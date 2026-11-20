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
     
   Script: test_rol_administrador.sql
   Ubicación: tests/seguridad/test_rol_administrador.sql
   Entrega: 8 (Seguridad y Respaldo)
   
   Descripción: Lote de pruebas de permisos y seguridad para el rol [rol_administrador]
                1. Pertenece efectivamente al rol [rol_administrador].
                2. Puede ejecutar Stored Procedures de ABM en administracion, partido, arbitraje y publicidad.
                3. Posee acceso exclusivo de ejecución y desencriptado sobre los 3 SPs visores
                   de datos sensibles:
                   - administracion.sp_ConsultarJugadorSensible
                   - administracion.sp_ConsultarBajasMedicasSensibles
                   - arbitraje.sp_ConsultarInformesArbitrales
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

DECLARE @Reporte TABLE (
    ID INT IDENTITY(1,1),
    Usuario_Evaluado VARCHAR(35),
    Objeto_Evaluado VARCHAR(55),
    Escenario VARCHAR(75),
    Tipo_Prueba VARCHAR(25),
    Resultado VARCHAR(10),
    Detalle VARCHAR(500)
);

PRINT '======================================================================';
PRINT 'INICIANDO TEST DE ROL Y PERMISOS: rol_administrador (usr_administrador)';
PRINT '======================================================================';

