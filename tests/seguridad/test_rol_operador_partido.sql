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
     
   Script: test_rol_operador_partido.sql
   Ubicación: tests/seguridad/test_rol_operador_partido.sql
   Entrega: 8 (Seguridad y Respaldo)
   
   Descripción: Lote de pruebas de permisos y seguridad para el rol [rol_operador_partido]
                evaluado mediante su usuario asociado [usr_operador_partido].
                Verifica mediante cambio de contexto (EXECUTE AS LOGIN = 'usr_operador_partido') que:
                1. Pertenece efectivamente al rol [rol_operador_partido].
                2. SÍ PUEDE ejecutar procedimientos operativos de partido (ej. asistencia/eventos).
                3. SÍ PUEDE registrar designaciones arbitrales con informe cifrado (sp_DesignarArbitro).
                4. NO PUEDE (Error 229) hacer SELECT directo sobre tablas físicas.
                5. NO PUEDE (Error 229) ejecutar arbitraje.sp_ConsultarInformesArbitrales.
                6. NO PUEDE (Error 229) ejecutar administracion.sp_ConsultarJugadorSensible.
                7. NO PUEDE (Error 229) ejecutar administracion.sp_ConsultarBajasMedicasSensibles.
                8. NO PUEDE (Error 229) ejecutar SPs de publicidad ni hacer INSERT directo en tablas.
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
PRINT 'INICIANDO TEST DE ROL Y PERMISOS: rol_operador_partido';
PRINT '======================================================================';

