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
     
   Script: test_rol_comite_arbitral.sql
   
   Descripción: Lote de pruebas de permisos y seguridad para el rol [rol_comite_arbitral]
                evaluado mediante su login asociado [usr_comite_arbitral].
                Verifica mediante cambio de contexto (EXECUTE AS LOGIN = 'usr_comite_arbitral') que:
                1. Pertenece efectivamente al rol [rol_comite_arbitral].
                2. SÍ PUEDE dar de alta árbitros (arbitraje.sp_InsertarArbitro).
                3. SÍ PUEDE designar árbitros con informe cifrado (arbitraje.sp_DesignarArbitro).
                4. SÍ PUEDE consultar informes arbitrales descifrados (arbitraje.sp_ConsultarInformesArbitrales).
                5. SÍ PUEDE consultar el reporte disciplinario (partido.sp_ReporteTarjetasYSuspensiones).
                6. NO PUEDE (Error 229) hacer SELECT directo sobre tablas físicas.
                7. NO PUEDE (Error 229) ejecutar administracion.sp_ConsultarJugadorSensible.
                8. NO PUEDE (Error 229) ejecutar administracion.sp_ConsultarBajasMedicasSensibles.
                9. NO PUEDE (Error 229) ejecutar SPs del esquema publicidad.
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
PRINT 'INICIANDO TEST DE ROL Y PERMISOS: rol_comite_arbitral';
PRINT '======================================================================';