BEGIN TRANSACTION;
BEGIN TRY

    -- Preparar datos maestros base
    DECLARE @id_p1 INT, @id_p2 INT, @id_p3 INT, @id_sede INT, @id_fase INT, @id_club INT;
    DECLARE @id_sel1 INT, @id_sel2 INT, @id_part INT, @id_jug INT, @id_conv INT, @id_arb INT, @id_anun INT;

    EXEC administracion.sp_InsertarPais @nombre = 'Pais Admin 1', @huso_horario = '-03:00', @id_generado = @id_p1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Admin 2', @huso_horario = '+01:00', @id_generado = @id_p2 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Admin Arb', @huso_horario = '+02:00', @id_generado = @id_p3 OUTPUT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Admin Test', @ciudad = 'Dallas', @capacidad = 70000, @huso_horario = '-05:00', @id_pais = @id_p1, @id_generado = @id_sede OUTPUT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Admin Test', @orden = 91, @id_generado = @id_fase OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p1, @confederacion = 'CONMEBOL', @grupo_asignado = 'A', @id_generado = @id_sel1 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p2, @confederacion = 'UEFA', @grupo_asignado = 'B', @id_generado = @id_sel2 OUTPUT;
    EXEC partido.sp_CrearPartido @id_sede = @id_sede, @id_fase = @id_fase, @fecha_hora_local = '2026-06-20 16:00:00', @id_local = @id_sel1, @id_visitante = @id_sel2;
    SELECT TOP 1 @id_part = ID FROM partido.Partido ORDER BY ID DESC;
    EXEC arbitraje.sp_InsertarArbitro @Nombre = 'Daniele', @Apellido = 'Orsato Admin', @Categoria = 'FIFA Elite', @ID_Pais = @id_p3, @ID = @id_arb OUTPUT;

    -- =========================================================================
    -- PRUEBA 1: Verificación de membresía en rol_administrador
    -- =========================================================================
    DECLARE @es_miembro INT = 0;
    EXECUTE AS LOGIN = 'usr_administrador';
    SET @es_miembro = IS_ROLEMEMBER('rol_administrador');
    REVERT;

    IF @es_miembro = 1
        INSERT INTO @Reporte VALUES ('usr_administrador', 'rol_administrador', 'Verificación de membresía activa en el rol', 'Membresía RBAC', 'OK', 'El usuario pertenece correctamente a [rol_administrador].');
    ELSE
        INSERT INTO @Reporte VALUES ('usr_administrador', 'rol_administrador', 'Verificación de membresía activa en el rol', 'Membresía RBAC', 'FALLÓ', 'El usuario no es miembro del rol esperado.');

    -- =========================================================================
    -- PRUEBA 2: Ejecución de SPs de ABM en administracion, partido y publicidad
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_administrador';
        EXEC administracion.sp_InsertarClub @nombre = 'Club Admin FC', @id_generado = @id_club OUTPUT;
        EXEC administracion.sp_InsertarJugador @nombre = 'Julian', @apellido = 'Alvarez Admin', @fecha_nacimiento = '2000-01-31', @id_club = @id_club, @posicion_habitual = 'Delantero', @id_generado = @id_jug OUTPUT;
        EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_jug, @id_seleccion = @id_sel1, @dorsal = 9, @id_generado = @id_conv OUTPUT;
        EXEC administracion.sp_RegistrarBajaConvocatoria @id_jugador = @id_jug, @motivo = 'Esguince de tobillo grado I en entrenamiento', @fecha = '2026-06-10';
        EXEC arbitraje.sp_DesignarArbitro @ID_Partido = @id_part, @ID_Arbitro = @id_arb, @Rol = 'Árbitro Principal', @Informe = 'Informe confidencial verificado por administrador.';
        EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_part, @asistencia_publico = 62000;
        EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Sponsor Admin Global', @id_generado = @id_anun OUTPUT;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_administrador', 'ABM Multi-Esquema', 'Alta en administracion, partido, arbitraje y publicidad', 'Permiso GRANT', 'OK', 'Ejecución exitosa en los 4 esquemas de la base de datos.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_administrador', 'ABM Multi-Esquema', 'Alta en administracion, partido, arbitraje y publicidad', 'Permiso GRANT', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 3: Desencriptación con administracion.sp_ConsultarJugadorSensible
    -- =========================================================================
    DROP TABLE IF EXISTS #AdminJug;
    CREATE TABLE #AdminJug (ID_Jugador INT, Jugador VARCHAR(200), Club VARCHAR(100), Posicion VARCHAR(30), Fecha_Nacimiento_Desencriptada DATE, Valor_En_Disco_Cifrado VARBINARY(256));

    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_administrador';
        INSERT INTO #AdminJug EXEC administracion.sp_ConsultarJugadorSensible @ID_Jugador = @id_jug;
        REVERT;

        IF EXISTS (SELECT 1 FROM #AdminJug WHERE ID_Jugador = @id_jug AND Fecha_Nacimiento_Desencriptada = '2000-01-31')
            INSERT INTO @Reporte VALUES ('usr_administrador', 'sp_ConsultarJugadorSensible', 'Acceso autorizado y desencriptación de fecha_nacimiento', 'Dato Sensible', 'OK', 'Fecha desencriptada correctamente: 2000-01-31.');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_administrador', 'sp_ConsultarJugadorSensible', 'Acceso autorizado y desencriptación de fecha_nacimiento', 'Dato Sensible', 'FALLÓ', 'No devolvió la fecha desencriptada.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_administrador', 'sp_ConsultarJugadorSensible', 'Acceso autorizado y desencriptación de fecha_nacimiento', 'Dato Sensible', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 4: Desencriptación con administracion.sp_ConsultarBajasMedicasSensibles
    -- =========================================================================
    DROP TABLE IF EXISTS #AdminBajas;
    CREATE TABLE #AdminBajas (Seleccion VARCHAR(100), Jugador VARCHAR(200), Dorsal TINYINT, Fecha_Baja DATE, Motivo_Medico_Desencriptado VARCHAR(255), Motivo_En_Disco_Cifrado VARBINARY(512));

    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_administrador';
        INSERT INTO #AdminBajas EXEC administracion.sp_ConsultarBajasMedicasSensibles;
        REVERT;

        IF EXISTS (SELECT 1 FROM #AdminBajas WHERE Dorsal = 9 AND Motivo_Medico_Desencriptado = 'Esguince de tobillo grado I en entrenamiento')
            INSERT INTO @Reporte VALUES ('usr_administrador', 'sp_ConsultarBajasMedicasSensibles', 'Acceso autorizado y desencriptación de diagnóstico médico', 'Dato Sensible', 'OK', 'Motivo médico desencriptado con éxito.');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_administrador', 'sp_ConsultarBajasMedicasSensibles', 'Acceso autorizado y desencriptación de diagnóstico médico', 'Dato Sensible', 'FALLÓ', 'No devolvió el motivo médico desencriptado.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_administrador', 'sp_ConsultarBajasMedicasSensibles', 'Acceso autorizado y desencriptación de diagnóstico médico', 'Dato Sensible', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 5: Desencriptación con arbitraje.sp_ConsultarInformesArbitrales
    -- =========================================================================
    DROP TABLE IF EXISTS #AdminInf;
    CREATE TABLE #AdminInf (Nro_Partido INT, Arbitro VARCHAR(200), Rol_Designado VARCHAR(30), Informe_Desencriptado VARCHAR(1000), Informe_En_Disco_Cifrado VARBINARY(1200));

    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_administrador';
        INSERT INTO #AdminInf EXEC arbitraje.sp_ConsultarInformesArbitrales @ID_Partido = @id_part;
        REVERT;

        IF EXISTS (SELECT 1 FROM #AdminInf WHERE Nro_Partido = @id_part AND Informe_Desencriptado = 'Informe confidencial verificado por administrador.')
            INSERT INTO @Reporte VALUES ('usr_administrador', 'sp_ConsultarInformesArbitrales', 'Acceso autorizado y desencriptación de informe arbitral', 'Dato Sensible', 'OK', 'Informe arbitral desencriptado con éxito.');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_administrador', 'sp_ConsultarInformesArbitrales', 'Acceso autorizado y desencriptación de informe arbitral', 'Dato Sensible', 'FALLÓ', 'No devolvió el informe arbitral desencriptado.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_administrador', 'sp_ConsultarInformesArbitrales', 'Acceso autorizado y desencriptación de informe arbitral', 'Dato Sensible', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 6: Permiso de lectura y gestión directa sobre tablas (DBA)
    -- =========================================================================
    BEGIN TRY
        DECLARE @cnt INT = 0;
        EXECUTE AS LOGIN = 'usr_administrador';
        SELECT @cnt = COUNT(*) FROM administracion.Jugador WHERE ID = @id_jug;
        REVERT;

        IF @cnt = 1
            INSERT INTO @Reporte VALUES ('usr_administrador', 'Acceso Tablas Físicas', 'Consulta directa sobre tablas del sistema', 'Permiso GRANT', 'OK', 'Acceso directo verificado para tareas de administración.');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_administrador', 'Acceso Tablas Físicas', 'Consulta directa sobre tablas del sistema', 'Permiso GRANT', 'FALLÓ', 'No pudo leer la tabla física.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_administrador', 'Acceso Tablas Físicas', 'Consulta directa sobre tablas del sistema', 'Permiso GRANT', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO @Reporte VALUES ('usr_administrador', 'Bloque General', 'Excepción crítica no controlada', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

SELECT 
    ID AS [#],
    Usuario_Evaluado AS [Usuario],
    Objeto_Evaluado AS [Objeto / Procedimiento],
    Escenario AS [Escenario Evaluado],
    Tipo_Prueba AS [Categoría],
    Resultado AS [Estado],
    Detalle AS [Detalle / Evidencia]
FROM @Reporte
ORDER BY ID;
GO
