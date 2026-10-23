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
     
   Script: test_05_partidos_y_cambios.sql
   Descripción: Lote de pruebas unitarias exhaustivas para los Stored Procedures de 05_sp_partidos_y_cambios.sql.
                Valida:
                - Creación de partidos con cálculo UTC y espacios publicitarios.
                - Registro de resultado final y control de aforo / asistencia de público.
                - Gestión de esquemas tácticos (4-3-3, 4-4-2, etc.).
                - Gestión de alineaciones (límite estricto de 11 titulares y banco de suplentes).
                - Gestión de sustituciones (5 cambios y 3 ventanas en tiempo regular; 6 cambios y 4 ventanas en tiempo suplementario).
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

-- Tabla en memoria para consolidar el reporte visual final
DECLARE @Reporte TABLE (
    ID INT IDENTITY(1,1),
    Procedimiento VARCHAR(50),
    Escenario VARCHAR(65),
    Tipo_Prueba VARCHAR(25),
    Resultado VARCHAR(10),
    Detalle VARCHAR(255)
);

PRINT '======================================================================';
PRINT 'INICIANDO LOTE DE PRUEBAS 1:1 - MÓDULO PARTIDOS Y CAMBIOS (05)';
PRINT '======================================================================';

-- =========================================================================================
-- 1. BLOQUE DE PRUEBAS: PARTIDOS, ASISTENCIA Y FIXTURE (sp_CrearPartido, sp_RegistrarResultadoYAsistencia, sp_ConsultarFixture)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_p1 INT, @id_p2 INT, @id_p3 INT, @id_p4 INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Test Part 1', @pbi_percapita = 25000, @huso_horario = '-06:00', @id_generado = @id_p1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Test Part 2', @pbi_percapita = 28000, @huso_horario = '-03:00', @id_generado = @id_p2 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Test Part 3', @pbi_percapita = 22000, @huso_horario = '+01:00', @id_generado = @id_p3 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Test Part 4', @pbi_percapita = 35000, @huso_horario = '+02:00', @id_generado = @id_p4 OUTPUT;

    DECLARE @id_sede1 INT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Azteca Test', @ciudad = 'Ciudad de México', @capacidad = 85000, @huso_horario = '-06:00', @id_pais = @id_p1, @id_generado = @id_sede1 OUTPUT;

    DECLARE @id_fase1 INT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Grupos Test 05', @orden = 90, @id_generado = @id_fase1 OUTPUT;

    DECLARE @id_s1 INT, @id_s2 INT, @id_s3 INT, @id_s4 INT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p1, @confederacion = 'CONCACAF', @grupo_asignado = 'A', @id_generado = @id_s1 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p2, @confederacion = 'CONMEBOL', @grupo_asignado = 'B', @id_generado = @id_s2 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p3, @confederacion = 'UEFA', @grupo_asignado = 'C', @id_generado = @id_s3 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p4, @confederacion = 'CAF', @grupo_asignado = 'D', @id_generado = @id_s4 OUTPUT;

    -- 1.A. Creación de partido exitoso
    EXEC partido.sp_CrearPartido 
        @id_sede = @id_sede1,
        @id_fase = @id_fase1,
        @fecha_hora_local = '2026-06-20 18:00:00',
        @id_local = @id_s1,
        @id_visitante = @id_s2;

    DECLARE @id_partido_creado INT;
    SELECT TOP 1 @id_partido_creado = ID FROM partido.Partido WHERE ID_Sede = @id_sede1 AND fecha_hora_local = '2026-06-20 18:00:00' ORDER BY ID DESC;

    DECLARE @utc_calculada DATETIME;
    SELECT @utc_calculada = fecha_hora_utc FROM partido.Partido WHERE ID = @id_partido_creado;

    DECLARE @cant_espacios INT;
    SELECT @cant_espacios = COUNT(*) FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_partido_creado;

    IF @id_partido_creado IS NOT NULL AND @cant_espacios = 4 AND @utc_calculada = '2026-06-21 00:00:00'
        INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Creación exitosa con cálculo UTC y espacios', 'Caso de Éxito', 'OK', 'Generó ID: ' + CAST(@id_partido_creado AS VARCHAR) + ' y 4 paneles publicitarios.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Creación exitosa con cálculo UTC y espacios', 'Caso de Éxito', 'FALLÓ', 'Discrepancia en UTC o paneles.');

    -- 1.B. Error 50001: Selección inexistente
    BEGIN TRY
        EXEC partido.sp_CrearPartido @id_sede1, @id_fase1, '2026-06-21 15:00:00', 999999, @id_s2;
        INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo selección inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50001');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50001
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo selección inexistente', 'Validación THROW', 'OK', 'Capturado 50001: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo selección inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.C. Error 50002: Misma selección local y visitante
    BEGIN TRY
        EXEC partido.sp_CrearPartido @id_sede1, @id_fase1, '2026-06-21 15:00:00', @id_s1, @id_s1;
        INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo selecciones idénticas', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50002');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50002
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo selecciones idénticas', 'Validación THROW', 'OK', 'Capturado 50002: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo selecciones idénticas', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.D. Error 50003: Sede inexistente
    BEGIN TRY
        EXEC partido.sp_CrearPartido 999999, @id_fase1, '2026-06-21 15:00:00', @id_s1, @id_s2;
        INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo sede inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50003');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50003
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo sede inexistente', 'Validación THROW', 'OK', 'Capturado 50003: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo sede inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.E. Error 50004: Fase inexistente
    BEGIN TRY
        EXEC partido.sp_CrearPartido @id_sede1, 999999, '2026-06-21 15:00:00', @id_s1, @id_s2;
        INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo fase inválida', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50004');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50004
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo fase inválida', 'Validación THROW', 'OK', 'Capturado 50004: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo fase inválida', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.F. Error 50005: Partido duplicado en la misma fase
    BEGIN TRY
        EXEC partido.sp_CrearPartido @id_sede1, @id_fase1, '2026-06-25 20:00:00', @id_s1, @id_s2;
        INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo partido duplicado en fase', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50005');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50005
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo partido duplicado en fase', 'Validación THROW', 'OK', 'Capturado 50005: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo partido duplicado en fase', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.G. Error 50006: Solapamiento de sede y horario
    BEGIN TRY
        EXEC partido.sp_CrearPartido @id_sede1, @id_fase1, '2026-06-20 18:00:00', @id_s3, @id_s4;
        INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo solapamiento en sede/hora', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50006');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50006
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo solapamiento en sede/hora', 'Validación THROW', 'OK', 'Capturado 50006: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Bloqueo solapamiento en sede/hora', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.H. Registro exitoso de resultado y asistencia
    EXEC partido.sp_RegistrarResultadoYAsistencia 
        @id_partido = @id_partido_creado, 
        @goles_local = 2, 
        @goles_visitante = 1, 
        @asistencia_publico = 80000;

    IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_partido_creado AND goles_local = 2 AND goles_visitante = 1 AND asistencia_publico = 80000)
        INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Registro exitoso de resultado y público', 'Caso de Éxito', 'OK', 'Marcador 2-1 y asistencia 80.000 registrados.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Registro exitoso de resultado y público', 'Caso de Éxito', 'FALLÓ', 'No se actualizaron los campos en Partido.');

    -- 1.I. Error 50043: Asistencia supera la capacidad del estadio (capacidad Azteca: 85.000)
    BEGIN TRY
        EXEC partido.sp_RegistrarResultadoYAsistencia 
            @id_partido = @id_partido_creado, 
            @goles_local = 2, 
            @goles_visitante = 1, 
            @asistencia_publico = 95000; -- Supera los 85.000
        INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo público superior a capacidad', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50043');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50043
            INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo público superior a capacidad', 'Validación THROW', 'OK', 'Capturado 50043: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo público superior a capacidad', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.J. Error 50040: Bloqueo partido inexistente al registrar resultado
    BEGIN TRY
        EXEC partido.sp_RegistrarResultadoYAsistencia 
            @id_partido = 999999, 
            @goles_local = 1, 
            @goles_visitante = 0, 
            @asistencia_publico = 50000;
        INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo partido inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50040');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50040
            INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo partido inexistente', 'Validación THROW', 'OK', 'Capturado 50040: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo partido inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.K. Error: Bloqueo goles negativos (impedido nativamente por tipo TINYINT o por THROW 50041)
    BEGIN TRY
        EXEC partido.sp_RegistrarResultadoYAsistencia 
            @id_partido = @id_partido_creado, 
            @goles_local = -1, 
            @goles_visitante = 2, 
            @asistencia_publico = 50000;
        INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo goles negativos', 'Validación Tipo/THROW', 'FALLÓ', 'Debió bloquear el valor negativo');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (50041, 8114)
            INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo goles negativos', 'Validación Tipo/THROW', 'OK', 'Bloqueado correctamente: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo goles negativos', 'Validación Tipo/THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.L. Error 50042: Bloqueo asistencia negativa al registrar resultado
    BEGIN TRY
        EXEC partido.sp_RegistrarResultadoYAsistencia 
            @id_partido = @id_partido_creado, 
            @goles_local = 2, 
            @goles_visitante = 1, 
            @asistencia_publico = -500;
        INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo asistencia negativa', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50042');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50042
            INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo asistencia negativa', 'Validación THROW', 'OK', 'Capturado 50042: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarResultadoYAsistencia', 'Bloqueo asistencia negativa', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('sp_CrearPartido', 'Excepción crítica en Bloque 1', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

