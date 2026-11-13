/* 
   UNIVERSIDAD NACIONAL DE LA MATANZA (UNLaM)
   Departamento de Ingeniería e Investigaciones Tecnológicas
   Asignatura: Bases de Datos Aplicada (3641)
   Comisión: 02-5600 (Viernes Tarde)
   
   TRABAJO PRÁCTICO - SISTEMA DE REGISTRO Y GESTIÓN DEL MUNDIAL DE FÚTBOL 2026
   
   Integrantes del Grupo:
     - Aleman Flores, Matias Osvaldo 
     - Gamarra Bravo, Sidney Maribel
     - Pereira, Carlos Manuel
     - Villa, Brenda
     
   Script: test_11_importacion_jugadores_clubes.sql
   Descripción: Batería de pruebas para la importación masiva de jugadores y clubes.
                - Valida excepciones de archivo (ruta vacía, extensión incorrecta, inexistente).
                - Carga masiva exitosa de jugadores y clubes desde SquadLists.csv.
                - Pruebas de Idempotencia y Upsert (re-ejecución y actualización).
                - Manejo de errores parciales con SquadLists_errores.csv y auditoría en dbo.LogImportacion.
*/

USE Mundial2026;
GO
 
/* ==========================================================================
   TEST 0 - CONFIGURACION (RUTAS DINAMICAS VIA FUNCION ADMINISTRACION.fn_RutaDatasets)
   ========================================================================== */
DECLARE @dir_datasets VARCHAR(500) = '..\..\datasets';
IF OBJECT_ID('administracion.fn_RutaDatasets', 'FN') IS NOT NULL
    SET @dir_datasets = administracion.fn_RutaDatasets();

IF OBJECT_ID('tempdb..#cfg') IS NOT NULL DROP TABLE #cfg;
CREATE TABLE #cfg (clave VARCHAR(30) PRIMARY KEY, valor VARCHAR(500) NOT NULL);
INSERT INTO #cfg (clave, valor) VALUES
    ('csv_ok',       @dir_datasets + '\SquadLists.csv'),
    ('csv_errores',  @dir_datasets + '\SquadLists_errores.csv');
GO
 
/* ==========================================================================
   VALIDACIONES DE ARCHIVO (casos que deben FALLAR)
   ========================================================================== */
 
-- TEST 1: Ruta nula.
-- ESPERADO: error 50001 "La ruta del archivo CSV no puede ser nula ni vacía."
--           y una fila ERROR en dbo.LogImportacion con archivo = 'SIN_RUTA'.
BEGIN TRY
    EXEC administracion.sp_ImportarJugadoresClubes @ruta_archivo = NULL;
    PRINT 'TEST 1 FALLÓ: debía lanzar excepción.';
END TRY
BEGIN CATCH
    PRINT 'TEST 1 OK -> ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
END CATCH;
GO
 
-- TEST 2: Extensión incorrecta y archivo inexistente (errores ACUMULADOS en un único mensaje).
-- ESPERADO: error 50002 cuyo mensaje incluye también (50010).
BEGIN TRY
    EXEC administracion.sp_ImportarJugadoresClubes @ruta_archivo = 'C:\no_existe\jugadores.txt';
    PRINT 'TEST 2 FALLÓ: debía lanzar excepción.';
END TRY
BEGIN CATCH
    PRINT 'TEST 2 OK -> ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
END CATCH;
GO
 
-- TEST 3: Extensión correcta pero archivo inexistente.
-- ESPERADO: error 50010 "El archivo especificado no existe o no es accesible".
BEGIN TRY
    EXEC administracion.sp_ImportarJugadoresClubes @ruta_archivo = 'C:\no_existe\SquadLists.csv';
    PRINT 'TEST 3 FALLÓ: debía lanzar excepción.';
END TRY
BEGIN CATCH
    PRINT 'TEST 3 OK -> ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
END CATCH;
GO
 
/* ==========================================================================
   IMPORTACIÓN EXITOSA
   ========================================================================== */
 
