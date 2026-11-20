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

   Script: test_rol_medico.sql
   
   Descripción: Lote de pruebas de permisos y seguridad para el rol [rol_medico]
                evaluado mediante su login asociado [usr_medico].
                Verifica mediante cambio de contexto (EXECUTE AS LOGIN = 'usr_medico') que:
                1. Pertenece efectivamente al rol [rol_medico].
                2. SÍ PUEDE registrar bajas médicas cifrando el motivo (sp_RegistrarBajaConvocatoria).
                3. SÍ PUEDE consultar bajas médicas descifradas (sp_ConsultarBajasMedicasSensibles).
                4. SÍ PUEDE consultar ficha y fecha de nacimiento descifrada (sp_ConsultarJugadorSensible).
                5. SÍ PUEDE consultar el reporte de selecciones y plantillas (sp_ReporteSeleccionesPlantillas).
                6. NO PUEDE (Error 229) hacer SELECT directo sobre tablas físicas.
                7. NO PUEDE (Error 229) ejecutar arbitraje.sp_ConsultarInformesArbitrales.
                8. NO PUEDE (Error 229) ejecutar SPs administrativos no médicos (ej. sp_InsertarPais).
                9. NO PUEDE (Error 229) ejecutar SPs del esquema partido ni publicidad.
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
PRINT 'INICIANDO TEST DE ROL Y PERMISOS: rol_medico';
PRINT '======================================================================';

