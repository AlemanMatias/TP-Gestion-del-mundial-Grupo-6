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
     
   Script: test_04_administracion.sql
   Descripción: Lote de pruebas unitarias para los Stored Procedures de 04_sp_administracion.sql.
                Valida los ciclos completos de ABM de las 8 tablas maestras y las reglas de negocio FIFA.
                Ejecuta de forma totalmente aislada (ROLLBACK) y consolida un reporte visual en la grilla de Resultados.
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

-- Tabla en memoria para consolidar el reporte visual final (inmune a ROLLBACK)
DECLARE @Reporte TABLE (
    ID INT IDENTITY(1,1),
    Procedimiento VARCHAR(50),
    Escenario VARCHAR(65),
    Tipo_Prueba VARCHAR(25),
    Resultado VARCHAR(10),
    Detalle VARCHAR(255)
);

PRINT '======================================================================';
PRINT 'INICIANDO LOTE DE PRUEBAS 1:1 - MÓDULO ADMINISTRACIÓN (04)';
PRINT '======================================================================';

-- =========================================================================================
-- 1. PRUEBAS: administracion.Pais (Alta, Modificación, Baja)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_test INT;

    -- 1.A. Inserción exitosa
    EXEC administracion.sp_InsertarPais
        @nombre = 'País Prueba Test',
        @pbi_percapita = 45000.50,
        @huso_horario = '+02:00',
        @id_generado = @id_pais_test OUTPUT;

    INSERT INTO @Reporte VALUES ('sp_InsertarPais', 'Alta exitosa con PBI y huso', 'Caso de Éxito', 'OK', 'Generó ID: ' + CAST(@id_pais_test AS VARCHAR(10)));

    -- 1.B. Error: Nombre duplicado
    BEGIN TRY
        EXEC administracion.sp_InsertarPais
            @nombre = 'País Prueba Test',
            @id_generado = @id_pais_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarPais', 'Bloqueo por nombre duplicado', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50002');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarPais', 'Bloqueo por nombre duplicado', 'Validación THROW', 'OK', 'Capturado 50002: ' + ERROR_MESSAGE());
    END CATCH;

    -- 1.C. Modificación exitosa
    EXEC administracion.sp_ModificarPais
        @id = @id_pais_test,
        @nombre = 'País Prueba Modificado',
        @pbi_percapita = 50000.00,
        @huso_horario = '+03:00';
    INSERT INTO @Reporte VALUES ('sp_ModificarPais', 'Actualización correcta de datos', 'Caso de Éxito', 'OK', 'Modificado ID: ' + CAST(@id_pais_test AS VARCHAR(10)));

    -- 1.D. Eliminación exitosa
    EXEC administracion.sp_EliminarPais @id = @id_pais_test;
    INSERT INTO @Reporte VALUES ('sp_EliminarPais', 'Baja física de país sin relaciones', 'Caso de Éxito', 'OK', 'Eliminado correctamente');

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Pais', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 2. PRUEBAS: administracion.Fase_Torneo (Alta, Modificación, Baja)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_fase_test INT;

    -- 2.A. Alta exitosa
    EXEC administracion.sp_InsertarFaseTorneo
        @nombre = 'Fase Extra Test',
        @orden = 99,
        @id_generado = @id_fase_test OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InsertarFaseTorneo', 'Alta exitosa de nueva fase', 'Caso de Éxito', 'OK', 'Fase ID: ' + CAST(@id_fase_test AS VARCHAR(10)));

    -- 2.B. Error: Orden cronológico duplicado
    BEGIN TRY
        DECLARE @id_fase_fallida INT;
        EXEC administracion.sp_InsertarFaseTorneo
            @nombre = 'Fase Duplicada Orden',
            @orden = 99,
            @id_generado = @id_fase_fallida OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarFaseTorneo', 'Bloqueo por orden correlativo duplicado', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50013');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarFaseTorneo', 'Bloqueo por orden correlativo duplicado', 'Validación THROW', 'OK', 'Capturado 50013');
    END CATCH;

    -- 2.C. Modificación exitosa
    EXEC administracion.sp_ModificarFaseTorneo
        @id = @id_fase_test,
        @nombre = 'Fase Extra Renombrada',
        @orden = 99;
    INSERT INTO @Reporte VALUES ('sp_ModificarFaseTorneo', 'Modificación de nombre de fase', 'Caso de Éxito', 'OK', 'Modificado correctamente');

    -- 2.D. Baja exitosa
    EXEC administracion.sp_EliminarFaseTorneo @id = @id_fase_test;
    INSERT INTO @Reporte VALUES ('sp_EliminarFaseTorneo', 'Baja de fase sin partidos asociados', 'Caso de Éxito', 'OK', 'Eliminado correctamente');

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('FaseTorneo', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 3. PRUEBAS: administracion.Club (Alta, Modificación, Baja)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_club_extra INT;

    -- 3.A. Alta exitosa
    EXEC administracion.sp_InsertarClub
        @nombre = 'Deportivo Prueba FC',
        @id_generado = @id_club_extra OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InsertarClub', 'Alta exitosa de nuevo club', 'Caso de Éxito', 'OK', 'Club ID: ' + CAST(@id_club_extra AS VARCHAR(10)));

    -- 3.B. Error: Club con nombre duplicado
    BEGIN TRY
        DECLARE @id_club_fallido INT;
        EXEC administracion.sp_InsertarClub
            @nombre = 'Deportivo Prueba FC',
            @id_generado = @id_club_fallido OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarClub', 'Bloqueo por nombre de club duplicado', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50021');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarClub', 'Bloqueo por nombre de club duplicado', 'Validación THROW', 'OK', 'Capturado 50021');
    END CATCH;

    -- 3.C. Modificación exitosa
    EXEC administracion.sp_ModificarClub
        @id = @id_club_extra,
        @nombre = 'Deportivo Prueba Modificado FC';
    INSERT INTO @Reporte VALUES ('sp_ModificarClub', 'Actualización de nombre de club', 'Caso de Éxito', 'OK', 'Modificado correctamente');

    -- 3.D. Baja exitosa
    EXEC administracion.sp_EliminarClub @id = @id_club_extra;
    INSERT INTO @Reporte VALUES ('sp_EliminarClub', 'Baja física de club sin jugadores', 'Caso de Éxito', 'OK', 'Eliminado correctamente');

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Club', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 4. PRUEBAS: administracion.Sede (Alta, Modificación, Baja)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_sede INT, @id_sede_test INT;
    EXEC administracion.sp_InsertarPais @nombre = 'País Sede Test', @id_generado = @id_pais_sede OUTPUT;

    -- Sede Alta exitosa
    EXEC administracion.sp_InsertarSede
        @nombre = 'Estadio Prueba Central',
        @ciudad = 'Ciudad Deportiva',
        @capacidad = 60000,
        @huso_horario = '-03:00',
        @id_pais = @id_pais_sede,
        @id_generado = @id_sede_test OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InsertarSede', 'Alta de estadio reglamentario', 'Caso de Éxito', 'OK', 'Sede ID: ' + CAST(@id_sede_test AS VARCHAR(10)));

    -- Sede Error: Formato de huso horario incorrecto
    BEGIN TRY
        EXEC administracion.sp_InsertarSede
            @nombre = 'Estadio Fallido',
            @ciudad = 'Ciudad Deportiva',
            @capacidad = 50000,
            @huso_horario = 'GMT-3', -- inválido
            @id_pais = @id_pais_sede,
            @id_generado = @id_sede_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarSede', 'Bloqueo por huso horario fuera de formato', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50033');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarSede', 'Bloqueo por huso horario fuera de formato', 'Validación THROW', 'OK', 'Capturado 50033: ' + ERROR_MESSAGE());
    END CATCH;

    -- Sede Modificación exitosa
    EXEC administracion.sp_ModificarSede
        @id = @id_sede_test,
        @nombre = 'Estadio Prueba Remodelado',
        @ciudad = 'Ciudad Deportiva',
        @capacidad = 65000,
        @huso_horario = '-03:00',
        @id_pais = @id_pais_sede;
    INSERT INTO @Reporte VALUES ('sp_ModificarSede', 'Ampliación de capacidad de estadio', 'Caso de Éxito', 'OK', 'Modificado ID: ' + CAST(@id_sede_test AS VARCHAR(10)));

    -- Sede Baja exitosa
    EXEC administracion.sp_EliminarSede @id = @id_sede_test;
    INSERT INTO @Reporte VALUES ('sp_EliminarSede', 'Baja de estadio sin partidos', 'Caso de Éxito', 'OK', 'Eliminado correctamente');

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Sede', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 5. PRUEBAS: administracion.Seleccion (Cupos FIFA, Grupos y Modificación)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_sel INT, @id_sel_test INT;

    EXEC administracion.sp_InsertarPais @nombre = 'País Selección Test', @pbi_percapita = 30000, @huso_horario = '+00:00', @id_generado = @id_pais_sel OUTPUT;

    -- 5.A. Alta exitosa
    EXEC administracion.sp_InsertarSeleccion
        @id_pais = @id_pais_sel,
        @confederacion = 'UEFA',
        @grupo_asignado = 'B',
        @id_generado = @id_sel_test OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InsertarSeleccion', 'Asignación correcta a Grupo B', 'Caso de Éxito', 'OK', 'Selección ID: ' + CAST(@id_sel_test AS VARCHAR(10)));

    -- 5.B. Error: Confederación inválida
    BEGIN TRY
        EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_sel, @confederacion = 'LIGA_FANTASMA', @grupo_asignado = 'B', @id_generado = @id_sel_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarSeleccion', 'Bloqueo por confederación inválida', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50042');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarSeleccion', 'Bloqueo por confederación inválida', 'Validación THROW', 'OK', 'Capturado 50042');
    END CATCH;

    -- 5.C. Error: Grupo fuera de rango (ej: Grupo Z)
    BEGIN TRY
        DECLARE @id_pais_otro INT;
        EXEC administracion.sp_InsertarPais @nombre = 'País Grupo Z', @id_generado = @id_pais_otro OUTPUT;
        EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_otro, @confederacion = 'UEFA', @grupo_asignado = 'Z', @id_generado = @id_sel_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarSeleccion', 'Bloqueo por grupo fuera de A-L', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50043');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarSeleccion', 'Bloqueo por grupo fuera de A-L', 'Validación THROW', 'OK', 'Capturado 50043');
    END CATCH;

    -- 5.D. Modificación exitosa (Reubicación a Grupo C)
    EXEC administracion.sp_ModificarSeleccion
        @id = @id_sel_test,
        @id_pais = @id_pais_sel,
        @confederacion = 'UEFA',
        @grupo_asignado = 'C';
    INSERT INTO @Reporte VALUES ('sp_ModificarSeleccion', 'Reubicación de grupo a Grupo C', 'Caso de Éxito', 'OK', 'Modificado correctamente');

    -- 5.E. Baja exitosa
    EXEC administracion.sp_EliminarSeleccion @id = @id_sel_test;
    INSERT INTO @Reporte VALUES ('sp_EliminarSeleccion', 'Baja de selección sin plantel ni partidos', 'Caso de Éxito', 'OK', 'Eliminado correctamente');

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Seleccion', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 6. PRUEBAS: administracion.Miembro_Cuerpo_Tecnico (Roles FIFA y Bloqueo 1 DT)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_ct INT, @id_sel_ct INT;
    DECLARE @id_dt_test INT, @id_ayudante_test INT;

    EXEC administracion.sp_InsertarPais @nombre = 'País Cuerpo Técnico Test', @id_generado = @id_pais_ct OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_ct, @confederacion = 'CONMEBOL', @grupo_asignado = 'H', @id_generado = @id_sel_ct OUTPUT;

    -- 6.A. Alta exitosa de Director Técnico principal
    EXEC administracion.sp_InsertarMiembroCuerpoTecnico
        @nombre = 'Lionel', @apellido = 'Scaloni Test',
        @rol = 'Director Técnico', @id_seleccion = @id_sel_ct,
        @id_generado = @id_dt_test OUTPUT;

    INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Alta exitosa de Director Técnico principal', 'Caso de Éxito', 'OK', 'DT ID: ' + CAST(@id_dt_test AS VARCHAR(10)));

    -- 6.B. Error: Bloqueo anti-"carnicero" (Rol no oficial)
    BEGIN TRY
        EXEC administracion.sp_InsertarMiembroCuerpoTecnico
            @nombre = 'Juan', @apellido = 'Pérez',
            @rol = 'Carnicero', @id_seleccion = @id_sel_ct,
            @id_generado = @id_ayudante_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Bloqueo de rol no oficial (Carnicero)', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50052');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Bloqueo de rol no oficial (Carnicero)', 'Validación THROW', 'OK', 'Capturado 50052: ' + ERROR_MESSAGE());
    END CATCH;

    -- 6.C. Error: Bloqueo de 2do Director Técnico principal en la misma selección
    BEGIN TRY
        EXEC administracion.sp_InsertarMiembroCuerpoTecnico
            @nombre = 'Marcelo', @apellido = 'Gallardo Test',
            @rol = 'Director Técnico', @id_seleccion = @id_sel_ct,
            @id_generado = @id_ayudante_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Bloqueo de 2do DT principal en misma selección', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50054');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Bloqueo de 2do DT principal en misma selección', 'Validación THROW', 'OK', 'Capturado 50054: ' + ERROR_MESSAGE());
    END CATCH;

    -- 6.D. Alta exitosa de Ayudante de Campo (Rol secundario permitido)
    EXEC administracion.sp_InsertarMiembroCuerpoTecnico
        @nombre = 'Pablo', @apellido = 'Aimar Test',
        @rol = 'Ayudante de Campo', @id_seleccion = @id_sel_ct,
        @id_generado = @id_ayudante_test OUTPUT;

    INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Alta exitosa de Ayudante de Campo', 'Caso de Éxito', 'OK', 'Ayudante ID: ' + CAST(@id_ayudante_test AS VARCHAR(10)));

    -- 6.E. Modificación exitosa
    EXEC administracion.sp_ModificarMiembroCuerpoTecnico
        @id = @id_ayudante_test,
        @nombre = 'Pablo César', @apellido = 'Aimar Test',
        @rol = 'Preparador Fisico', @id_seleccion = @id_sel_ct;

    INSERT INTO @Reporte VALUES ('sp_ModificarMiembroCuerpoTecnico', 'Modificación de rol a Preparador Físico', 'Caso de Éxito', 'OK', 'Actualizado correctamente');

    -- 6.F. Baja exitosa
    EXEC administracion.sp_EliminarMiembroCuerpoTecnico @id = @id_ayudante_test;
    INSERT INTO @Reporte VALUES ('sp_EliminarMiembroCuerpoTecnico', 'Baja de miembro sin tarjetas asociadas', 'Caso de Éxito', 'OK', 'Eliminado correctamente');

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('CuerpoTecnico', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 7. PRUEBAS: administracion.Jugador (Alta, Modificación, Baja)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_club_test INT, @id_jug_test INT;
    EXEC administracion.sp_InsertarClub @nombre = 'Club Test FC', @id_generado = @id_club_test OUTPUT;

    -- 7.A. Alta exitosa
    EXEC administracion.sp_InsertarJugador
        @nombre = 'Lautaro', @apellido = 'Test',
        @fecha_nacimiento = '2000-01-01', @id_club = @id_club_test,
        @posicion_habitual = 'Delantero', @id_generado = @id_jug_test OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InsertarJugador', 'Alta de jugador mayor a 15 años', 'Caso de Éxito', 'OK', 'Jugador ID: ' + CAST(@id_jug_test AS VARCHAR(10)));

    -- 7.B. Error: Menor a 15 años
    BEGIN TRY
        EXEC administracion.sp_InsertarJugador
            @nombre = 'Niño', @apellido = 'Test',
            @fecha_nacimiento = '2020-01-01', @id_club = @id_club_test,
            @posicion_habitual = 'Delantero', @id_generado = @id_jug_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarJugador', 'Bloqueo por edad menor a 15 años', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50063');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarJugador', 'Bloqueo por edad menor a 15 años', 'Validación THROW', 'OK', 'Capturado 50063');
    END CATCH;

    -- 7.C. Modificación exitosa
    EXEC administracion.sp_ModificarJugador
        @id = @id_jug_test,
        @nombre = 'Lautaro Javier',
        @apellido = 'Test',
        @fecha_nacimiento = '2000-01-01',
        @id_club = @id_club_test,
        @posicion_habitual = 'Delantero';
    INSERT INTO @Reporte VALUES ('sp_ModificarJugador', 'Actualización de datos personales de jugador', 'Caso de Éxito', 'OK', 'Modificado correctamente');

    -- 7.D. Baja exitosa
    EXEC administracion.sp_EliminarJugador @id = @id_jug_test;
    INSERT INTO @Reporte VALUES ('sp_EliminarJugador', 'Baja física de jugador sin historial', 'Caso de Éxito', 'OK', 'Eliminado correctamente');

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Jugador', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 8. PRUEBAS: Convocatorias, Dorsales FIFA (1 al 26), Baja Médica y Reemplazo Atómico
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_conv INT, @id_sel_conv INT, @id_club_conv INT;
    DECLARE @id_arq INT, @id_del INT, @id_reemplazo INT;
    DECLARE @id_conv INT, @id_conv_reemplazo INT;

    EXEC administracion.sp_InsertarPais @nombre = 'País Convocatoria', @id_generado = @id_pais_conv OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_conv, @confederacion = 'CONMEBOL', @grupo_asignado = 'K', @id_generado = @id_sel_conv OUTPUT;
    EXEC administracion.sp_InsertarClub @nombre = 'Club Convocatoria', @id_generado = @id_club_conv OUTPUT;

    -- Crear 1 arquero y 2 jugadores de campo
    EXEC administracion.sp_InsertarJugador @nombre = 'Emiliano', @apellido = 'Arquero', @fecha_nacimiento = '1992-09-02', @id_club = @id_club_conv, @posicion_habitual = 'Arquero', @id_generado = @id_arq OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Nico', @apellido = 'Lesionado', @fecha_nacimiento = '1998-04-06', @id_club = @id_club_conv, @posicion_habitual = 'Delantero', @id_generado = @id_del OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Ángel', @apellido = 'Sustituto', @fecha_nacimiento = '1995-03-09', @id_club = @id_club_conv, @posicion_habitual = 'Delantero', @id_generado = @id_reemplazo OUTPUT;

    -- 8.A. Convocatoria exitosa arquero con dorsal 1
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_arq, @id_seleccion = @id_sel_conv, @dorsal = 1, @id_generado = @id_conv OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Inscripción de Arquero con dorsal 1', 'Caso de Éxito', 'OK', 'Dorsal 1 asignado');

    -- 8.B. Error FIFA: Camiseta 1 asignada a jugador que NO es arquero
    BEGIN TRY
        EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_del, @id_seleccion = @id_sel_conv, @dorsal = 1, @id_generado = @id_conv OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo: Camiseta 1 solo para arquero', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50078');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo: Camiseta 1 solo para arquero', 'Validación THROW', 'OK', 'Capturado 50078');
    END CATCH;

    -- 8.C. Error FIFA: Dorsal fuera del rango 1 a 26 (ej: dorsal 30)
    BEGIN TRY
        EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_del, @id_seleccion = @id_sel_conv, @dorsal = 30, @id_generado = @id_conv OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo: Dorsal fuera del rango 1-26', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50072');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo: Dorsal fuera del rango 1-26', 'Validación THROW', 'OK', 'Capturado 50072');
    END CATCH;

    -- Convocamos a Nico con camiseta 15
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_del, @id_seleccion = @id_sel_conv, @dorsal = 15, @id_generado = @id_conv OUTPUT;

    -- 8.D. Error: Dorsal repetido entre activos
    BEGIN TRY
        EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_reemplazo, @id_seleccion = @id_sel_conv, @dorsal = 15, @id_generado = @id_conv OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo por dorsal 15 ya ocupado', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50074');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo por dorsal 15 ya ocupado', 'Validación THROW', 'OK', 'Capturado 50074');
    END CATCH;

    -- 8.E. Baja médica individual (sp_RegistrarBajaConvocatoria)
    EXEC administracion.sp_RegistrarBajaConvocatoria
        @id_jugador = @id_arq,
        @motivo = 'Decisión médica preventiva',
        @fecha = '2026-06-01';
    INSERT INTO @Reporte VALUES ('sp_RegistrarBajaConvocatoria', 'Baja lógica por motivo médico asentada', 'Caso de Éxito', 'OK', 'Estado pasado a inactivo (0)');

    -- 8.F. Reemplazo Atómico por Lesión (Heredando automáticamente la camiseta 15)
    EXEC administracion.sp_ReemplazarConvocadoUltimoMomento
        @id_jugador_lesionado = @id_del,
        @id_jugador_reemplazo = @id_reemplazo,
        @motivo_lesion = 'Desgarro muscular en entrenamiento previo',
        @dorsal_nuevo = NULL, -- Hereda la 15
        @id_convocatoria_nueva = @id_conv_reemplazo OUTPUT;

    INSERT INTO @Reporte VALUES ('sp_ReemplazarConvocadoUltimoMomento', 'Baja por lesión y alta con herencia dorsal 15', 'Caso de Éxito', 'OK', 'Reemplazado en transacción atómica');

    -- 8.G. Error FIFA: Bloqueo por superar cupo de 26 jugadores activos (Intento Jugador 27)
    DECLARE @id_sel_cupo INT, @id_pais_cupo INT;
    EXEC administracion.sp_InsertarPais @nombre = 'País Cupo 26', @id_generado = @id_pais_cupo OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_cupo, @confederacion = 'UEFA', @grupo_asignado = 'L', @id_generado = @id_sel_cupo OUTPUT;

    DECLARE @idx INT = 1, @id_j_loop INT, @id_conv_loop INT;
    WHILE @idx <= 26
    BEGIN
        DECLARE @pos_loop VARCHAR(30) = CASE WHEN @idx = 1 THEN 'Arquero' ELSE 'Mediocampista' END;
        EXEC administracion.sp_InsertarJugador @nombre = 'Player', @apellido = 'Cupo', @fecha_nacimiento = '2000-01-01', @id_club = @id_club_conv, @posicion_habitual = @pos_loop, @id_generado = @id_j_loop OUTPUT;
        EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_j_loop, @id_seleccion = @id_sel_cupo, @dorsal = @idx, @id_generado = @id_conv_loop OUTPUT;
        SET @idx = @idx + 1;
    END;

    -- Intento de jugador 27, debe lanzar error
    BEGIN TRY
        DECLARE @id_j_27 INT, @id_conv_27 INT;
        EXEC administracion.sp_InsertarJugador @nombre = 'Player', @apellido = 'Excedente27', @fecha_nacimiento = '2000-01-01', @id_club = @id_club_conv, @posicion_habitual = 'Delantero', @id_generado = @id_j_27 OUTPUT;
        EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_j_27, @id_seleccion = @id_sel_cupo, @dorsal = 10, @id_generado = @id_conv_27 OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo por cupo mayor a 26 activos (Jugador 27)', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50075');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo por cupo mayor a 26 activos (Jugador 27)', 'Validación THROW', 'OK', 'Capturado 50075: ' + ERROR_MESSAGE());
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Convocatoria', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- REPORTE CONSOLIDADO VISUAL (RESULTADOS EN SSMS)
-- =========================================================================================
PRINT '======================================================================';
PRINT 'LOTE DE PRUEBAS FINALIZADO. REVISAR PESTAÑA "RESULTADOS"';
PRINT '======================================================================';

SELECT 
    ID AS [#],
    Procedimiento AS [SP Evaluado],
    Escenario AS [Escenario de Prueba],
    Tipo_Prueba AS [Tipo],
    Resultado AS [Estado],
    Detalle AS [Detalle / Mensaje]
FROM @Reporte
ORDER BY ID;
GO
