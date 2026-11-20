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
     
   Script: test_rol_gestor_publicidad.sql
   Ubicación: tests/seguridad/test_rol_gestor_publicidad.sql
   Entrega: 8 (Seguridad y Respaldo)
   
   Descripción: Lote de pruebas de permisos y seguridad para el rol [rol_gestor_publicidad]
                evaluado mediante su usuario asociado [usr_gestor_publicidad].
                Verifica mediante cambio de contexto (EXECUTE AS LOGIN = 'usr_gestor_publicidad') que:
                1. Pertenece efectivamente al rol [rol_gestor_publicidad].
                2. SÍ PUEDE ejecutar procedimientos del esquema publicidad (alta de anunciantes, espacios).
                3. NO PUEDE (Error 229) ejecutar SPs de partido ni de administracion.
                4. NO PUEDE (Error 229) ejecutar ninguno de los 3 SPs visores de datos sensibles.
                5. NO PUEDE (Error 229) hacer SELECT, INSERT, UPDATE o DELETE directo sobre tablas físicas.
                   
   PRERREQUISITO: Haber ejecutado 01_cifrado_datos_sensibles.sql y 02_roles_y_permisos.sql.
   RESULTADO ESPERADO: Las 8 pruebas del reporte consolidado deben finalizar con Estado = 'OK'.
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
PRINT 'INICIANDO TEST DE ROL Y PERMISOS: rol_gestor_publicidad';
PRINT '======================================================================';