BEGIN TRANSACTION;
BEGIN TRY

    -- Preparar datos maestros como dbo
    DECLARE @id_p1 INT, @id_club INT, @id_sel INT, @id_jug INT, @id_jug2 INT, @id_conv INT, @id_conv2 INT, @id_p_nuevo INT, @id_anun INT;

    EXEC administracion.sp_InsertarPais @nombre = 'Pais Medico Test', @huso_horario = '-03:00', @id_generado = @id_p1 OUTPUT;
    EXEC administracion.sp_InsertarClub @nombre = 'Club Medico FC', @id_generado = @id_club OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p1, @confederacion = 'CONMEBOL', @grupo_asignado = 'A', @id_generado = @id_sel OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Marcos', @apellido = 'Acuna Med', @fecha_nacimiento = '1991-10-28', @id_club = @id_club, @posicion_habitual = 'Defensor', @id_generado = @id_jug OUTPUT;
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_jug, @id_seleccion = @id_sel, @dorsal = 8, @id_generado = @id_conv OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Rodrigo', @apellido = 'De Paul Med', @fecha_nacimiento = '1994-05-24', @id_club = @id_club, @posicion_habitual = 'Mediocampista', @id_generado = @id_jug2 OUTPUT;
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_jug2, @id_seleccion = @id_sel, @dorsal = 7, @id_generado = @id_conv2 OUTPUT;

    -- =========================================================================
    -- PRUEBA 1: Verificación de membresía en rol_medico
    -- =========================================================================
    DECLARE @es_miembro INT = 0;
    EXECUTE AS LOGIN = 'usr_medico';
    SET @es_miembro = IS_ROLEMEMBER('rol_medico');
    REVERT;

    IF @es_miembro = 1
        INSERT INTO @Reporte VALUES ('usr_medico', 'rol_medico', 'Verificación de membresía activa en el rol', 'Membresía RBAC', 'OK', 'El usuario pertenece correctamente a [rol_medico].');
    ELSE
        INSERT INTO @Reporte VALUES ('usr_medico', 'rol_medico', 'Verificación de membresía activa en el rol', 'Membresía RBAC', 'FALLÓ', 'El usuario no es miembro del rol esperado.');

    -- =========================================================================
    -- PRUEBA 2 (PERMITIDO): Registro de baja médica con motivo cifrado
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_medico';
        EXEC administracion.sp_RegistrarBajaConvocatoria @id_jugador = @id_jug, @motivo = 'Desgarro muscular en isquiotibial izquierdo', @fecha = '2026-06-12';
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.sp_RegistrarBajaConvocatoria', 'Registro de baja médica con cifrado AES-256', 'Permiso GRANT + Cifrado', 'OK', 'Baja médica registrada y cifrada exitosamente por el médico.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.sp_RegistrarBajaConvocatoria', 'Registro de baja médica con cifrado AES-256', 'Permiso GRANT + Cifrado', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 3 (PERMITIDO): Consulta de bajas médicas descifradas
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_medico';
        EXEC administracion.sp_ConsultarBajasMedicasSensibles;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.sp_ConsultarBajasMedicasSensibles', 'Lectura autorizada de motivos médicos descifrados', 'Permiso GRANT + Cifrado', 'OK', 'Motivo médico descifrado consultado correctamente.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.sp_ConsultarBajasMedicasSensibles', 'Lectura autorizada de motivos médicos descifrados', 'Permiso GRANT + Cifrado', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 4 (PERMITIDO): Consulta de ficha sensible de jugador
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_medico';
        EXEC administracion.sp_ConsultarJugadorSensible @id_jugador = @id_jug;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.sp_ConsultarJugadorSensible', 'Lectura autorizada de fecha de nacimiento descifrada', 'Permiso GRANT + Cifrado', 'OK', 'Ficha sensible del jugador consultada correctamente.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.sp_ConsultarJugadorSensible', 'Lectura autorizada de fecha de nacimiento descifrada', 'Permiso GRANT + Cifrado', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 5 (PERMITIDO): Reporte de selecciones y plantillas
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_medico';
        EXEC administracion.sp_ReporteSeleccionesPlantillas;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.sp_ReporteSeleccionesPlantillas', 'Consulta de reporte de plantillas convocadas', 'Permiso GRANT', 'OK', 'Reporte de selecciones y plantillas ejecutado correctamente.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.sp_ReporteSeleccionesPlantillas', 'Consulta de reporte de plantillas convocadas', 'Permiso GRANT', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 6 (DENEGADO): SELECT directo sobre tabla física
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_medico';
        EXEC sp_executesql N'SELECT TOP 1 ID FROM administracion.Convocatoria;';
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.Convocatoria', 'Intento de SELECT directo sobre tabla física', 'Bloqueo DENY (229)', 'FALLÓ', 'Permitió leer la tabla física directamente.');
    END TRY
    BEGIN CATCH
        REVERT;
        IF ERROR_NUMBER() = 229
            INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.Convocatoria', 'Intento de SELECT directo sobre tabla física', 'Bloqueo DENY (229)', 'OK', 'Bloqueado correctamente (Error 229).');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.Convocatoria', 'Intento de SELECT directo sobre tabla física', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '): ' + ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 7 (DENEGADO): Lectura de informes arbitrales descifrados
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_medico';
        EXEC arbitraje.sp_ConsultarInformesArbitrales;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_medico', 'arbitraje.sp_ConsultarInformesArbitrales', 'Intento de leer informes arbitrales confidenciales', 'Bloqueo DENY (229)', 'FALLÓ', 'El médico logró leer informes arbitrales.');
    END TRY
    BEGIN CATCH
        REVERT;
        IF ERROR_NUMBER() = 229
            INSERT INTO @Reporte VALUES ('usr_medico', 'arbitraje.sp_ConsultarInformesArbitrales', 'Intento de leer informes arbitrales confidenciales', 'Bloqueo DENY (229)', 'OK', 'Bloqueado correctamente (Error 229).');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_medico', 'arbitraje.sp_ConsultarInformesArbitrales', 'Intento de leer informes arbitrales confidenciales', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '): ' + ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 8 (DENEGADO): SP administrativo no médico (sp_InsertarPais)
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_medico';
        EXEC administracion.sp_InsertarPais @nombre = 'Pais Ilegal Med', @huso_horario = '-03:00', @id_generado = @id_p_nuevo OUTPUT;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.sp_InsertarPais', 'Intento de alta administrativa fuera de rol médico', 'Bloqueo Implícito (229)', 'FALLÓ', 'El médico logró insertar un país.');
    END TRY
    BEGIN CATCH
        REVERT;
        IF ERROR_NUMBER() = 229
            INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.sp_InsertarPais', 'Intento de alta administrativa fuera de rol médico', 'Bloqueo Implícito (229)', 'OK', 'Bloqueado correctamente (Error 229).');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_medico', 'administracion.sp_InsertarPais', 'Intento de alta administrativa fuera de rol médico', 'Bloqueo Implícito (229)', 'FALLÓ', 'Error inesperado (' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '): ' + ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 9 (DENEGADO): SP del esquema publicidad
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_medico';
        EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Sponsor Ilegal Med', @id_generado = @id_anun OUTPUT;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_medico', 'publicidad.sp_RegistrarAnunciante', 'Intento de operar en esquema publicidad', 'Bloqueo DENY (229)', 'FALLÓ', 'El médico logró registrar un anunciante.');
    END TRY
    BEGIN CATCH
        REVERT;
        IF ERROR_NUMBER() = 229
            INSERT INTO @Reporte VALUES ('usr_medico', 'publicidad.sp_RegistrarAnunciante', 'Intento de operar en esquema publicidad', 'Bloqueo DENY (229)', 'OK', 'Bloqueado correctamente (Error 229).');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_medico', 'publicidad.sp_RegistrarAnunciante', 'Intento de operar en esquema publicidad', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '): ' + ERROR_MESSAGE());
    END CATCH;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO @Reporte VALUES ('usr_medico', 'ERROR GENERAL', 'Error inesperado preparando datos de prueba', 'Control Test', 'FALLÓ', ERROR_MESSAGE());
END CATCH;

SELECT ID, Usuario_Evaluado, Objeto_Evaluado, Escenario, Tipo_Prueba, Resultado, Detalle
FROM @Reporte
ORDER BY ID;
GO