BEGIN TRANSACTION;
BEGIN TRY

    -- Preparar datos maestros como dbo
    DECLARE @id_p1 INT, @id_p2 INT, @id_p3 INT, @id_sede INT, @id_fase INT;
    DECLARE @id_sel1 INT, @id_sel2 INT, @id_part INT, @id_arb INT, @id_anun INT;

    EXEC administracion.sp_InsertarPais @nombre = 'Pais Comite 1', @huso_horario = '-03:00', @id_generado = @id_p1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Comite 2', @huso_horario = '+01:00', @id_generado = @id_p2 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Comite Arb', @huso_horario = '+02:00', @id_generado = @id_p3 OUTPUT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Comite Test', @ciudad = 'Miami', @capacidad = 65000, @huso_horario = '-05:00', @id_pais = @id_p1, @id_generado = @id_sede OUTPUT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Comite Test', @orden = 94, @id_generado = @id_fase OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p1, @confederacion = 'CONMEBOL', @grupo_asignado = 'A', @id_generado = @id_sel1 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p2, @confederacion = 'UEFA', @grupo_asignado = 'B', @id_generado = @id_sel2 OUTPUT;
    EXEC partido.sp_CrearPartido @id_sede = @id_sede, @id_fase = @id_fase, @fecha_hora_local = '2026-06-23 19:00:00', @id_local = @id_sel1, @id_visitante = @id_sel2;
    SELECT TOP 1 @id_part = ID FROM partido.Partido ORDER BY ID DESC;

    -- =========================================================================
    -- PRUEBA 1: Verificación de membresía en rol_comite_arbitral
    -- =========================================================================
    DECLARE @es_miembro INT = 0;
    EXECUTE AS LOGIN = 'usr_comite_arbitral';
    SET @es_miembro = IS_ROLEMEMBER('rol_comite_arbitral');
    REVERT;

    IF @es_miembro = 1
        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'rol_comite_arbitral', 'Verificación de membresía activa en el rol', 'Membresía RBAC', 'OK', 'El usuario pertenece correctamente a [rol_comite_arbitral].');
    ELSE
        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'rol_comite_arbitral', 'Verificación de membresía activa en el rol', 'Membresía RBAC', 'FALLÓ', 'El usuario no es miembro del rol esperado.');

    -- =========================================================================
    -- PRUEBA 2 (PERMITIDO): Alta de árbitro (arbitraje.sp_InsertarArbitro)
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_comite_arbitral';
        EXEC arbitraje.sp_InsertarArbitro @Nombre = 'Pierluigi', @Apellido = 'Collina Test', @Categoria = 'FIFA Elite', @ID_Pais = @id_p3, @ID = @id_arb OUTPUT;
        REVERT;

        IF @id_arb IS NOT NULL
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'arbitraje.sp_InsertarArbitro', 'Alta de árbitro autorizada al comité', 'Permiso GRANT', 'OK', 'Árbitro registrado con ID ' + CAST(@id_arb AS VARCHAR(10)) + '.');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'arbitraje.sp_InsertarArbitro', 'Alta de árbitro autorizada al comité', 'Permiso GRANT', 'FALLÓ', 'No devolvió ID generado.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'arbitraje.sp_InsertarArbitro', 'Alta de árbitro autorizada al comité', 'Permiso GRANT', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 3 (PERMITIDO): Designación arbitral con informe cifrado
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_comite_arbitral';
        EXEC arbitraje.sp_DesignarArbitro @ID_Partido = @id_part, @ID_Arbitro = @id_arb, @Rol = 'Árbitro Principal', @Informe = 'Informe disciplinario del comité arbitral.';
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'arbitraje.sp_DesignarArbitro', 'Designación arbitral e informe cifrado', 'Permiso GRANT + Cifrado', 'OK', 'Designación e informe cifrado registrados correctamente.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'arbitraje.sp_DesignarArbitro', 'Designación arbitral e informe cifrado', 'Permiso GRANT + Cifrado', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 4 (PERMITIDO): Lectura de informes arbitrales descifrados
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_comite_arbitral';
        EXEC arbitraje.sp_ConsultarInformesArbitrales @id_partido = @id_part;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'arbitraje.sp_ConsultarInformesArbitrales', 'Lectura autorizada de informes arbitrales descifrados', 'Permiso GRANT + Cifrado', 'OK', 'Consulta descifrada ejecutada correctamente por el comité.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'arbitraje.sp_ConsultarInformesArbitrales', 'Lectura autorizada de informes arbitrales descifrados', 'Permiso GRANT + Cifrado', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 5 (PERMITIDO): Permisos disciplinarios en esquema partido
    -- =========================================================================
    BEGIN TRY
        DECLARE @perm_susp BIT = 0, @perm_rep BIT = 0;
        EXECUTE AS LOGIN = 'usr_comite_arbitral';
        SET @perm_susp = HAS_PERMS_BY_NAME('partido.sp_ModificarSuspension', 'OBJECT', 'EXECUTE');
        SET @perm_rep  = HAS_PERMS_BY_NAME('partido.sp_ReporteTarjetasYSuspensiones', 'OBJECT', 'EXECUTE');
        REVERT;

        IF @perm_susp = 1 AND @perm_rep = 1
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'partido.sp_ModificarSuspension / Reporte', 'Permiso efectivo de gestión disciplinaria en partido', 'Permiso GRANT', 'OK', 'El comité posee EXECUTE efectivo sobre suspensiones y reporte disciplinario.');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'partido.sp_ModificarSuspension / Reporte', 'Permiso efectivo de gestión disciplinaria en partido', 'Permiso GRANT', 'FALLÓ', 'Falta permiso EXECUTE sobre algún SP disciplinario.');
    END TRY
    BEGIN CATCH
        REVERT;
        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'partido.sp_ModificarSuspension / Reporte', 'Permiso efectivo de gestión disciplinaria en partido', 'Permiso GRANT', 'FALLÓ', ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 6 (DENEGADO): SELECT directo sobre tabla física
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_comite_arbitral';
        EXEC sp_executesql N'SELECT TOP 1 ID_Partido FROM arbitraje.Designacion_Arbitral;';
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'arbitraje.Designacion_Arbitral', 'Intento de SELECT directo sobre tabla física', 'Bloqueo DENY (229)', 'FALLÓ', 'Permitió leer la tabla física directamente.');
    END TRY
    BEGIN CATCH
        REVERT;
        IF ERROR_NUMBER() = 229
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'arbitraje.Designacion_Arbitral', 'Intento de SELECT directo sobre tabla física', 'Bloqueo DENY (229)', 'OK', 'Bloqueado correctamente (Error 229).');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'arbitraje.Designacion_Arbitral', 'Intento de SELECT directo sobre tabla física', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '): ' + ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 7 (DENEGADO): Visor sensible de jugadores (administracion)
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_comite_arbitral';
        EXEC administracion.sp_ConsultarJugadorSensible;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'administracion.sp_ConsultarJugadorSensible', 'Intento de leer fechas de nacimiento descifradas', 'Bloqueo DENY (229)', 'FALLÓ', 'El comité logró ejecutar un visor sensible de administración.');
    END TRY
    BEGIN CATCH
        REVERT;
        IF ERROR_NUMBER() = 229
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'administracion.sp_ConsultarJugadorSensible', 'Intento de leer fechas de nacimiento descifradas', 'Bloqueo DENY (229)', 'OK', 'Bloqueado correctamente (Error 229).');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'administracion.sp_ConsultarJugadorSensible', 'Intento de leer fechas de nacimiento descifradas', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '): ' + ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 8 (DENEGADO): Visor sensible de bajas médicas (administracion)
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_comite_arbitral';
        EXEC administracion.sp_ConsultarBajasMedicasSensibles;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'administracion.sp_ConsultarBajasMedicasSensibles', 'Intento de leer motivos médicos descifrados', 'Bloqueo DENY (229)', 'FALLÓ', 'El comité logró leer bajas médicas confidenciales.');
    END TRY
    BEGIN CATCH
        REVERT;
        IF ERROR_NUMBER() = 229
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'administracion.sp_ConsultarBajasMedicasSensibles', 'Intento de leer motivos médicos descifrados', 'Bloqueo DENY (229)', 'OK', 'Bloqueado correctamente (Error 229).');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'administracion.sp_ConsultarBajasMedicasSensibles', 'Intento de leer motivos médicos descifrados', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '): ' + ERROR_MESSAGE());
    END CATCH;

    -- =========================================================================
    -- PRUEBA 9 (DENEGADO): SP del esquema publicidad
    -- =========================================================================
    BEGIN TRY
        EXECUTE AS LOGIN = 'usr_comite_arbitral';
        EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Intento Comite', @id_generado = @id_anun OUTPUT;
        REVERT;

        INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'publicidad.sp_RegistrarAnunciante', 'Intento de operar en esquema publicidad', 'Bloqueo DENY (229)', 'FALLÓ', 'El comité logró ejecutar un SP comercial.');
    END TRY
    BEGIN CATCH
        REVERT;
        IF ERROR_NUMBER() = 229
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'publicidad.sp_RegistrarAnunciante', 'Intento de operar en esquema publicidad', 'Bloqueo DENY (229)', 'OK', 'Bloqueado correctamente (Error 229).');
        ELSE
            INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'publicidad.sp_RegistrarAnunciante', 'Intento de operar en esquema publicidad', 'Bloqueo DENY (229)', 'FALLÓ', 'Error inesperado (' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '): ' + ERROR_MESSAGE());
    END CATCH;

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO @Reporte VALUES ('usr_comite_arbitral', 'ERROR GENERAL', 'Error inesperado preparando datos de prueba', 'Control Test', 'FALLÓ', ERROR_MESSAGE());
END CATCH;

SELECT ID, Usuario_Evaluado, Objeto_Evaluado, Escenario, Tipo_Prueba, Resultado, Detalle
FROM @Reporte
ORDER BY ID;
GO