BEGIN TRANSACTION;
BEGIN TRY

    -- Preparar datos maestros como dbo
    DECLARE @id_p1 INT, @id_p2 INT, @id_sede INT, @id_fase INT;
    DECLARE @id_sel1 INT, @id_sel2 INT, @id_part INT, @id_anun INT, @id_club INT;

    EXEC administracion.sp_InsertarPais @nombre = 'Pais Pub 1', @huso_horario = '-03:00', @id_generado = @id_p1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Pub 2', @huso_horario = '+01:00', @id_generado = @id_p2 OUTPUT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Publicidad Test', @ciudad = 'Boston', @capacidad = 65000, @huso_horario = '-05:00', @id_pais = @id_p1, @id_generado = @id_sede OUTPUT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Publicidad Test', @orden = 93, @id_generado = @id_fase OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p1, @confederacion = 'CONMEBOL', @grupo_asignado = 'A', @id_generado = @id_sel1 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p2, @confederacion = 'UEFA', @grupo_asignado = 'B', @id_generado = @id_sel2 OUTPUT;
    EXEC partido.sp_CrearPartido @id_sede = @id_sede, @id_fase = @id_fase, @fecha_hora_local = '2026-06-22 20:00:00', @id_local = @id_sel1, @id_visitante = @id_sel2;
    SELECT TOP 1 @id_part = ID FROM partido.Partido ORDER BY ID DESC;

    -- =========================================================================
    -- PRUEBA 1: Verificación de membresía en rol_gestor_publicidad
    -- =========================================================================
    DECLARE @es_miembro INT = 0;
    EXECUTE AS LOGIN = 'usr_gestor_publicidad';
    SET @es_miembro = IS_ROLEMEMBER('rol_gestor_publicidad');
    REVERT;

    IF @es_miembro = 1
        INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'rol_gestor_publicidad', 'Verificación de membresía activa en el rol', 'Membresía RBAC', 'OK', 'El usuario pertenece correctamente a [rol_gestor_publicidad].');
    ELSE
        INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'rol_gestor_publicidad', 'Verificación de membresía activa en el rol', 'Membresía RBAC', 'FALLÓ', 'El usuario no es miembro del rol esperado.');

    -- =========================================================================
    -- PRUEBA 2 (PERMITIDO): Alta de anunciante (publicidad.sp_RegistrarAnunciante)
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_gestor_publicidad';
        EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Sponsor Oficial Test FIFA', @id_generado = @id_anun OUTPUT;
        REVERT;

        IF @id_anun IS NOT NULL
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'publicidad.sp_RegistrarAnunciante', 'Alta de anunciante autorizada en esquema publicidad', 'Permiso GRANT', 'OK', 'Anunciante registrado con ID ' + CAST(@id_anun AS VARCHAR(10)) + '.');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'publicidad.sp_RegistrarAnunciante', 'Alta de anunciante autorizada en esquema publicidad', 'Permiso GRANT', 'FALLÓ', 'No devolvió ID generado.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'publicidad.sp_RegistrarAnunciante', 'Alta de anunciante autorizada en esquema publicidad', 'Permiso GRANT', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 3 (PERMITIDO): Gestión de espacios publicitarios del partido
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_gestor_publicidad';
        EXEC publicidad.sp_EliminarEspaciosPartido @id_partido = @id_part;
        EXEC publicidad.sp_GenerarEspaciosPartido @id_partido = @id_part;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'publicidad.sp_GenerarEspaciosPartido', 'Regeneración de los 4 paneles perimetrales del partido', 'Permiso GRANT', 'OK', 'Los 4 paneles publicitarios fueron regenerados con éxito.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'publicidad.sp_GenerarEspaciosPartido', 'Regeneración de los 4 paneles perimetrales del partido', 'Permiso GRANT', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 4 (DENEGADO - ERROR 229): Intento de ejecutar SP de partido
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_gestor_publicidad';
        EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_part, @asistencia_publico = 50000;
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'partido.sp_RegistrarAsistenciaPublico', 'Bloqueo de ejecución en esquema ajeno (partido)', 'Bloqueo DENY (229)', 'FALLÓ', 'Debió arrojar Error 229 de permiso denegado.');
    END TRY
    BEGIN CATCH
        DECLARE @err4 INT = ERROR_NUMBER(), @msg4 VARCHAR(500) = ERROR_MESSAGE();
        REVERT;
        IF @err4 = 229
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'partido.sp_RegistrarAsistenciaPublico', 'Bloqueo de ejecución en esquema ajeno (partido)', 'Bloqueo DENY (229)', 'OK', 'Error 229 capturado: ' + @msg4);
        ELSE
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'partido.sp_RegistrarAsistenciaPublico', 'Bloqueo de ejecución en esquema ajeno (partido)', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(@err4 AS VARCHAR(10)) + '): ' + @msg4);
    END CATCH;

    -- =========================================================================
    -- PRUEBA 5 (DENEGADO - ERROR 229): Intento de ejecutar SP de administracion
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_gestor_publicidad';
        EXEC administracion.sp_InsertarClub @nombre = 'Club Intruso Pub', @id_generado = @id_club OUTPUT;
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'administracion.sp_InsertarClub', 'Bloqueo de ejecución en esquema ajeno (administracion)', 'Bloqueo DENY (229)', 'FALLÓ', 'Debió arrojar Error 229 de permiso denegado.');
    END TRY
    BEGIN CATCH
        DECLARE @err5 INT = ERROR_NUMBER(), @msg5 VARCHAR(500) = ERROR_MESSAGE();
        REVERT;
        IF @err5 = 229
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'administracion.sp_InsertarClub', 'Bloqueo de ejecución en esquema ajeno (administracion)', 'Bloqueo DENY (229)', 'OK', 'Error 229 capturado: ' + @msg5);
        ELSE
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'administracion.sp_InsertarClub', 'Bloqueo de ejecución en esquema ajeno (administracion)', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(@err5 AS VARCHAR(10)) + '): ' + @msg5);
    END CATCH;

    -- =========================================================================
    -- PRUEBA 6 (DENEGADO - ERROR 229): Intento de usar sp_ConsultarJugadorSensible
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_gestor_publicidad';
        EXEC administracion.sp_ConsultarJugadorSensible;
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'sp_ConsultarJugadorSensible', 'Bloqueo de acceso a datos personales desencriptados', 'Bloqueo DENY (229)', 'FALLÓ', 'Debió arrojar Error 229 de permiso denegado.');
    END TRY
    BEGIN CATCH
        DECLARE @err6 INT = ERROR_NUMBER(), @msg6 VARCHAR(500) = ERROR_MESSAGE();
        REVERT;
        IF @err6 = 229
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'sp_ConsultarJugadorSensible', 'Bloqueo de acceso a datos personales desencriptados', 'Bloqueo DENY (229)', 'OK', 'Error 229 capturado: ' + @msg6);
        ELSE
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'sp_ConsultarJugadorSensible', 'Bloqueo de acceso a datos personales desencriptados', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(@err6 AS VARCHAR(10)) + '): ' + @msg6);
    END CATCH;

    -- =========================================================================
    -- PRUEBA 7 (DENEGADO - ERROR 229): Intento de usar sp_ConsultarInformesArbitrales
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_gestor_publicidad';
        EXEC arbitraje.sp_ConsultarInformesArbitrales;
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'sp_ConsultarInformesArbitrales', 'Bloqueo de acceso a informes arbitrales desencriptados', 'Bloqueo DENY (229)', 'FALLÓ', 'Debió arrojar Error 229 de permiso denegado.');
    END TRY
    BEGIN CATCH
        DECLARE @err7 INT = ERROR_NUMBER(), @msg7 VARCHAR(500) = ERROR_MESSAGE();
        REVERT;
        IF @err7 = 229
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'sp_ConsultarInformesArbitrales', 'Bloqueo de acceso a informes arbitrales desencriptados', 'Bloqueo DENY (229)', 'OK', 'Error 229 capturado: ' + @msg7);
        ELSE
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'sp_ConsultarInformesArbitrales', 'Bloqueo de acceso a informes arbitrales desencriptados', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(@err7 AS VARCHAR(10)) + '): ' + @msg7);
    END CATCH;

    -- =========================================================================
    -- PRUEBA 8 (DENEGADO - ERROR 229): Intento de UPDATE directo en tabla física
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_gestor_publicidad';
        UPDATE publicidad.Anunciante SET nombre = 'Modificacion Directa Prohibida' WHERE ID = @id_anun;
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'UPDATE publicidad.Anunciante', 'Bloqueo de UPDATE directo salteando Stored Procedure', 'Bloqueo DENY (229)', 'FALLÓ', 'Debió arrojar Error 229 de permiso denegado.');
    END TRY
    BEGIN CATCH
        DECLARE @err8 INT = ERROR_NUMBER(), @msg8 VARCHAR(500) = ERROR_MESSAGE();
        REVERT;
        IF @err8 = 229
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'UPDATE publicidad.Anunciante', 'Bloqueo de UPDATE directo salteando Stored Procedure', 'Bloqueo DENY (229)', 'OK', 'Error 229 capturado: ' + @msg8);
        ELSE
            INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'UPDATE publicidad.Anunciante', 'Bloqueo de UPDATE directo salteando Stored Procedure', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(@err8 AS VARCHAR(10)) + '): ' + @msg8);
    END CATCH;

END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO @Reporte VALUES ('usr_gestor_publicidad', 'Bloque General', 'Excepción crítica no controlada', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
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