-- TEST 4: Primera importación del dataset completo.
-- ESPERADO (resultado del SP): total_procesados = 1248, insertados = 1248,
--          actualizados = 0, fallidos = 0, clubes_creados = 450.
DECLARE @ruta VARCHAR(500) = (SELECT valor FROM #cfg WHERE clave = 'csv_ok');
EXEC administracion.sp_ImportarJugadoresClubes @ruta_archivo = @ruta;
GO
 
-- TEST 4b: Evidencia de los datos manipulados.
-- ESPERADO: Club = 450 filas, Jugador = 1248 filas.
SELECT (SELECT COUNT(*) FROM administracion.Club)    AS total_clubes,
       (SELECT COUNT(*) FROM administracion.Jugador) AS total_jugadores;
 
-- ESPERADO: MAHREZ Riyad Karim | 1991-02-21 | Delantero | Al Ahli FC (KSA)
--           (club creado por el importador y vinculado vía ID_Club).
SELECT j.ID, j.nombre, j.apellido, j.fecha_nacimiento, j.posicion_habitual, c.nombre AS club
FROM administracion.Jugador j
JOIN administracion.Club c ON c.ID = j.ID_Club
WHERE j.apellido = 'MAHREZ';
 
-- ESPERADO: posiciones traducidas -> Defensor 420, Mediocampista 370, Delantero 313, Arquero 145.
SELECT posicion_habitual, COUNT(*) AS cantidad
FROM administracion.Jugador
GROUP BY posicion_habitual
ORDER BY cantidad DESC;
 
-- ESPERADO: ningún jugador sin club (0 filas).
SELECT j.ID FROM administracion.Jugador j
LEFT JOIN administracion.Club c ON c.ID = j.ID_Club
WHERE c.ID IS NULL;
GO
 
/* ==========================================================================
   IDEMPOTENCIA Y UPSERT
   ========================================================================== */
 
-- TEST 5: Re-ejecución con el mismo archivo (no debe duplicar).
-- ESPERADO: total_procesados = 1248, insertados = 0, actualizados = 1248,
--           fallidos = 0, clubes_creados = 0. Club sigue en 450 y Jugador en 1248.
DECLARE @ruta VARCHAR(500) = (SELECT valor FROM #cfg WHERE clave = 'csv_ok');
EXEC administracion.sp_ImportarJugadoresClubes @ruta_archivo = @ruta;
 
SELECT (SELECT COUNT(*) FROM administracion.Club)    AS total_clubes,
       (SELECT COUNT(*) FROM administracion.Jugador) AS total_jugadores;
GO
 
-- TEST 6: Actualización de un jugador existente (transferencia de club).
-- Se mueve a MAHREZ a otro club usando los SP de la Entrega 5 y se vuelve a importar.
-- ESPERADO: antes de importar el club es 'Club Temporal Test'; después de importar
--           vuelve a 'Al Ahli FC (KSA)'. insertados = 0, actualizados = 1248.
--           (Queda 'Club Temporal Test' sin jugadores: Club pasa a 451.)
DECLARE @id_club_tmp INT, @id_mahrez INT, @fecha DATE, @nom VARCHAR(100), @ape VARCHAR(100), @pos VARCHAR(30);
 
EXEC administracion.sp_InsertarClub @nombre = 'Club Temporal Test', @id_generado = @id_club_tmp OUTPUT;
 
SELECT @id_mahrez = ID, @fecha = fecha_nacimiento, @nom = nombre, @ape = apellido, @pos = posicion_habitual
FROM administracion.Jugador WHERE apellido = 'MAHREZ';
 
EXEC administracion.sp_ModificarJugador @id = @id_mahrez, @nombre = @nom, @apellido = @ape,
     @fecha_nacimiento = @fecha, @id_club = @id_club_tmp, @posicion_habitual = @pos;
 
SELECT 'ANTES' AS momento, c.nombre AS club
FROM administracion.Jugador j JOIN administracion.Club c ON c.ID = j.ID_Club WHERE j.ID = @id_mahrez;
 
DECLARE @ruta VARCHAR(500) = (SELECT valor FROM #cfg WHERE clave = 'csv_ok');
EXEC administracion.sp_ImportarJugadoresClubes @ruta_archivo = @ruta;
 
SELECT 'DESPUES' AS momento, c.nombre AS club
FROM administracion.Jugador j JOIN administracion.Club c ON c.ID = j.ID_Club WHERE j.ID = @id_mahrez;
GO
 
/* ==========================================================================
   IMPORTACIÓN PARCIAL CON ERRORES (SquadLists_errores.csv, 9 filas)
   Fila 1,2,8: válidas | 3: fecha 31/02/1999 | 4: posición 'XX' | 5: club vacío
   Fila 6: jugador de 11 años (lo rechaza sp_InsertarJugador, con club nuevo)
   Fila 7: nombre vacío | 9: club de más de 100 caracteres
   ========================================================================== */
 
-- TEST 7: Importación con errores parciales.
-- ESPERADO: total_procesados = 9, insertados = 3, actualizados = 0, fallidos = 6,
--           clubes_creados = 1 ('Club Test Uno (TST)'),
--           resultado = 'Importación finalizada con errores parciales...'.
DECLARE @ruta VARCHAR(500) = (SELECT valor FROM #cfg WHERE clave = 'csv_errores');
EXEC administracion.sp_ImportarJugadoresClubes @ruta_archivo = @ruta;
GO
 
-- TEST 7b: Log de errores de la última ejecución del archivo con errores.
-- ESPERADO: 6 filas ERROR (filas 3,4,5,6,7,9 con el detalle de cada causa; la fila 6 con
--           error 50063 de sp_InsertarJugador) + 1 fila ADVERTENCIA con el resumen
--           'Total: 9 | Insertados: 3 | Actualizados: 0 | Fallidos: 6 | Clubes creados: 1'.
SELECT id_log, fila_origen, tipo_evento, mensaje
FROM dbo.LogImportacion
WHERE archivo = (SELECT valor FROM #cfg WHERE clave = 'csv_errores')
  AND fecha_proceso = (SELECT MAX(fecha_proceso) FROM dbo.LogImportacion
                       WHERE archivo = (SELECT valor FROM #cfg WHERE clave = 'csv_errores'))
ORDER BY id_log;
GO
 
-- TEST 7c: Atomicidad por fila.
-- ESPERADO: 1 fila para 'Club Test Uno (TST)' con sus 3 jugadores (PEREZ, GOMEZ, TORRES) y
--           0 filas para 'Club Test Tres (TST)' (se creó dentro de la fila 6 y se revirtió
--           porque falló el alta del jugador) y para 'Club Test Dos (TST)' (la fila 4 se
--           rechazó antes de tocar las tablas).
SELECT c.nombre AS club, COUNT(j.ID) AS jugadores
FROM administracion.Club c
LEFT JOIN administracion.Jugador j ON j.ID_Club = c.ID
WHERE c.nombre LIKE 'Club Test % (TST)'
GROUP BY c.nombre;
GO
 
-- TEST 8: Re-ejecución del archivo con errores (idempotencia con errores parciales).
-- ESPERADO: total_procesados = 9, insertados = 0, actualizados = 3, fallidos = 6, clubes_creados = 0.
--           Totales finales: Club = 452, Jugador = 1251.
DECLARE @ruta VARCHAR(500) = (SELECT valor FROM #cfg WHERE clave = 'csv_errores');
EXEC administracion.sp_ImportarJugadoresClubes @ruta_archivo = @ruta;
 
SELECT (SELECT COUNT(*) FROM administracion.Club)    AS total_clubes,
       (SELECT COUNT(*) FROM administracion.Jugador) AS total_jugadores;
GO
 
-- TEST 9: Auditoría general de ejecuciones.
-- ESPERADO: una fila resumen (INFO/ADVERTENCIA) por cada importación exitosa o parcial
--           y una fila ERROR por cada fallo de archivo (tests 1 a 3).
SELECT id_log, archivo, fecha_proceso, tipo_evento, LEFT(mensaje, 150) AS mensaje
FROM dbo.LogImportacion
ORDER BY id_log DESC;
GO