-- =========================================================================================
-- 2. BLOQUE DE PRUEBAS: FORMACIONES TÁCTICAS (sp_RegistrarFormacion y sp_EliminarFormacion)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_p_f1 INT, @id_p_f2 INT, @id_p_f3 INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Form 1', @id_generado = @id_p_f1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Form 2', @id_generado = @id_p_f2 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Form 3', @id_generado = @id_p_f3 OUTPUT;

    DECLARE @id_sede_f INT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Formaciones', @ciudad = 'Monterrey', @capacidad = 53000, @huso_horario = '-06:00', @id_pais = @id_p_f1, @id_generado = @id_sede_f OUTPUT;

    DECLARE @id_fase_f INT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Formaciones', @orden = 91, @id_generado = @id_fase_f OUTPUT;

    DECLARE @id_sf1 INT, @id_sf2 INT, @id_sf3 INT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p_f1, @confederacion = 'CONMEBOL', @grupo_asignado = 'E', @id_generado = @id_sf1 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p_f2, @confederacion = 'UEFA', @grupo_asignado = 'F', @id_generado = @id_sf2 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p_f3, @confederacion = 'CAF', @grupo_asignado = 'G', @id_generado = @id_sf3 OUTPUT;

    EXEC partido.sp_CrearPartido @id_sede = @id_sede_f, @id_fase = @id_fase_f, @fecha_hora_local = '2026-06-22 17:00:00', @id_local = @id_sf1, @id_visitante = @id_sf2;
    DECLARE @id_partido_f INT;
    SELECT TOP 1 @id_partido_f = ID FROM partido.Partido WHERE ID_Sede = @id_sede_f ORDER BY ID DESC;

    -- 2.A. Alta de formación exitosa
    EXEC partido.sp_RegistrarFormacion @id_partido = @id_partido_f, @id_seleccion = @id_sf1, @esquema_tactico = '4-3-3';
    IF EXISTS (SELECT 1 FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido_f AND ID_Seleccion = @id_sf1 AND esquema_tactico = '4-3-3')
        INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Alta exitosa de formación 4-3-3', 'Caso de Éxito', 'OK', 'Formación guardada correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Alta exitosa de formación 4-3-3', 'Caso de Éxito', 'FALLÓ', 'No se encontró la formación creada.');

    -- 2.B. Modificación de formación exitosa (Update)
    EXEC partido.sp_RegistrarFormacion @id_partido = @id_partido_f, @id_seleccion = @id_sf1, @esquema_tactico = '4-4-2';
    IF EXISTS (SELECT 1 FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido_f AND ID_Seleccion = @id_sf1 AND esquema_tactico = '4-4-2')
        INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Modificación de esquema táctico (4-4-2)', 'Caso de Éxito', 'OK', 'Actualizado a 4-4-2 correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Modificación de esquema táctico (4-4-2)', 'Caso de Éxito', 'FALLÓ', 'No se actualizó el esquema.');

    -- 2.C. Error 50010: Partido inexistente
    BEGIN TRY
        EXEC partido.sp_RegistrarFormacion 999999, @id_sf1, '4-4-2';
        INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Bloqueo partido inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50010');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50010
            INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Bloqueo partido inexistente', 'Validación THROW', 'OK', 'Capturado 50010: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Bloqueo partido inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.D. Error 50011: Selección no participa del partido
    BEGIN TRY
        EXEC partido.sp_RegistrarFormacion @id_partido_f, @id_sf3, '4-4-2';
        INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Bloqueo selección ajena al partido', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50011');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50011
            INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Bloqueo selección ajena al partido', 'Validación THROW', 'OK', 'Capturado 50011: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Bloqueo selección ajena al partido', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.E. Error 50012: Esquema táctico no permitido
    BEGIN TRY
        EXEC partido.sp_RegistrarFormacion @id_partido_f, @id_sf1, '1-2-7';
        INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Bloqueo esquema táctico no válido', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50012');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50012
            INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Bloqueo esquema táctico no válido', 'Validación THROW', 'OK', 'Capturado 50012: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Bloqueo esquema táctico no válido', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.F. Baja de formación exitosa
    EXEC partido.sp_EliminarFormacion @id_partido = @id_partido_f, @id_seleccion = @id_sf1;
    IF NOT EXISTS (SELECT 1 FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido_f AND ID_Seleccion = @id_sf1)
        INSERT INTO @Reporte VALUES ('sp_EliminarFormacion', 'Baja exitosa de formación', 'Caso de Éxito', 'OK', 'Formación eliminada correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarFormacion', 'Baja exitosa de formación', 'Caso de Éxito', 'FALLÓ', 'La formación sigue existiendo.');

    -- 2.G. Error 50013: Baja de formación inexistente
    BEGIN TRY
        EXEC partido.sp_EliminarFormacion @id_partido_f, @id_sf1;
        INSERT INTO @Reporte VALUES ('sp_EliminarFormacion', 'Bloqueo baja formación inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50013');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50013
            INSERT INTO @Reporte VALUES ('sp_EliminarFormacion', 'Bloqueo baja formación inexistente', 'Validación THROW', 'OK', 'Capturado 50013: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarFormacion', 'Bloqueo baja formación inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('sp_RegistrarFormacion', 'Excepción crítica en Bloque 2', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

-- =========================================================================================
-- 3. BLOQUE DE PRUEBAS: ALINEACIONES (sp_RegistrarAlineacion y sp_EliminarAlineacion)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_p_al1 INT, @id_p_al2 INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Alineacion 1', @id_generado = @id_p_al1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Alineacion 2', @id_generado = @id_p_al2 OUTPUT;

    DECLARE @id_sede_al INT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Alineaciones', @ciudad = 'Guadalajara', @capacidad = 48000, @huso_horario = '-06:00', @id_pais = @id_p_al1, @id_generado = @id_sede_al OUTPUT;

    DECLARE @id_fase_al INT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Alineaciones', @orden = 92, @id_generado = @id_fase_al OUTPUT;

    DECLARE @id_club_al INT;
    EXEC administracion.sp_InsertarClub @nombre = 'Club Alineaciones Test', @id_generado = @id_club_al OUTPUT;

    DECLARE @id_sal1 INT, @id_sal2 INT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p_al1, @confederacion = 'CONMEBOL', @grupo_asignado = 'H', @id_generado = @id_sal1 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p_al2, @confederacion = 'UEFA', @grupo_asignado = 'I', @id_generado = @id_sal2 OUTPUT;

    EXEC partido.sp_CrearPartido @id_sede = @id_sede_al, @id_fase = @id_fase_al, @fecha_hora_local = '2026-06-23 20:00:00', @id_local = @id_sal1, @id_visitante = @id_sal2;
    DECLARE @id_partido_al INT;
    SELECT TOP 1 @id_partido_al = ID FROM partido.Partido WHERE ID_Sede = @id_sede_al ORDER BY ID DESC;

    EXEC partido.sp_RegistrarFormacion @id_partido = @id_partido_al, @id_seleccion = @id_sal1, @esquema_tactico = '4-3-3';
    DECLARE @id_formacion_al INT;
    SELECT TOP 1 @id_formacion_al = ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido_al AND ID_Seleccion = @id_sal1;

    -- Convocamos 12 jugadores en Selección 1 (1 arquero + 11 delanteros)
    DECLARE @j_al TABLE (idx INT IDENTITY(1,1), id_jug INT);
    DECLARE @idx_al INT = 1;
    DECLARE @id_jtemp INT, @id_ctemp INT;
    WHILE @idx_al <= 12
    BEGIN
        DECLARE @pos_al VARCHAR(30) = CASE WHEN @idx_al = 1 THEN 'ARQUERO' ELSE 'DELANTERO' END;
        EXEC administracion.sp_InsertarJugador @nombre = 'Jug_Al', @apellido = 'Test', @fecha_nacimiento = '1998-03-15', @id_club = @id_club_al, @posicion_habitual = @pos_al, @id_generado = @id_jtemp OUTPUT;
        INSERT INTO @j_al VALUES (@id_jtemp);
        EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_jtemp, @id_seleccion = @id_sal1, @dorsal = @idx_al, @id_generado = @id_ctemp OUTPUT;
        SET @idx_al = @idx_al + 1;
    END;

    -- Convocamos 1 jugador en Selección 2 (ajeno)
    DECLARE @id_j_ajeno INT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Jug_Ajeno', @apellido = 'Test', @fecha_nacimiento = '1999-07-20', @id_club = @id_club_al, @posicion_habitual = 'MEDIOCAMPISTA', @id_generado = @id_j_ajeno OUTPUT;
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_j_ajeno, @id_seleccion = @id_sal2, @dorsal = 10, @id_generado = @id_ctemp OUTPUT;

    -- Helpers de IDs
    DECLARE @jal1 INT, @jal2 INT, @jal3 INT, @jal4 INT, @jal5 INT, @jal6 INT, @jal7 INT, @jal8 INT, @jal9 INT, @jal10 INT, @jal11 INT, @jal12 INT;
    SELECT @jal1 = id_jug FROM @j_al WHERE idx = 1;
    SELECT @jal2 = id_jug FROM @j_al WHERE idx = 2;
    SELECT @jal3 = id_jug FROM @j_al WHERE idx = 3;
    SELECT @jal4 = id_jug FROM @j_al WHERE idx = 4;
    SELECT @jal5 = id_jug FROM @j_al WHERE idx = 5;
    SELECT @jal6 = id_jug FROM @j_al WHERE idx = 6;
    SELECT @jal7 = id_jug FROM @j_al WHERE idx = 7;
    SELECT @jal8 = id_jug FROM @j_al WHERE idx = 8;
    SELECT @jal9 = id_jug FROM @j_al WHERE idx = 9;
    SELECT @jal10 = id_jug FROM @j_al WHERE idx = 10;
    SELECT @jal11 = id_jug FROM @j_al WHERE idx = 11;
    SELECT @jal12 = id_jug FROM @j_al WHERE idx = 12;

    -- 3.A. Registro exitoso de los 11 titulares
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal1, 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal2, 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal3, 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal4, 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal5, 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal6, 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal7, 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal8, 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal9, 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal10, 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal11, 1;

    DECLARE @titulares_cont INT;
    SELECT @titulares_cont = COUNT(*) FROM partido.Alineacion WHERE ID_Formacion = @id_formacion_al AND es_titular = 1;
    IF @titulares_cont = 11
        INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Alta exitosa de 11 titulares', 'Caso de Éxito', 'OK', '11 titulares reglamentarios cargados.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Alta exitosa de 11 titulares', 'Caso de Éxito', 'FALLÓ', 'Cantidad cargada: ' + CAST(@titulares_cont AS VARCHAR));

    -- 3.B. Registro exitoso de suplente
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal12, 0;
    IF EXISTS (SELECT 1 FROM partido.Alineacion WHERE ID_Formacion = @id_formacion_al AND ID_Jugador = @jal12 AND es_titular = 0)
        INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Alta exitosa de suplente en el banco', 'Caso de Éxito', 'OK', 'Suplente registrado.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Alta exitosa de suplente en el banco', 'Caso de Éxito', 'FALLÓ', 'No figura en suplentes.');

    -- 3.C. Modificación exitosa (Update de suplente)
    EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal12, 0;
    INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Modificación de alineación (Update)', 'Caso de Éxito', 'OK', 'Registro actualizado sin error.');

    -- 3.D. Error 50020: Formación inexistente
    BEGIN TRY
        EXEC partido.sp_RegistrarAlineacion 999999, @jal1, 1;
        INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo formación inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50020');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50020
            INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo formación inexistente', 'Validación THROW', 'OK', 'Capturado 50020: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo formación inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.E. Error 50021: Jugador inexistente
    BEGIN TRY
        EXEC partido.sp_RegistrarAlineacion @id_formacion_al, 999999, 1;
        INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo jugador inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50021');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50021
            INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo jugador inexistente', 'Validación THROW', 'OK', 'Capturado 50021: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo jugador inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.F. Error 50022: Jugador no convocado en la selección
    BEGIN TRY
        EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @id_j_ajeno, 1;
        INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo jugador de otra selección', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50022');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50022
            INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo jugador de otra selección', 'Validación THROW', 'OK', 'Capturado 50022: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo jugador de otra selección', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.G. Error 50024: Bloqueo de titular número 12 (supera límite de 11)
    BEGIN TRY
        EXEC partido.sp_RegistrarAlineacion @id_formacion_al, @jal12, 1; -- Intentar pasar al suplente a titular habiendo ya 11
        INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo titular 12 (límite 11 titulares)', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50024');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50024
            INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo titular 12 (límite 11 titulares)', 'Validación THROW', 'OK', 'Capturado 50024: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo titular 12 (límite 11 titulares)', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.H. Baja de jugador en alineación exitosa
    EXEC partido.sp_EliminarAlineacion @id_formacion = @id_formacion_al, @id_jugador = @jal12;
    IF NOT EXISTS (SELECT 1 FROM partido.Alineacion WHERE ID_Formacion = @id_formacion_al AND ID_Jugador = @jal12)
        INSERT INTO @Reporte VALUES ('sp_EliminarAlineacion', 'Baja exitosa de jugador en alineación', 'Caso de Éxito', 'OK', 'Jugador retirado de la alineación.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarAlineacion', 'Baja exitosa de jugador en alineación', 'Caso de Éxito', 'FALLÓ', 'El jugador aún figura alineado.');

    -- 3.I. Error 50025: Baja de jugador no alineado
    BEGIN TRY
        EXEC partido.sp_EliminarAlineacion @id_formacion_al, @jal12;
        INSERT INTO @Reporte VALUES ('sp_EliminarAlineacion', 'Bloqueo baja jugador no alineado', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50025');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50025
            INSERT INTO @Reporte VALUES ('sp_EliminarAlineacion', 'Bloqueo baja jugador no alineado', 'Validación THROW', 'OK', 'Capturado 50025: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarAlineacion', 'Bloqueo baja jugador no alineado', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Excepción crítica en Bloque 3', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

-- ==============================================
-- 4. BLOQUE DE PRUEBAS: SUSTITUCIONES, PRÓRROGA
-- ==============================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_p_su1 INT, @id_p_su2 INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Sustitucion 1', @id_generado = @id_p_su1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Sustitucion 2', @id_generado = @id_p_su2 OUTPUT;

    DECLARE @id_sede_su INT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Sustituciones', @ciudad = 'Dallas', @capacidad = 80000, @huso_horario = '-05:00', @id_pais = @id_p_su1, @id_generado = @id_sede_su OUTPUT;

    DECLARE @id_fase_su INT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Sustituciones', @orden = 93, @id_generado = @id_fase_su OUTPUT;

    DECLARE @id_club_su INT;
    EXEC administracion.sp_InsertarClub @nombre = 'Club Sustituciones Test', @id_generado = @id_club_su OUTPUT;

    DECLARE @id_ssu1 INT, @id_ssu2 INT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p_su1, @confederacion = 'CONMEBOL', @grupo_asignado = 'J', @id_generado = @id_ssu1 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_p_su2, @confederacion = 'UEFA', @grupo_asignado = 'K', @id_generado = @id_ssu2 OUTPUT;

    EXEC partido.sp_CrearPartido @id_sede = @id_sede_su, @id_fase = @id_fase_su, @fecha_hora_local = '2026-06-24 16:00:00', @id_local = @id_ssu1, @id_visitante = @id_ssu2;
    DECLARE @id_partido_su INT;
    SELECT TOP 1 @id_partido_su = ID FROM partido.Partido WHERE ID_Sede = @id_sede_su ORDER BY ID DESC;

    EXEC partido.sp_RegistrarFormacion @id_partido = @id_partido_su, @id_seleccion = @id_ssu1, @esquema_tactico = '4-3-3';
    DECLARE @id_formacion_su INT;
    SELECT TOP 1 @id_formacion_su = ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido_su AND ID_Seleccion = @id_ssu1;

    -- Convocamos 18 jugadores en Selección 1 (1 arquero + 17 delanteros)
    DECLARE @j_su TABLE (idx INT IDENTITY(1,1), id_jug INT);
    DECLARE @idx_su INT = 1;
    DECLARE @id_jsutemp INT, @id_csutemp INT;
    WHILE @idx_su <= 18
    BEGIN
        DECLARE @pos_su VARCHAR(30) = CASE WHEN @idx_su = 1 THEN 'ARQUERO' ELSE 'DELANTERO' END;
        EXEC administracion.sp_InsertarJugador @nombre = 'Jug_Su', @apellido = 'Test', @fecha_nacimiento = '1998-05-12', @id_club = @id_club_su, @posicion_habitual = @pos_su, @id_generado = @id_jsutemp OUTPUT;
        INSERT INTO @j_su VALUES (@id_jsutemp);
        EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_jsutemp, @id_seleccion = @id_ssu1, @dorsal = @idx_su, @id_generado = @id_csutemp OUTPUT;
        SET @idx_su = @idx_su + 1;
    END;

    -- Jugador de Selección 2 (ajeno)
    DECLARE @id_j_ajeno_su INT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Jug_Ajeno_Su', @apellido = 'Test', @fecha_nacimiento = '1999-01-01', @id_club = @id_club_su, @posicion_habitual = 'MEDIOCAMPISTA', @id_generado = @id_j_ajeno_su OUTPUT;
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_j_ajeno_su, @id_seleccion = @id_ssu2, @dorsal = 10, @id_generado = @id_csutemp OUTPUT;

    -- Helpers de jugadores
    DECLARE @js1 INT, @js2 INT, @js3 INT, @js4 INT, @js5 INT, @js6 INT, @js7 INT;
    DECLARE @js12 INT, @js13 INT, @js14 INT, @js15 INT, @js16 INT, @js17 INT, @js18 INT;
    SELECT @js1 = id_jug FROM @j_su WHERE idx = 1;
    SELECT @js2 = id_jug FROM @j_su WHERE idx = 2;
    SELECT @js3 = id_jug FROM @j_su WHERE idx = 3;
    SELECT @js4 = id_jug FROM @j_su WHERE idx = 4;
    SELECT @js5 = id_jug FROM @j_su WHERE idx = 5;
    SELECT @js6 = id_jug FROM @j_su WHERE idx = 6;
    SELECT @js7 = id_jug FROM @j_su WHERE idx = 7;
    SELECT @js12 = id_jug FROM @j_su WHERE idx = 12;
    SELECT @js13 = id_jug FROM @j_su WHERE idx = 13;
    SELECT @js14 = id_jug FROM @j_su WHERE idx = 14;
    SELECT @js15 = id_jug FROM @j_su WHERE idx = 15;
    SELECT @js16 = id_jug FROM @j_su WHERE idx = 16;
    SELECT @js17 = id_jug FROM @j_su WHERE idx = 17;
    SELECT @js18 = id_jug FROM @j_su WHERE idx = 18;

    -- Titulares 1..11
    DECLARE @t_idx INT = 1;
    WHILE @t_idx <= 11
    BEGIN
        DECLARE @j_tit INT;
        SELECT @j_tit = id_jug FROM @j_su WHERE idx = @t_idx;
        EXEC partido.sp_RegistrarAlineacion @id_formacion_su, @j_tit, 1;
        SET @t_idx = @t_idx + 1;
    END;

    -- Suplentes 12..18
    DECLARE @s_idx INT = 12;
    WHILE @s_idx <= 18
    BEGIN
        DECLARE @j_sup INT;
        SELECT @j_sup = id_jug FROM @j_su WHERE idx = @s_idx;
        EXEC partido.sp_RegistrarAlineacion @id_formacion_su, @j_sup, 0;
        SET @s_idx = @s_idx + 1;
    END;

    -- 4.A. Sustitución exitosa en juego (Minuto 60 - Abre Ventana 1)
    EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js1, @js12, 60, 'Táctico';
    IF EXISTS (SELECT 1 FROM partido.Sustitucion WHERE ID_Partido = @id_partido_su AND ID_Jugador_Sale = @js1 AND ID_Jugador_Entra = @js12)
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Sustitución en juego (Ventana 1, min 60)', 'Caso de Éxito', 'OK', 'Cambio 1 registrado correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Sustitución en juego (Ventana 1, min 60)', 'Caso de Éxito', 'FALLÓ', 'No se insertó la sustitución.');

    -- 4.B. Sustitución exitosa en entretiempo (Minuto 45 - No consume ventana FIFA)
    EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js2, @js13, 45, 'Lesión';
    IF EXISTS (SELECT 1 FROM partido.Sustitucion WHERE ID_Partido = @id_partido_su AND ID_Jugador_Sale = @js2 AND ID_Jugador_Entra = @js13)
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Sustitución en entretiempo (minuto 45)', 'Caso de Éxito', 'OK', 'Cambio 2 registrado sin consumir ventana.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Sustitución en entretiempo (minuto 45)', 'Caso de Éxito', 'FALLÓ', 'No se insertó la sustitución.');

    -- 4.C. Error 50030: Partido inexistente
    BEGIN TRY
        EXEC partido.sp_RegistrarSustitucion 999999, @js3, @js14, 70, 'Táctico';
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo partido inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50030');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50030
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo partido inexistente', 'Validación THROW', 'OK', 'Capturado 50030: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo partido inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.D. Error 50031: Mismo jugador sale y entra
    BEGIN TRY
        EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js3, @js3, 70, 'Táctico';
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo mismo jugador saliente y entrante', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50031');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50031
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo mismo jugador saliente y entrante', 'Validación THROW', 'OK', 'Capturado 50031: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo mismo jugador saliente y entrante', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.E. Error 50032: Jugador que sale no juega el partido
    BEGIN TRY
        EXEC partido.sp_RegistrarSustitucion @id_partido_su, 999999, @js14, 70, 'Táctico';
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo jugador saliente ajeno', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50032');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50032
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo jugador saliente ajeno', 'Validación THROW', 'OK', 'Capturado 50032: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo jugador saliente ajeno', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.F. Error 50033: Jugador que sale ya había salido antes
    BEGIN TRY
        EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js1, @js14, 70, 'Táctico'; -- @js1 ya salió en min 60
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo jugador ya sustituido previamente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50033');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50033
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo jugador ya sustituido previamente', 'Validación THROW', 'OK', 'Capturado 50033: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo jugador ya sustituido previamente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.G. Error 50034: Jugador que entra no pertenece al banco de suplentes
    BEGIN TRY
        EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js3, @id_j_ajeno_su, 70, 'Táctico';
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo entrante no suplente del equipo', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50034');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50034
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo entrante no suplente del equipo', 'Validación THROW', 'OK', 'Capturado 50034: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo entrante no suplente del equipo', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- Ejecutamos cambios para consumir ventanas 2 y 3:
    EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js3, @js14, 70, 'Táctico'; -- Ventana 2 (Cambio 3)
    EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js4, @js15, 80, 'Táctico'; -- Ventana 3 (Cambio 4)

    -- 4.H. Error 50035: Bloqueo de reingreso de jugador que ya había salido
    BEGIN TRY
        EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js5, @js2, 80, 'Táctico'; -- @js2 salió en min 45
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo reingreso de jugador salido', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50034/50035');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (50034, 50035)
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo reingreso de jugador salido', 'Validación THROW', 'OK', 'Capturado ' + CAST(ERROR_NUMBER() AS VARCHAR) + ': ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo reingreso de jugador salido', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.I. Error 50037: Bloqueo de 4ta ventana en tiempo regular (min 88)
    BEGIN TRY
        EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js5, @js16, 88, 'Táctico';
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo 4ta ventana en regular (máx 3)', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50037');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50037
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo 4ta ventana en regular (máx 3)', 'Validación THROW', 'OK', 'Capturado 50037: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo 4ta ventana en regular (máx 3)', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- Hacemos el 5to cambio en la misma Ventana 3 (Minuto 80) para agotar los 5 cambios regulares:
    EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js5, @js16, 80, 'Táctico'; -- Cambio 5 (Misma ventana 3, válido!)

    -- 4.J. Error 50036: Bloqueo de 6to cambio en tiempo regular (minuto 85)
    BEGIN TRY
        EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js6, @js17, 85, 'Táctico';
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo 6to cambio en tiempo regular', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50036');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50036
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo 6to cambio en tiempo regular', 'Validación THROW', 'OK', 'Capturado 50036: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo 6to cambio en tiempo regular', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.K. Sustitución en tiempo suplementario (6to cambio reglamentario FIFA en minuto > 90)
    EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js6, @js17, 95, 'Táctico'; -- Minuto 95 (Prórroga)
    IF EXISTS (SELECT 1 FROM partido.Sustitucion WHERE ID_Partido = @id_partido_su AND ID_Jugador_Sale = @js6 AND ID_Jugador_Entra = @js17 AND minuto = 95)
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', '6to cambio habilitado en tiempo suplementario', 'Caso de Éxito', 'OK', '6to cambio reglamentario en prórroga (min 95) permitido.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', '6to cambio habilitado en tiempo suplementario', 'Caso de Éxito', 'FALLÓ', 'No se insertó el 6to cambio en suplementario.');

    -- 4.L. Error 50036 en prórroga: Bloqueo de 7mo cambio (límite absoluto)
    BEGIN TRY
        EXEC partido.sp_RegistrarSustitucion @id_partido_su, @js7, @js18, 98, 'Táctico';
        INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo 7mo cambio en prórroga', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50036');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50036
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo 7mo cambio en prórroga', 'Validación THROW', 'OK', 'Capturado 50036: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Bloqueo 7mo cambio en prórroga', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.M. Baja de sustitución exitosa
    DECLARE @id_sustitucion_a_borrar INT;
    SELECT TOP 1 @id_sustitucion_a_borrar = ID FROM partido.Sustitucion WHERE ID_Partido = @id_partido_su AND ID_Jugador_Sale = @js6 ORDER BY ID DESC;

    EXEC partido.sp_EliminarSustitucion @id_sustitucion = @id_sustitucion_a_borrar;
    IF NOT EXISTS (SELECT 1 FROM partido.Sustitucion WHERE ID = @id_sustitucion_a_borrar)
        INSERT INTO @Reporte VALUES ('sp_EliminarSustitucion', 'Baja exitosa de sustitución', 'Caso de Éxito', 'OK', 'Sustitución anulada y eliminada correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarSustitucion', 'Baja exitosa de sustitución', 'Caso de Éxito', 'FALLÓ', 'La sustitución sigue existiendo.');

    -- 4.N. Error 50038: Baja de sustitución inexistente
    BEGIN TRY
        EXEC partido.sp_EliminarSustitucion @id_sustitucion = 999999;
        INSERT INTO @Reporte VALUES ('sp_EliminarSustitucion', 'Bloqueo baja sustitución inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50038');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50038
            INSERT INTO @Reporte VALUES ('sp_EliminarSustitucion', 'Bloqueo baja sustitución inexistente', 'Validación THROW', 'OK', 'Capturado 50038: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarSustitucion', 'Bloqueo baja sustitución inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('sp_RegistrarSustitucion', 'Excepción crítica en Bloque 4', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

-- =========================================================================================
-- REPORTE VISUAL FINAL EN GRILLA DE RESULTADOS
-- =========================================================================================
PRINT '======================================================================';
PRINT 'REPORTE CONSOLIDADO DE EJECUCIÓN (RESULTADOS EN GRILLA)';
PRINT '======================================================================';

SELECT 
    ID AS [#],
    Procedimiento,
    Escenario,
    Tipo_Prueba,
    Resultado,
    Detalle
FROM @Reporte
ORDER BY ID ASC;
