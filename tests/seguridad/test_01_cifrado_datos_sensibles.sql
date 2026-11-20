/* 
   UNIVERSIDAD NACIONAL DE LA MATANZA (UNLaM)
   Departamento de Ingeniería e Investigaciones Tecnológicas
   Asignatura: Bases de Datos Aplicadas (3641)
   Comisión: 02-5600 (Viernes Tarde)
   
   TRABAJO PRÁCTICO - SISTEMA DE REGISTRO Y GESTIÓN DEL MUNDIAL DE FÚTBOL 2026
   
   Integrantes del Grupo:
     - Aleman Flores, Matias Osvaldo 
     - Gamarra Bravo, Sidney Maribel
     - Pereira, Carlos Manuel
     - Villa, Brenda
     
   Fecha: 19/11/2026
   Script: test_01_cifrado_datos_sensibles.sql
   
   Descripción: 
                Prueba el alta mediante los Stored Procedures
                Evidencia por tabla: Nombre_Tabla | Columna_Plana_Disco (NULL) |
                   Registro_Desencriptado | Registro_Cifrado_Binario (VARBINARY).
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

DECLARE @Evidencia TABLE (
    Nombre_Tabla VARCHAR(35),
    Columna_Plana_Disco VARCHAR(30),
    Registro_Desencriptado VARCHAR(255),
    Registro_Cifrado_Binario VARBINARY(1200)
);

DECLARE @Resumen TABLE (
    ID INT IDENTITY(1,1),
    Prueba VARCHAR(55),
    Estado VARCHAR(10),
    Detalle VARCHAR(300)
);

PRINT '==========================';
PRINT 'INICIANDO TEST DE CIFRADO';
PRINT '==========================';

BEGIN TRANSACTION;
BEGIN TRY

    -- Asegurar clave cerrada al iniciar
    IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'Key_Mundial2026_AES256')
        CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;

    -- PRUEBA 1: Se verifica creacion de todas las claves y certificados
    IF EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
       AND EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'Cert_Mundial2026_Seguridad')
       AND EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'Key_Mundial2026_AES256' AND algorithm_desc = 'AES_256')
       AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('administracion.Jugador') AND name = 'fecha_nacimiento_cifrada')
       AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('administracion.Convocatoria') AND name = 'motivo_cifrado')
       AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('arbitraje.Designacion_Arbitral') AND name = 'informe_cifrado')
        INSERT INTO @Resumen VALUES ('1. Infraestructura DMK + Certificado + AES-256', 'OK', 'Llaves y las 3 columnas VARBINARY verificadas.');
    ELSE
        INSERT INTO @Resumen VALUES ('1. Infraestructura DMK + Certificado + AES-256', 'FALLÓ', 'Falta ejecutar 01_cifrado_datos_sensibles.sql.');

    -- PRUEBA 2: Cero textos planos en registros previos de las 3 tablas
    IF NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE fecha_nacimiento IS NOT NULL)
       AND NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE fecha_nacimiento_cifrada IS NULL)
       AND NOT EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE motivo IS NOT NULL)
       AND NOT EXISTS (SELECT 1 FROM arbitraje.Designacion_Arbitral WHERE informe IS NOT NULL)
        INSERT INTO @Resumen VALUES ('2. Ausencia de textos planos en disco', 'OK', 'Ningún registro previo conserva datos sensibles en texto plano.');
    ELSE
        INSERT INTO @Resumen VALUES ('2. Ausencia de textos planos en disco', 'FALLÓ', 'Existen registros sin migrar en texto plano.');

    -- Datos de prueba
    DECLARE @fecha_test DATE = '1998-04-27';
    DECLARE @motivo_test VARCHAR(255) = 'Desgarro grado II en isquiotibial derecho';
    DECLARE @informe_test VARCHAR(1000) = 'Informe reservado: incidente en túnel tras el pitazo final.';

    DECLARE @id_p1 INT, @id_p2 INT, @id_p3 INT, @id_sede INT, @id_fase INT, @id_club INT;
    DECLARE @id_sel1 INT, @id_sel2 INT, @id_part INT, @id_jug INT, @id_conv INT, @id_arb INT;

    EXEC administracion.sp_InsertarPais @nombre = 'Pais Test Cifrado 1', @huso_horario = '-03:00', @id_generado = @id_p1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Test Cifrado 2', @huso_horario = '+01:00', @id_generado = @id_p2 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Test Arbitro', @huso_horario = '+02:00', @id_generado = @id_p3 OUTPUT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Test Cifrado', @ciudad = 'Miami', @capacidad = 65000, @huso_horario = '-05:00', @id_pais = @id_p1, @id_generado = @id_sede OUTPUT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Test Cifrado', @orden = 96, @id_generado = @id_fase OUTPUT;
    EXEC administracion.sp_InsertarClub @nombre = 'Club Test Cifrado', @id_generado = @id_club OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p1, @confederacion = 'CONMEBOL', @grupo_asignado = 'A', @id_generado = @id_sel1 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p2, @confederacion = 'UEFA', @grupo_asignado = 'B', @id_generado = @id_sel2 OUTPUT;
    EXEC partido.sp_CrearPartido @id_sede = @id_sede, @id_fase = @id_fase, @fecha_hora_local = '2026-06-15 18:00:00', @id_local = @id_sel1, @id_visitante = @id_sel2;
    SELECT TOP 1 @id_part = ID FROM partido.Partido ORDER BY ID DESC;

    -- Alta mediante los Stored Procedures 
    EXEC administracion.sp_InsertarJugador
        @nombre = 'Cristian', @apellido = 'Romero', @fecha_nacimiento = @fecha_test,
        @id_club = @id_club, @posicion_habitual = 'Defensor', @id_generado = @id_jug OUTPUT;

    EXEC administracion.sp_RegistrarConvocatoria
        @id_jugador = @id_jug, @id_seleccion = @id_sel1, @dorsal = 13, @id_generado = @id_conv OUTPUT;

    EXEC administracion.sp_RegistrarBajaConvocatoria
        @id_jugador = @id_jug, @motivo = @motivo_test, @fecha = '2026-06-05';

    EXEC arbitraje.sp_InsertarArbitro
        @Nombre = 'Szymon', @Apellido = 'Marciniak', @Categoria = 'FIFA Elite', @ID_Pais = @id_p3, @ID = @id_arb OUTPUT;

    EXEC arbitraje.sp_DesignarArbitro
        @ID_Partido = @id_part, @ID_Arbitro = @id_arb, @Rol = 'Árbitro Principal', @Informe = @informe_test;

    -- PRUEBA 3: Verifica que ningun sp dejo la llave abierta
    DECLARE @sin_llave VARCHAR(50);
    SELECT @sin_llave = CONVERT(VARCHAR(50), DecryptByKey(fecha_nacimiento_cifrada))
    FROM administracion.Jugador WHERE ID = @id_jug;

    IF @sin_llave IS NULL
        INSERT INTO @Resumen VALUES ('3. Bloqueo con clave cerrada (DecryptByKey)', 'OK', 'Sin abrir la llave AES-256, DecryptByKey devolvió NULL.');
    ELSE
        INSERT INTO @Resumen VALUES ('3. Bloqueo con clave cerrada (DecryptByKey)', 'FALLÓ', 'Se pudo leer sin abrir la clave.');

    -- Abrir clave para leer y construir la tabla comparativa
    OPEN SYMMETRIC KEY Key_Mundial2026_AES256
    DECRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;

    INSERT INTO @Evidencia
    SELECT
        'administracion.Jugador',
        CAST(fecha_nacimiento AS VARCHAR(30)),
        CONVERT(VARCHAR(10), DecryptByKey(fecha_nacimiento_cifrada)),
        fecha_nacimiento_cifrada
    FROM administracion.Jugador WHERE ID = @id_jug;

    INSERT INTO @Evidencia
    SELECT
        'administracion.Convocatoria',
        motivo,
        CONVERT(VARCHAR(255), DecryptByKey(motivo_cifrado)),
        motivo_cifrado
    FROM administracion.Convocatoria WHERE ID = @id_conv;

    INSERT INTO @Evidencia
    SELECT
        'arbitraje.Designacion_Arbitral',
        informe,
        CONVERT(VARCHAR(1000), DecryptByKey(informe_cifrado)),
        informe_cifrado
    FROM arbitraje.Designacion_Arbitral WHERE ID_Partido = @id_part AND ID_Arbitro = @id_arb;

    CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;

    -- PRUEBAS 4, 5 y 6: Validar columna plana en NULL, binario cargado y coincidencia exacta
    IF EXISTS (SELECT 1 FROM @Evidencia WHERE Nombre_Tabla = 'administracion.Jugador' AND Columna_Plana_Disco IS NULL AND Registro_Cifrado_Binario IS NOT NULL AND Registro_Desencriptado = CONVERT(VARCHAR(10), @fecha_test, 120))
        INSERT INTO @Resumen VALUES ('4. Cifrado y descifrado en Jugador', 'OK', 'fecha_nacimiento = NULL en disco y desencriptado exacto.');
    ELSE
        INSERT INTO @Resumen VALUES ('4. Cifrado y descifrado en Jugador', 'FALLÓ', 'No coincidió la fecha o quedó texto plano.');

    IF EXISTS (SELECT 1 FROM @Evidencia WHERE Nombre_Tabla = 'administracion.Convocatoria' AND Columna_Plana_Disco IS NULL AND Registro_Cifrado_Binario IS NOT NULL AND Registro_Desencriptado = @motivo_test)
        INSERT INTO @Resumen VALUES ('5. Cifrado y descifrado en Convocatoria', 'OK', 'motivo = NULL en disco y desencriptado exacto.');
    ELSE
        INSERT INTO @Resumen VALUES ('5. Cifrado y descifrado en Convocatoria', 'FALLÓ', 'No coincidió el motivo médico o quedó texto plano.');

    IF EXISTS (SELECT 1 FROM @Evidencia WHERE Nombre_Tabla = 'arbitraje.Designacion_Arbitral' AND Columna_Plana_Disco IS NULL AND Registro_Cifrado_Binario IS NOT NULL AND Registro_Desencriptado = @informe_test)
        INSERT INTO @Resumen VALUES ('6. Cifrado y descifrado en Designacion_Arbitral', 'OK', 'informe = NULL en disco y desencriptado exacto.');
    ELSE
        INSERT INTO @Resumen VALUES ('6. Cifrado y descifrado en Designacion_Arbitral', 'FALLÓ', 'No coincidió el informe o quedó texto plano.');

END TRY
BEGIN CATCH
    IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'Key_Mundial2026_AES256')
        CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
    INSERT INTO @Resumen VALUES ('Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

-- ============================================================================
-- RESULTADOS: TABLA DE EVIDENCIA + RESUMEN DE VALIDACIONES
-- ============================================================================
SELECT
    Nombre_Tabla AS [Nombre de Tabla],
    Columna_Plana_Disco AS [Columna Plana (En Disco)],
    Registro_Desencriptado AS [Registro (Desencriptado)],
    Registro_Cifrado_Binario AS [Registro Cifrado Binario]
FROM @Evidencia;

SELECT
    ID AS [#],
    Prueba AS [Validación],
    Estado AS [Estado],
    Detalle AS [Resultado]
FROM @Resumen
ORDER BY ID;
GO