BEGIN TRANSACTION;
BEGIN TRY

    -- Preparar datos maestros como dbo
    DECLARE @id_p1 INT, @id_p2 INT, @id_p3 INT, @id_sede INT, @id_fase INT;
    DECLARE @id_sel1 INT, @id_sel2 INT, @id_part INT, @id_arb INT, @id_anun INT;

    EXEC administracion.sp_InsertarPais @nombre = 'Pais Operador 1', @huso_horario = '-03:00', @id_generado = @id_p1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Operador 2', @huso_horario = '+01:00', @id_generado = @id_p2 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Operador Arb', @huso_horario = '+02:00', @id_generado = @id_p3 OUTPUT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Operador Test', @ciudad = 'Atlanta', @capacidad = 68000, @huso_horario = '-05:00', @id_pais = @id_p1, @id_generado = @id_sede OUTPUT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Operador Test', @orden = 92, @id_generado = @id_fase OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p1, @confederacion = 'CONMEBOL', @grupo_asignado = 'A', @id_generado = @id_sel1 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p2, @confederacion = 'UEFA', @grupo_asignado = 'B', @id_generado = @id_sel2 OUTPUT;
    EXEC partido.sp_CrearPartido @id_sede = @id_sede, @id_fase = @id_fase, @fecha_hora_local = '2026-06-21 18:00:00', @id_local = @id_sel1, @id_visitante = @id_sel2;
    SELECT TOP 1 @id_part = ID FROM partido.Partido ORDER BY ID DESC;
    EXEC arbitraje.sp_InsertarArbitro @Nombre = 'Wilton', @Apellido = 'Sampaio Op', @Categoria = 'FIFA Elite', @ID_Pais = @id_p3, @ID = @id_arb OUTPUT;

    -- =========================================================================
    -- PRUEBA 1: Verificación de membresía en rol_operador_partido
    -- =========================================================================
    DECLARE @es_miembro INT = 0;
    EXECUTE AS LOGIN = 'usr_operador_partido';
    SET @es_miembro = IS_ROLEMEMBER('rol_operador_partido');
    REVERT;

    IF @es_miembro = 1
        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'rol_operador_partido', 'Verificación de membresía activa en el rol', 'Membresía RBAC', 'OK', 'El usuario pertenece correctamente a [rol_operador_partido].');
    ELSE
        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'rol_operador_partido', 'Verificación de membresía activa en el rol', 'Membresía RBAC', 'FALLÓ', 'El usuario no es miembro del rol esperado.');

    -- =========================================================================
    -- PRUEBA 2 (PERMITIDO): Ejecución de SP del esquema partido
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_operador_partido';
        EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_part, @asistencia_publico = 58400;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'partido.sp_RegistrarAsistenciaPublico', 'Operación permitida en esquema partido', 'Permiso GRANT', 'OK', 'Asistencia del partido registrada exitosamente por el operador.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'partido.sp_RegistrarAsistenciaPublico', 'Operación permitida en esquema partido', 'Permiso GRANT', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 3 (PERMITIDO): Designar árbitro y cargar informe (se cifra al guardar)
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_operador_partido';
        EXEC arbitraje.sp_DesignarArbitro @ID_Partido = @id_part, @ID_Arbitro = @id_arb, @Rol = 'Árbitro Principal', @Informe = 'Informe cargado por operador y cifrado automáticamente.';
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'arbitraje.sp_DesignarArbitro', 'Designación arbitral con cifrado transparente de informe', 'Permiso GRANT', 'OK', 'Designación e informe cifrados y guardados correctamente.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'arbitraje.sp_DesignarArbitro', 'Designación arbitral con cifrado transparente de informe', 'Permiso GRANT', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 4 (DENEGADO - ERROR 229): Intento de SELECT directo en tabla física
    -- =========================================================================
    BEGIN TRY
        DECLARE @inf_plano VARCHAR(1000);
        EXECUTE AS LOGIN = 'usr_operador_partido';
        SELECT @inf_plano = informe FROM arbitraje.Designacion_Arbitral WHERE ID_Partido = @id_part AND ID_Arbitro = @id_arb;
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'SELECT Designacion_Arbitral', 'Bloqueo de SELECT directo sobre tabla física', 'Bloqueo DENY (229)', 'FALLÓ', 'Debió arrojar Error 229 de permiso denegado.');
    END TRY
    BEGIN CATCH
        DECLARE @err4 INT = ERROR_NUMBER(), @msg4 VARCHAR(500) = ERROR_MESSAGE();
        REVERT;
        IF @err4 = 229
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'SELECT Designacion_Arbitral', 'Bloqueo de SELECT directo sobre tabla física', 'Bloqueo DENY (229)', 'OK', 'Error 229 capturado: ' + @msg4);
        ELSE
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'SELECT Designacion_Arbitral', 'Bloqueo de SELECT directo sobre tabla física', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(@err4 AS VARCHAR(10)) + '): ' + @msg4);
    END CATCH;

    -- =========================================================================
    -- PRUEBA 5 (DENEGADO - ERROR 229): Intento de usar sp_ConsultarInformesArbitrales
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_operador_partido';
        EXEC arbitraje.sp_ConsultarInformesArbitrales @ID_Partido = @id_part;
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'sp_ConsultarInformesArbitrales', 'Bloqueo de lectura de informes arbitrales desencriptados', 'Bloqueo DENY (229)', 'FALLÓ', 'Debió arrojar Error 229 de permiso denegado.');
    END TRY
    BEGIN CATCH
        DECLARE @err5 INT = ERROR_NUMBER(), @msg5 VARCHAR(500) = ERROR_MESSAGE();
        REVERT;
        IF @err5 = 229
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'sp_ConsultarInformesArbitrales', 'Bloqueo de lectura de informes arbitrales desencriptados', 'Bloqueo DENY (229)', 'OK', 'Error 229 capturado: ' + @msg5);
        ELSE
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'sp_ConsultarInformesArbitrales', 'Bloqueo de lectura de informes arbitrales desencriptados', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(@err5 AS VARCHAR(10)) + '): ' + @msg5);
    END CATCH;

    -- =========================================================================
    -- PRUEBA 6 (DENEGADO - ERROR 229): Intento de usar sp_ConsultarJugadorSensible
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_operador_partido';
        EXEC administracion.sp_ConsultarJugadorSensible;
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'sp_ConsultarJugadorSensible', 'Bloqueo de lectura de fecha_nacimiento desencriptada', 'Bloqueo DENY (229)', 'FALLÓ', 'Debió arrojar Error 229 de permiso denegado.');
    END TRY
    BEGIN CATCH
        DECLARE @err6 INT = ERROR_NUMBER(), @msg6 VARCHAR(500) = ERROR_MESSAGE();
        REVERT;
        IF @err6 = 229
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'sp_ConsultarJugadorSensible', 'Bloqueo de lectura de fecha_nacimiento desencriptada', 'Bloqueo DENY (229)', 'OK', 'Error 229 capturado: ' + @msg6);
        ELSE
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'sp_ConsultarJugadorSensible', 'Bloqueo de lectura de fecha_nacimiento desencriptada', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(@err6 AS VARCHAR(10)) + '): ' + @msg6);
    END CATCH;

    -- =========================================================================
    -- PRUEBA 7 (DENEGADO - ERROR 229): Intento de usar sp_ConsultarBajasMedicasSensibles
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_operador_partido';
        EXEC administracion.sp_ConsultarBajasMedicasSensibles;
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'sp_ConsultarBajasMedicasSensibles', 'Bloqueo de lectura de diagnósticos médicos desencriptados', 'Bloqueo DENY (229)', 'FALLÓ', 'Debió arrojar Error 229 de permiso denegado.');
    END TRY
    BEGIN CATCH
        DECLARE @err7 INT = ERROR_NUMBER(), @msg7 VARCHAR(500) = ERROR_MESSAGE();
        REVERT;
        IF @err7 = 229
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'sp_ConsultarBajasMedicasSensibles', 'Bloqueo de lectura de diagnósticos médicos desencriptados', 'Bloqueo DENY (229)', 'OK', 'Error 229 capturado: ' + @msg7);
        ELSE
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'sp_ConsultarBajasMedicasSensibles', 'Bloqueo de lectura de diagnósticos médicos desencriptados', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(@err7 AS VARCHAR(10)) + '): ' + @msg7);
    END CATCH;

    -- =========================================================================
    -- PRUEBA 8 (DENEGADO - ERROR 229): Intento de ejecutar SP de publicidad
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_operador_partido';
        EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Sponsor Intruso', @id_generado = @id_anun OUTPUT;
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'publicidad.sp_RegistrarAnunciante', 'Bloqueo de ejecución en esquema ajeno (publicidad)', 'Bloqueo DENY (229)', 'FALLÓ', 'Debió arrojar Error 229 de permiso denegado.');
    END TRY
    BEGIN CATCH
        DECLARE @err8 INT = ERROR_NUMBER(), @msg8 VARCHAR(500) = ERROR_MESSAGE();
        REVERT;
        IF @err8 = 229
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'publicidad.sp_RegistrarAnunciante', 'Bloqueo de ejecución en esquema ajeno (publicidad)', 'Bloqueo DENY (229)', 'OK', 'Error 229 capturado: ' + @msg8);
        ELSE
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'publicidad.sp_RegistrarAnunciante', 'Bloqueo de ejecución en esquema ajeno (publicidad)', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(@err8 AS VARCHAR(10)) + '): ' + @msg8);
    END CATCH;

    -- =========================================================================
    -- PRUEBA 9 (DENEGADO - ERROR 229): Intento de INSERT directo en tabla física
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_operador_partido';
        INSERT INTO administracion.Club (nombre) VALUES ('Club Directo Prohibido');
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_operador_partido', 'INSERT administracion.Club', 'Bloqueo de modificación directa sobre tabla física', 'Bloqueo DENY (229)', 'FALLÓ', 'Debió arrojar Error 229 de permiso denegado.');
    END TRY
    BEGIN CATCH
        DECLARE @err9 INT = ERROR_NUMBER(), @msg9 VARCHAR(500) = ERROR_MESSAGE();
        REVERT;
        IF @err9 = 229
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'INSERT administracion.Club', 'Bloqueo de modificación directa sobre tabla física', 'Bloqueo DENY (229)', 'OK', 'Error 229 capturado: ' + @msg9);
        ELSE
            INSERT INTO @Reporte VALUES ('usr_operador_partido', 'INSERT administracion.Club', 'Bloqueo de modificación directa sobre tabla física', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(@err9 AS VARCHAR(10)) + '): ' + @msg9);
    END CATCH;

END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO @Reporte VALUES ('usr_operador_partido', 'Bloque General', 'Excepción crítica no controlada', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
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
