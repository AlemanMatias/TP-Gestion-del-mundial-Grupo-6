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
     
   Script: test_06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql
   Descripción: 
                - Árbitros e Idiomas 
                - Designación Arbitral
                - Goles 
                - Tarjetas, Suspensiones y Partidos Perdidos por Suspensión 
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

-- Tabla en memoria para consolidar el reporte visual final (inmune a ROLLBACK)
DECLARE @Reporte TABLE (
    ID INT IDENTITY(1,1),
    Procedimiento VARCHAR(50),
    Escenario VARCHAR(80),
    Tipo_Prueba VARCHAR(30),
    Resultado VARCHAR(10),
    Detalle VARCHAR(500)
);

PRINT '======================================================================';
PRINT 'INICIANDO LOTE DE PRUEBAS 1:1 - MÓDULO GOLES, TARJETAS Y ÁRBITROS (06)';
PRINT '======================================================================';

-- =========================================================================================
-- 1. BLOQUE DE PRUEBAS: ABM DE ÁRBITROS E IDIOMAS (sp_Insertar/Modificar/EliminarArbitro e IdiomaArbitro)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_arb1 INT, @id_pais_arb2 INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Arbitro Test 1', @pbi_percapita = 40000, @huso_horario = '+01:00', @id_generado = @id_pais_arb1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Arbitro Test 2', @pbi_percapita = 35000, @huso_horario = '+02:00', @id_generado = @id_pais_arb2 OUTPUT;

    -- 1.A. Alta exitosa de árbitro
    DECLARE @id_arb INT;
    EXEC arbitraje.sp_InsertarArbitro
        @Nombre = 'Pierluigi',
        @Apellido = 'Collina',
        @Categoria = 'FIFA Elite',
        @ID_Pais = @id_pais_arb1,
        @ID = @id_arb OUTPUT;

    IF @id_arb IS NOT NULL AND EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @id_arb AND apellido = 'Collina')
        INSERT INTO @Reporte VALUES ('sp_InsertarArbitro', 'Alta exitosa de árbitro', 'Caso de Éxito', 'OK', 'Árbitro creado con ID: ' + CAST(@id_arb AS VARCHAR));
    ELSE
        INSERT INTO @Reporte VALUES ('sp_InsertarArbitro', 'Alta exitosa de árbitro', 'Caso de Éxito', 'FALLÓ', 'No se insertó el árbitro.');

    -- 1.B. Modificación exitosa de árbitro
    EXEC arbitraje.sp_ModificarArbitro
        @ID = @id_arb,
        @Categoria = 'FIFA Master',
        @ID_Pais = @id_pais_arb2;

    IF EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @id_arb AND categoria = 'FIFA Master' AND ID_Pais = @id_pais_arb2)
        INSERT INTO @Reporte VALUES ('sp_ModificarArbitro', 'Modificación exitosa de árbitro', 'Caso de Éxito', 'OK', 'Categoría y país actualizados correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ModificarArbitro', 'Modificación exitosa de árbitro', 'Caso de Éxito', 'FALLÓ', 'No se actualizaron los datos del árbitro.');

    -- 1.C. Error 50010: Alta de árbitro con campos obligatorios nulos o vacíos
    BEGIN TRY
        DECLARE @id_arb_err INT;
        EXEC arbitraje.sp_InsertarArbitro @Nombre = 'Incompleto', @Apellido = NULL, @Categoria = NULL, @ID_Pais = @id_pais_arb1, @ID = @id_arb_err OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarArbitro', 'Bloqueo alta con campos faltantes', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50010');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50010
            INSERT INTO @Reporte VALUES ('sp_InsertarArbitro', 'Bloqueo alta con campos faltantes', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_InsertarArbitro', 'Bloqueo alta con campos faltantes', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.D. Error 50016: Alta de árbitro con país inexistente
    BEGIN TRY
        DECLARE @id_arb_err2 INT;
        EXEC arbitraje.sp_InsertarArbitro @Nombre = 'Howard', @Apellido = 'Webb', @Categoria = 'FIFA Elite', @ID_Pais = 999999, @ID = @id_arb_err2 OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarArbitro', 'Bloqueo país inexistente en árbitro', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50016');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50016
            INSERT INTO @Reporte VALUES ('sp_InsertarArbitro', 'Bloqueo país inexistente en árbitro', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_InsertarArbitro', 'Bloqueo país inexistente en árbitro', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.E. Error 50011: Modificación de árbitro inexistente
    BEGIN TRY
        EXEC arbitraje.sp_ModificarArbitro @ID = 999999, @Nombre = 'Fantasma';
        INSERT INTO @Reporte VALUES ('sp_ModificarArbitro', 'Bloqueo modificación árbitro inexistente', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50011');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50011
            INSERT INTO @Reporte VALUES ('sp_ModificarArbitro', 'Bloqueo modificación árbitro inexistente', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_ModificarArbitro', 'Bloqueo modificación árbitro inexistente', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.F. Alta exitosa de idiomas para el árbitro
    EXEC arbitraje.sp_InsertarIdiomaArbitro @ID_Arbitro = @id_arb, @Lengua = 'Italiano';
    EXEC arbitraje.sp_InsertarIdiomaArbitro @ID_Arbitro = @id_arb, @Lengua = 'Inglés';

    IF (SELECT COUNT(*) FROM arbitraje.Idioma WHERE ID_Arbitro = @id_arb) = 2
        INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Inserción exitosa de idiomas de árbitro', 'Caso de Éxito', 'OK', '2 idiomas asociados al árbitro.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Inserción exitosa de idiomas de árbitro', 'Caso de Éxito', 'FALLÓ', 'No se registraron los idiomas.');

    -- 1.G. Error 50014: Idioma duplicado en el mismo árbitro
    BEGIN TRY
        EXEC arbitraje.sp_InsertarIdiomaArbitro @ID_Arbitro = @id_arb, @Lengua = 'Italiano';
        INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Bloqueo idioma duplicado en árbitro', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50014');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50014
            INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Bloqueo idioma duplicado en árbitro', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Bloqueo idioma duplicado en árbitro', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.H. Modificación exitosa de idioma del árbitro
    EXEC arbitraje.sp_ModificarIdiomaArbitro @ID_Arbitro = @id_arb, @Lengua = 'Inglés', @NuevaLengua = 'Francés';

    IF EXISTS (SELECT 1 FROM arbitraje.Idioma WHERE ID_Arbitro = @id_arb AND lengua = 'Francés')
        INSERT INTO @Reporte VALUES ('sp_ModificarIdiomaArbitro', 'Modificación exitosa de idioma de árbitro', 'Caso de Éxito', 'OK', 'Idioma actualizado de Inglés a Francés.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ModificarIdiomaArbitro', 'Modificación exitosa de idioma de árbitro', 'Caso de Éxito', 'FALLÓ', 'No se modificó el idioma.');

    -- 1.I. Eliminación exitosa de un idioma del árbitro
    EXEC arbitraje.sp_EliminarIdiomaArbitro @ID_Arbitro = @id_arb, @Lengua = 'Francés';

    IF NOT EXISTS (SELECT 1 FROM arbitraje.Idioma WHERE ID_Arbitro = @id_arb AND lengua = 'Francés')
        INSERT INTO @Reporte VALUES ('sp_EliminarIdiomaArbitro', 'Baja exitosa de idioma de árbitro', 'Caso de Éxito', 'OK', 'Idioma Francés eliminado correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarIdiomaArbitro', 'Baja exitosa de idioma de árbitro', 'Caso de Éxito', 'FALLÓ', 'El idioma sigue existiendo.');

    -- 1.J. Error 50015: Idioma sobre árbitro inexistente
    BEGIN TRY
        EXEC arbitraje.sp_InsertarIdiomaArbitro @ID_Arbitro = 999999, @Lengua = 'Alemán';
        INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Bloqueo árbitro inexistente en idioma', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50015');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50015
            INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Bloqueo árbitro inexistente en idioma', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Bloqueo árbitro inexistente en idioma', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.K. Error 50017: Lengua vacía al insertar idioma
    BEGIN TRY
        EXEC arbitraje.sp_InsertarIdiomaArbitro @ID_Arbitro = @id_arb, @Lengua = '   ';
        INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Bloqueo lengua vacía en idioma', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50017');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50017
            INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Bloqueo lengua vacía en idioma', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Bloqueo lengua vacía en idioma', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.L. Baja exitosa de árbitro (limpia sus idiomas y borra el árbitro)
    EXEC arbitraje.sp_EliminarArbitro @ID = @id_arb;
    IF NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @id_arb)
        INSERT INTO @Reporte VALUES ('sp_EliminarArbitro', 'Baja exitosa de árbitro sin designaciones', 'Caso de Éxito', 'OK', 'Árbitro e idiomas dados de baja correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarArbitro', 'Baja exitosa de árbitro sin designaciones', 'Caso de Éxito', 'FALLÓ', 'El árbitro aún figura en la tabla.');

    -- 1.M. Error 50012: Baja de árbitro ya eliminado / inexistente
    BEGIN TRY
        EXEC arbitraje.sp_EliminarArbitro @ID = @id_arb;
        INSERT INTO @Reporte VALUES ('sp_EliminarArbitro', 'Bloqueo baja de árbitro inexistente', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50012');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50012
            INSERT INTO @Reporte VALUES ('sp_EliminarArbitro', 'Bloqueo baja de árbitro inexistente', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarArbitro', 'Bloqueo baja de árbitro inexistente', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.N. Caso de Falla Múltiple en sp_InsertarArbitro (50010 + 50016 simultáneos)
    BEGIN TRY
        DECLARE @id_arb_mult INT;
        EXEC arbitraje.sp_InsertarArbitro @Nombre = NULL, @Apellido = NULL, @Categoria = 'FIFA Elite', @ID_Pais = 999999, @ID = @id_arb_mult OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarArbitro', 'Validación múltiple: campos nulos + país inexistente', 'Caso de Falla Múltiple', 'FALLÓ', 'Debió arrojar 50010 y 50016');
    END TRY
    BEGIN CATCH
        IF ERROR_MESSAGE() LIKE '%(50010)%' AND ERROR_MESSAGE() LIKE '%(50016)%'
            INSERT INTO @Reporte VALUES ('sp_InsertarArbitro', 'Validación múltiple: campos nulos + país inexistente', 'Caso de Falla Múltiple', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_InsertarArbitro', 'Validación múltiple: campos nulos + país inexistente', 'Caso de Falla Múltiple', 'FALLÓ', 'No acumuló ambos: ' + ERROR_MESSAGE());
    END CATCH;

    -- 1.O. Caso de Falla Múltiple en sp_InsertarIdiomaArbitro (50015 + 50017 simultáneos)
    BEGIN TRY
        EXEC arbitraje.sp_InsertarIdiomaArbitro @ID_Arbitro = 999999, @Lengua = '';
        INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Validación múltiple: árbitro inexistente + lengua vacía', 'Caso de Falla Múltiple', 'FALLÓ', 'Debió arrojar 50015 y 50017');
    END TRY
    BEGIN CATCH
        IF ERROR_MESSAGE() LIKE '%(50015)%' AND ERROR_MESSAGE() LIKE '%(50017)%'
            INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Validación múltiple: árbitro inexistente + lengua vacía', 'Caso de Falla Múltiple', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_InsertarIdiomaArbitro', 'Validación múltiple: árbitro inexistente + lengua vacía', 'Caso de Falla Múltiple', 'FALLÓ', 'No acumuló ambos: ' + ERROR_MESSAGE());
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Bloque 1', 'Excepción crítica en Bloque 1', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

-- =========================================================================================
-- 2. BLOQUE DE PRUEBAS: ABM DESIGNACIÓN ARBITRAL Y CONFLICTO DE NACIONALIDAD
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    -- Insertamos un país extra primero para desfasar ID_Pais respecto de ID_Seleccion y probar el JOIN real
    DECLARE @id_pais_extra INT, @id_pais_loc INT, @id_pais_vis INT, @id_pais_neu INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Desfasaje Test', @id_generado = @id_pais_extra OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Local Desig', @id_generado = @id_pais_loc OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Visita Desig', @id_generado = @id_pais_vis OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Neutral Desig', @id_generado = @id_pais_neu OUTPUT;

    DECLARE @id_sede_d INT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Arbitraje Test', @ciudad = 'Miami', @capacidad = 65000, @huso_horario = '-05:00', @id_pais = @id_pais_loc, @id_generado = @id_sede_d OUTPUT;

    DECLARE @id_fase_grupos INT, @id_fase_elim INT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Grupos Desig', @orden = 1, @id_generado = @id_fase_grupos OUTPUT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Octavos Desig', @orden = 3, @id_generado = @id_fase_elim OUTPUT;

    DECLARE @id_sel_loc INT, @id_sel_vis INT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_loc, @confederacion = 'CONMEBOL', @grupo_asignado = 'A', @id_generado = @id_sel_loc OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_vis, @confederacion = 'UEFA', @grupo_asignado = 'A', @id_generado = @id_sel_vis OUTPUT;

    EXEC partido.sp_CrearPartido @id_sede = @id_sede_d, @id_fase = @id_fase_grupos, @fecha_hora_local = '2026-06-15 16:00:00', @id_local = @id_sel_loc, @id_visitante = @id_sel_vis;
    DECLARE @id_part_grupos INT;
    SELECT TOP 1 @id_part_grupos = ID FROM partido.Partido WHERE ID_Sede = @id_sede_d AND ID_Fase = @id_fase_grupos ORDER BY ID DESC;

    EXEC partido.sp_CrearPartido @id_sede = @id_sede_d, @id_fase = @id_fase_elim, @fecha_hora_local = '2026-07-01 18:00:00', @id_local = @id_sel_loc, @id_visitante = @id_sel_vis;
    DECLARE @id_part_elim INT;
    SELECT TOP 1 @id_part_elim = ID FROM partido.Partido WHERE ID_Sede = @id_sede_d AND ID_Fase = @id_fase_elim ORDER BY ID DESC;

    -- Creamos un árbitro neutral y un árbitro con nacionalidad de la Selección Visitante
    DECLARE @id_arb_neutral INT, @id_arb_conflicto INT;
    EXEC arbitraje.sp_InsertarArbitro @Nombre = 'Szymon', @Apellido = 'Marciniak', @Categoria = 'FIFA Elite', @ID_Pais = @id_pais_neu, @ID = @id_arb_neutral OUTPUT;
    EXEC arbitraje.sp_InsertarArbitro @Nombre = 'Arbitro', @Apellido = 'Parcial', @Categoria = 'FIFA Elite', @ID_Pais = @id_pais_vis, @ID = @id_arb_conflicto OUTPUT;

    -- 2.A. Designación exitosa de árbitro neutral
    EXEC arbitraje.sp_DesignarArbitro @ID_Partido = @id_part_grupos, @ID_Arbitro = @id_arb_neutral, @Rol = 'Árbitro Principal', @Informe = 'Partido sin incidencias previas.';
    IF EXISTS (SELECT 1 FROM arbitraje.Designacion_Arbitral WHERE ID_Partido = @id_part_grupos AND ID_Arbitro = @id_arb_neutral)
        INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Designación exitosa de árbitro neutral', 'Caso de Éxito', 'OK', 'Árbitro neutral asignado como Principal.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Designación exitosa de árbitro neutral', 'Caso de Éxito', 'FALLÓ', 'No se registró la designación.');

    -- 2.B. Modificación exitosa de designación arbitral (carga de informe post-partido)
    EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_part_grupos, @ID_Arbitro = @id_arb_neutral, @Informe = 'Informe final aprobado por comité.';
    IF EXISTS (SELECT 1 FROM arbitraje.Designacion_Arbitral WHERE ID_Partido = @id_part_grupos AND ID_Arbitro = @id_arb_neutral AND informe = 'Informe final aprobado por comité.')
        INSERT INTO @Reporte VALUES ('sp_ModificarDesignacionArbitro', 'Actualización exitosa de informe post-partido', 'Caso de Éxito', 'OK', 'Informe arbitral actualizado correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ModificarDesignacionArbitro', 'Actualización exitosa de informe post-partido', 'Caso de Éxito', 'FALLÓ', 'No se actualizó el informe.');

    -- 2.C. Error 50008: Modificación de designación inexistente
    BEGIN TRY
        EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = 999999, @ID_Arbitro = @id_arb_neutral, @Informe = 'Test';
        INSERT INTO @Reporte VALUES ('sp_ModificarDesignacionArbitro', 'Bloqueo modificación designación inexistente', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50008');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50008
            INSERT INTO @Reporte VALUES ('sp_ModificarDesignacionArbitro', 'Bloqueo modificación designación inexistente', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_ModificarDesignacionArbitro', 'Bloqueo modificación designación inexistente', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.D. Error 50002: Bloqueo por conflicto de nacionalidad (país del árbitro = país selección visitante)
    BEGIN TRY
        EXEC arbitraje.sp_DesignarArbitro @ID_Partido = @id_part_grupos, @ID_Arbitro = @id_arb_conflicto, @Rol = 'VAR';
        INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Bloqueo conflicto de nacionalidad FIFA', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50002');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50002
            INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Bloqueo conflicto de nacionalidad FIFA', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Bloqueo conflicto de nacionalidad FIFA', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.E. Error 50003: Bloqueo de doble designación del mismo árbitro en el mismo partido
    BEGIN TRY
        EXEC arbitraje.sp_DesignarArbitro @ID_Partido = @id_part_grupos, @ID_Arbitro = @id_arb_neutral, @Rol = 'Cuarto Árbitro';
        INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Bloqueo árbitro duplicado en el partido', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50003');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50003
            INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Bloqueo árbitro duplicado en el partido', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Bloqueo árbitro duplicado en el partido', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.F. Error 50001: Bloqueo por partido o árbitro inexistente
    BEGIN TRY
        EXEC arbitraje.sp_DesignarArbitro @ID_Partido = 999999, @ID_Arbitro = @id_arb_neutral, @Rol = 'Principal';
        INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Bloqueo partido o árbitro inexistente', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50001');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50001
            INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Bloqueo partido o árbitro inexistente', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Bloqueo partido o árbitro inexistente', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.G. Designación en fase eliminatoria (orden >= 2 con advertencia FIFA)
    EXEC arbitraje.sp_DesignarArbitro @ID_Partido = @id_part_elim, @ID_Arbitro = @id_arb_neutral, @Rol = 'Árbitro Principal';
    IF EXISTS (SELECT 1 FROM arbitraje.Designacion_Arbitral WHERE ID_Partido = @id_part_elim AND ID_Arbitro = @id_arb_neutral)
        INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Designación en fase eliminatoria con advertencia', 'Caso de Éxito', 'OK', 'Designado en Octavos emitiendo advertencia FIFA.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_DesignarArbitro', 'Designación en fase eliminatoria con advertencia', 'Caso de Éxito', 'FALLÓ', 'No se asignó en fase eliminatoria.');

    -- 2.H. Error 50013: Bloqueo de baja de árbitro que ya dirigió partidos
    BEGIN TRY
        EXEC arbitraje.sp_EliminarArbitro @ID = @id_arb_neutral;
        INSERT INTO @Reporte VALUES ('sp_EliminarArbitro', 'Bloqueo baja de árbitro con designaciones', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50013');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50013
            INSERT INTO @Reporte VALUES ('sp_EliminarArbitro', 'Bloqueo baja de árbitro con designaciones', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarArbitro', 'Bloqueo baja de árbitro con designaciones', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.I. Eliminación exitosa de designación arbitral
    EXEC arbitraje.sp_EliminarDesignacionArbitro @ID_Partido = @id_part_elim, @ID_Arbitro = @id_arb_neutral;
    IF NOT EXISTS (SELECT 1 FROM arbitraje.Designacion_Arbitral WHERE ID_Partido = @id_part_elim AND ID_Arbitro = @id_arb_neutral)
        INSERT INTO @Reporte VALUES ('sp_EliminarDesignacionArbitro', 'Baja exitosa de designación arbitral', 'Caso de Éxito', 'OK', 'Designación eliminada correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarDesignacionArbitro', 'Baja exitosa de designación arbitral', 'Caso de Éxito', 'FALLÓ', 'La designación sigue existiendo.');

    -- 2.J. Error 50009: Eliminación de designación inexistente
    BEGIN TRY
        EXEC arbitraje.sp_EliminarDesignacionArbitro @ID_Partido = @id_part_elim, @ID_Arbitro = @id_arb_neutral;
        INSERT INTO @Reporte VALUES ('sp_EliminarDesignacionArbitro', 'Bloqueo baja de designación inexistente', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50009');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50009
            INSERT INTO @Reporte VALUES ('sp_EliminarDesignacionArbitro', 'Bloqueo baja de designación inexistente', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarDesignacionArbitro', 'Bloqueo baja de designación inexistente', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Bloque 2', 'Excepción crítica en Bloque 2', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

-- =========================================================================================
-- 3. BLOQUE DE PRUEBAS: ABM DE GOLES Y MARCADOR AUTOMÁTICO
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pg1 INT, @id_pg2 INT, @id_pg3 INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Gol Local', @id_generado = @id_pg1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Gol Visita', @id_generado = @id_pg2 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Gol Ajeno', @id_generado = @id_pg3 OUTPUT;

    DECLARE @id_sede_g INT, @id_fase_g INT, @id_club_g INT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Goles Test', @ciudad = 'Toronto', @capacidad = 45000, @huso_horario = '-05:00', @id_pais = @id_pg1, @id_generado = @id_sede_g OUTPUT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Goles Test', @orden = 1, @id_generado = @id_fase_g OUTPUT;
    EXEC administracion.sp_InsertarClub @nombre = 'Club Goles Test', @id_generado = @id_club_g OUTPUT;

    DECLARE @id_sg_loc INT, @id_sg_vis INT, @id_sg_aje INT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pg1, @confederacion = 'CONMEBOL', @grupo_asignado = 'B', @id_generado = @id_sg_loc OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pg2, @confederacion = 'UEFA', @grupo_asignado = 'B', @id_generado = @id_sg_vis OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pg3, @confederacion = 'CAF', @grupo_asignado = 'C', @id_generado = @id_sg_aje OUTPUT;

    EXEC partido.sp_CrearPartido @id_sede = @id_sede_g, @id_fase = @id_fase_g, @fecha_hora_local = '2026-06-18 19:00:00', @id_local = @id_sg_loc, @id_visitante = @id_sg_vis;
    DECLARE @id_part_gol INT;
    SELECT TOP 1 @id_part_gol = ID FROM partido.Partido WHERE ID_Sede = @id_sede_g ORDER BY ID DESC;

    EXEC partido.sp_RegistrarFormacion @id_partido = @id_part_gol, @id_seleccion = @id_sg_loc, @esquema_tactico = '4-3-3';
    DECLARE @id_form_gol INT;
    SELECT TOP 1 @id_form_gol = ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_part_gol AND ID_Seleccion = @id_sg_loc;

    -- Jugadores convocados y alineados (2 titulares, 1 suplente y 1 no alineado)
    DECLARE @jg1 INT, @jg2 INT, @jg_sup INT, @jg_no_alin INT, @id_conv_tmp INT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Julian', @apellido = 'Alvarez', @fecha_nacimiento = '2000-01-31', @id_club = @id_club_g, @posicion_habitual = 'DELANTERO', @id_generado = @jg1 OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Enzo', @apellido = 'Fernandez', @fecha_nacimiento = '2001-01-17', @id_club = @id_club_g, @posicion_habitual = 'MEDIOCAMPISTA', @id_generado = @jg2 OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Lautaro', @apellido = 'Martinez', @fecha_nacimiento = '1997-08-22', @id_club = @id_club_g, @posicion_habitual = 'DELANTERO', @id_generado = @jg_sup OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Jugador', @apellido = 'NoAlineado', @fecha_nacimiento = '1999-05-10', @id_club = @id_club_g, @posicion_habitual = 'DEFENSOR', @id_generado = @jg_no_alin OUTPUT;

    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @jg1, @id_seleccion = @id_sg_loc, @dorsal = 9, @id_generado = @id_conv_tmp OUTPUT;
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @jg2, @id_seleccion = @id_sg_loc, @dorsal = 8, @id_generado = @id_conv_tmp OUTPUT;
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @jg_sup, @id_seleccion = @id_sg_loc, @dorsal = 22, @id_generado = @id_conv_tmp OUTPUT;
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @jg_no_alin, @id_seleccion = @id_sg_loc, @dorsal = 4, @id_generado = @id_conv_tmp OUTPUT;

    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_gol, @id_jugador = @jg1, @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_gol, @id_jugador = @jg2, @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_gol, @id_jugador = @jg_sup, @es_titular = 0;

    -- 3.A. Gol de jugada con asistencia e impacto en marcador (1 - 0)
    EXEC partido.sp_RegistrarGol
        @ID_Partido = @id_part_gol,
        @ID_Jugador_autor = @jg1,
        @ID_Jugador_asistencia = @jg2,
        @ID_Seleccion = @id_sg_loc,
        @Minuto = 23,
        @Tipo = 'Jugada',
        @Periodo = 'Primer Tiempo';

    IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_part_gol AND goles_local = 1 AND goles_visitante = 0)
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Gol con asistencia y actualización marcador (1-0)', 'Caso de Éxito', 'OK', 'Gol registrado y marcador actualizado a 1-0.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Gol con asistencia y actualización marcador (1-0)', 'Caso de Éxito', 'FALLÓ', 'No se actualizó el marcador a 1-0.');

    -- 3.B. Ingresa suplente en min 60, anota de penal sin asistencia (2 - 0)
    EXEC partido.sp_RegistrarSustitucion @id_partido = @id_part_gol, @id_jugador_sale = @jg1, @id_jugador_entra = @jg_sup, @minuto = 60, @motivo = 'Táctico';
    EXEC partido.sp_RegistrarGol
        @ID_Partido = @id_part_gol,
        @ID_Jugador_autor = @jg_sup,
        @ID_Jugador_asistencia = NULL,
        @ID_Seleccion = @id_sg_loc,
        @Minuto = 75,
        @Tipo = 'Penal',
        @Periodo = 'Segundo Tiempo';

    IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_part_gol AND goles_local = 2 AND goles_visitante = 0)
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Gol de penal sin asistencia (marcador 2-0)', 'Caso de Éxito', 'OK', 'Marcador actualizado a 2-0.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Gol de penal sin asistencia (marcador 2-0)', 'Caso de Éxito', 'FALLÓ', 'No se actualizó el marcador a 2-0.');

    -- 3.C. Gol en contra (suma para la selección visitante: 2 - 1)
    EXEC partido.sp_RegistrarGol
        @ID_Partido = @id_part_gol,
        @ID_Jugador_autor = @jg2,
        @ID_Jugador_asistencia = NULL,
        @ID_Seleccion = @id_sg_vis,
        @Minuto = 88,
        @Tipo = 'En contra',
        @Periodo = 'Segundo Tiempo';

    IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_part_gol AND goles_local = 2 AND goles_visitante = 1)
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Gol en contra suma al rival (marcador 2-1)', 'Caso de Éxito', 'OK', 'Marcador actualizado a 2-1.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Gol en contra suma al rival (marcador 2-1)', 'Caso de Éxito', 'FALLÓ', 'No se actualizó el marcador a 2-1.');

    -- 3.D. Modificación exitosa de gol
    DECLARE @id_gol_mod INT;
    SELECT TOP 1 @id_gol_mod = ID FROM partido.Gol WHERE ID_Partido = @id_part_gol AND ID_Jugador_autor = @jg2 ORDER BY ID DESC;
    EXEC partido.sp_ModificarGol @ID_Gol = @id_gol_mod, @Minuto = 89;

    IF EXISTS (SELECT 1 FROM partido.Gol WHERE ID = @id_gol_mod AND minuto = 89)
        INSERT INTO @Reporte VALUES ('sp_ModificarGol', 'Modificación exitosa de minuto de gol', 'Caso de Éxito', 'OK', 'Minuto del gol actualizado a 89.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ModificarGol', 'Modificación exitosa de minuto de gol', 'Caso de Éxito', 'FALLÓ', 'No se modificó el gol.');

    -- 3.E. Eliminación de gol (anulado por VAR) y recálculo automático del marcador a 2 - 0
    EXEC partido.sp_EliminarGol @ID_Gol = @id_gol_mod;
    IF NOT EXISTS (SELECT 1 FROM partido.Gol WHERE ID = @id_gol_mod)
       AND EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_part_gol AND goles_local = 2 AND goles_visitante = 0)
        INSERT INTO @Reporte VALUES ('sp_EliminarGol', 'Baja de gol y recálculo automático de marcador (2-0)', 'Caso de Éxito', 'OK', 'Gol anulado y marcador recalculado a 2-0.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarGol', 'Baja de gol y recálculo automático de marcador (2-0)', 'Caso de Éxito', 'FALLÓ', 'No se recalculó el marcador tras borrar el gol.');

    -- 3.F. Error 50026 y 50027: Modificar y eliminar gol inexistente
    BEGIN TRY
        EXEC partido.sp_EliminarGol @ID_Gol = 999999;
        INSERT INTO @Reporte VALUES ('sp_EliminarGol', 'Bloqueo baja de gol inexistente', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50027');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50027
            INSERT INTO @Reporte VALUES ('sp_EliminarGol', 'Bloqueo baja de gol inexistente', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarGol', 'Bloqueo baja de gol inexistente', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.G. Error 50020: Partido inexistente
    BEGIN TRY
        EXEC partido.sp_RegistrarGol 999999, @jg1, NULL, @id_sg_loc, 10, 'Jugada', 'Primer Tiempo';
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo partido inexistente', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50020');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50020
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo partido inexistente', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo partido inexistente', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.H. Error 50024: Selección no participa en el partido
    BEGIN TRY
        EXEC partido.sp_RegistrarGol @id_part_gol, @jg1, NULL, @id_sg_aje, 10, 'Jugada', 'Primer Tiempo';
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo selección ajena al partido', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50024');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50024
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo selección ajena al partido', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo selección ajena al partido', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.I. Error 50021: Autor del gol no alineado en el partido
    BEGIN TRY
        EXEC partido.sp_RegistrarGol @id_part_gol, @jg_no_alin, NULL, @id_sg_loc, 10, 'Jugada', 'Primer Tiempo';
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo autor no alineado en el partido', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50021');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50021
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo autor no alineado en el partido', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo autor no alineado en el partido', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.J. Error 50022: Asistente no alineado en el partido
    BEGIN TRY
        EXEC partido.sp_RegistrarGol @id_part_gol, @jg1, @jg_no_alin, @id_sg_loc, 10, 'Jugada', 'Primer Tiempo';
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo asistente no alineado en el partido', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50022');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50022
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo asistente no alineado en el partido', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo asistente no alineado en el partido', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.K. Error 50023: Autor y asistente son el mismo jugador
    BEGIN TRY
        EXEC partido.sp_RegistrarGol @id_part_gol, @jg1, @jg1, @id_sg_loc, 10, 'Jugada', 'Primer Tiempo';
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo autor y asistente idénticos', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50023');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50023
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo autor y asistente idénticos', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo autor y asistente idénticos', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.L. Error 50025: Minuto del gol inválido
    BEGIN TRY
        EXEC partido.sp_RegistrarGol @id_part_gol, @jg1, NULL, @id_sg_loc, 145, 'Jugada', 'Segundo Tiempo';
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo minuto fuera de rango (>140)', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50025');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50025
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo minuto fuera de rango (>140)', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo minuto fuera de rango (>140)', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.M. Error 50039: Bloqueo de anulación de sustitución si el jugador ingresado ya anotó un gol
    DECLARE @id_sust_gol INT;
    SELECT TOP 1 @id_sust_gol = ID FROM partido.Sustitucion WHERE ID_Partido = @id_part_gol AND ID_Jugador_Entra = @jg_sup;

    BEGIN TRY
        EXEC partido.sp_EliminarSustitucion @id_sustitucion = @id_sust_gol;
        INSERT INTO @Reporte VALUES ('sp_EliminarSustitucion', 'Bloqueo anular cambio de jugador con gol', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50039');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50039
            INSERT INTO @Reporte VALUES ('sp_EliminarSustitucion', 'Bloqueo anular cambio de jugador con gol', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarSustitucion', 'Bloqueo anular cambio de jugador con gol', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.N. Error 50040: Bloqueo de asistencia en gol de penal
    BEGIN TRY
        EXEC partido.sp_RegistrarGol @id_part_gol, @jg1, @jg2, @id_sg_loc, 80, 'Penal', 'Segundo Tiempo';
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo asistencia en gol de penal', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50040');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50040
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo asistencia en gol de penal', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo asistencia en gol de penal', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.O. Error 50042: Bloqueo de alargue o definición por penales en Fase de Grupos
    BEGIN TRY
        EXEC partido.sp_RegistrarGol @id_part_gol, @jg1, NULL, @id_sg_loc, 105, 'Jugada', 'Alargue';
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo alargue/penales en Fase de Grupos', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50042');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50042
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo alargue/penales en Fase de Grupos', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo alargue/penales en Fase de Grupos', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.P. Partido de Fase Eliminatoria: bloqueo si no está empatado (50043) y éxito de tanda de penales al empatar
    DECLARE @id_fase_elim_g INT, @id_part_elim_g INT, @id_form_elim_g INT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Cuartos Goles Test', @orden = 4, @id_generado = @id_fase_elim_g OUTPUT;
    EXEC partido.sp_CrearPartido @id_sede = @id_sede_g, @id_fase = @id_fase_elim_g, @fecha_hora_local = '2026-07-04 19:00:00', @id_local = @id_sg_loc, @id_visitante = @id_sg_vis;
    SELECT TOP 1 @id_part_elim_g = ID FROM partido.Partido WHERE ID_Fase = @id_fase_elim_g ORDER BY ID DESC;
    EXEC partido.sp_RegistrarFormacion @id_partido = @id_part_elim_g, @id_seleccion = @id_sg_loc, @esquema_tactico = '4-3-3';
    SELECT TOP 1 @id_form_elim_g = ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_part_elim_g AND ID_Seleccion = @id_sg_loc;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_elim_g, @id_jugador = @jg1, @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_elim_g, @id_jugador = @jg2, @es_titular = 1;

    -- Local se pone 1-0 en Alargue
    EXEC partido.sp_RegistrarGol @id_part_elim_g, @jg1, NULL, @id_sg_loc, 105, 'Jugada', 'Alargue';

    -- Intento de Definición por penales estando 1-0 (debe fallar con 50043)
    BEGIN TRY
        EXEC partido.sp_RegistrarGol @id_part_elim_g, @jg1, NULL, @id_sg_loc, 120, 'Penal', 'Definición por penales';
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo definición por penales sin empate', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50043');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50043
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo definición por penales sin empate', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Bloqueo definición por penales sin empate', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- Empata el partido 1-1 (gol en contra para visitante) y ahora sí permite Definición por penales manteniendo el 1-1 de juego
    EXEC partido.sp_RegistrarGol @id_part_elim_g, @jg2, NULL, @id_sg_vis, 118, 'En contra', 'Alargue';
    EXEC partido.sp_RegistrarGol @id_part_elim_g, @jg1, NULL, @id_sg_loc, 120, 'Penal', 'Definición por penales';

    IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_part_elim_g AND goles_local = 1 AND goles_visitante = 1)
       AND EXISTS (SELECT 1 FROM partido.Gol WHERE ID_Partido = @id_part_elim_g AND periodo = 'Definición por penales')
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Definición por penales en eliminatoria empatada (1-1)', 'Caso de Éxito', 'OK', 'Penal de definición registrado manteniendo 1-1 en los 120 min.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Definición por penales en eliminatoria empatada (1-1)', 'Caso de Éxito', 'FALLÓ', 'Error al registrar definición por penales.');

    -- 3.Q. Caso de Falla Múltiple en sp_RegistrarGol (50024 + 50021 + 50025 simultáneos)
    BEGIN TRY
        EXEC partido.sp_RegistrarGol @id_part_gol, @jg_no_alin, NULL, @id_sg_aje, 150, 'Jugada', 'Primer Tiempo';
        INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Validación múltiple: selección ajena + autor no alineado + min>140', 'Caso de Falla Múltiple', 'FALLÓ', 'Debió arrojar múltiples errores');
    END TRY
    BEGIN CATCH
        IF ERROR_MESSAGE() LIKE '%(50024)%' AND ERROR_MESSAGE() LIKE '%(50021)%' AND ERROR_MESSAGE() LIKE '%(50025)%'
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Validación múltiple: selección ajena + autor no alineado + min>140', 'Caso de Falla Múltiple', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarGol', 'Validación múltiple: selección ajena + autor no alineado + min>140', 'Caso de Falla Múltiple', 'FALLÓ', 'No acumuló todos: ' + ERROR_MESSAGE());
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Bloque 3', 'Excepción crítica en Bloque 3', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

-- =========================================================================================
-- 4. BLOQUE DE PRUEBAS: TARJETAS, SUSPENSIONES Y PARTIDOS PERDIDOS POR SUSPENSIÓN
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pt1 INT, @id_pt2 INT, @id_pt3 INT, @id_pt4 INT, @id_pt5 INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Tarjeta 1', @id_generado = @id_pt1 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Tarjeta 2', @id_generado = @id_pt2 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Tarjeta 3', @id_generado = @id_pt3 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Tarjeta 4', @id_generado = @id_pt4 OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Tarjeta 5', @id_generado = @id_pt5 OUTPUT;

    DECLARE @id_sede_t INT, @id_fase_t INT, @id_club_t INT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Disciplina Test', @ciudad = 'Los Ángeles', @capacidad = 70000, @huso_horario = '-08:00', @id_pais = @id_pt1, @id_generado = @id_sede_t OUTPUT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Disciplina Test', @orden = 1, @id_generado = @id_fase_t OUTPUT;
    EXEC administracion.sp_InsertarClub @nombre = 'Club Disciplina Test', @id_generado = @id_club_t OUTPUT;

    DECLARE @id_st1 INT, @id_st2 INT, @id_st3 INT, @id_st4 INT, @id_st5 INT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pt1, @confederacion = 'CONMEBOL', @grupo_asignado = 'D', @id_generado = @id_st1 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pt2, @confederacion = 'UEFA', @grupo_asignado = 'D', @id_generado = @id_st2 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pt3, @confederacion = 'CAF', @grupo_asignado = 'D', @id_generado = @id_st3 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pt4, @confederacion = 'AFC', @grupo_asignado = 'D', @id_generado = @id_st4 OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pt5, @confederacion = 'CONCACAF', @grupo_asignado = 'E', @id_generado = @id_st5 OUTPUT;

    -- Creamos 4 partidos sucesivos para la Selección 1
    EXEC partido.sp_CrearPartido @id_sede = @id_sede_t, @id_fase = @id_fase_t, @fecha_hora_local = '2026-06-12 18:00:00', @id_local = @id_st1, @id_visitante = @id_st2;
    DECLARE @id_part_f1 INT;
    SELECT TOP 1 @id_part_f1 = ID FROM partido.Partido WHERE ID_Sede = @id_sede_t AND fecha_hora_local = '2026-06-12 18:00:00' ORDER BY ID DESC;

    EXEC partido.sp_CrearPartido @id_sede = @id_sede_t, @id_fase = @id_fase_t, @fecha_hora_local = '2026-06-17 18:00:00', @id_local = @id_st1, @id_visitante = @id_st3;
    DECLARE @id_part_f2 INT;
    SELECT TOP 1 @id_part_f2 = ID FROM partido.Partido WHERE ID_Sede = @id_sede_t AND fecha_hora_local = '2026-06-17 18:00:00' ORDER BY ID DESC;

    EXEC partido.sp_CrearPartido @id_sede = @id_sede_t, @id_fase = @id_fase_t, @fecha_hora_local = '2026-06-22 18:00:00', @id_local = @id_st1, @id_visitante = @id_st4;
    DECLARE @id_part_f3 INT;
    SELECT TOP 1 @id_part_f3 = ID FROM partido.Partido WHERE ID_Sede = @id_sede_t AND fecha_hora_local = '2026-06-22 18:00:00' ORDER BY ID DESC;

    EXEC partido.sp_CrearPartido @id_sede = @id_sede_t, @id_fase = @id_fase_t, @fecha_hora_local = '2026-06-27 18:00:00', @id_local = @id_st1, @id_visitante = @id_st5;
    DECLARE @id_part_f4 INT;
    SELECT TOP 1 @id_part_f4 = ID FROM partido.Partido WHERE ID_Sede = @id_sede_t AND fecha_hora_local = '2026-06-27 18:00:00' ORDER BY ID DESC;

    -- Formaciones de la Selección 1 en los 4 partidos
    EXEC partido.sp_RegistrarFormacion @id_partido = @id_part_f1, @id_seleccion = @id_st1, @esquema_tactico = '4-4-2';
    EXEC partido.sp_RegistrarFormacion @id_partido = @id_part_f2, @id_seleccion = @id_st1, @esquema_tactico = '4-4-2';
    EXEC partido.sp_RegistrarFormacion @id_partido = @id_part_f3, @id_seleccion = @id_st1, @esquema_tactico = '4-4-2';
    EXEC partido.sp_RegistrarFormacion @id_partido = @id_part_f4, @id_seleccion = @id_st1, @esquema_tactico = '4-4-2';

    DECLARE @id_form_f1 INT, @id_form_f2 INT, @id_form_f3 INT, @id_form_f4 INT;
    SELECT @id_form_f1 = ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_part_f1 AND ID_Seleccion = @id_st1;
    SELECT @id_form_f2 = ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_part_f2 AND ID_Seleccion = @id_st1;
    SELECT @id_form_f3 = ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_part_f3 AND ID_Seleccion = @id_st1;
    SELECT @id_form_f4 = ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_part_f4 AND ID_Seleccion = @id_st1;

    -- Jugadores y Cuerpo Técnico
    DECLARE @jt_acum INT, @jt_doble INT, @jt_roja INT, @jt_no_alin INT, @id_ct_loc INT, @id_ct_aje INT, @id_c_tmp INT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Cristian', @apellido = 'Romero', @fecha_nacimiento = '1998-04-27', @id_club = @id_club_t, @posicion_habitual = 'DEFENSOR', @id_generado = @jt_acum OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Nicolas', @apellido = 'Otamendi', @fecha_nacimiento = '1988-02-12', @id_club = @id_club_t, @posicion_habitual = 'DEFENSOR', @id_generado = @jt_doble OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Leandro', @apellido = 'Paredes', @fecha_nacimiento = '1994-06-29', @id_club = @id_club_t, @posicion_habitual = 'MEDIOCAMPISTA', @id_generado = @jt_roja OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Jugador', @apellido = 'SinPlanilla', @fecha_nacimiento = '1999-09-09', @id_club = @id_club_t, @posicion_habitual = 'DELANTERO', @id_generado = @jt_no_alin OUTPUT;

    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @jt_acum, @id_seleccion = @id_st1, @dorsal = 13, @id_generado = @id_c_tmp OUTPUT;
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @jt_doble, @id_seleccion = @id_st1, @dorsal = 19, @id_generado = @id_c_tmp OUTPUT;
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @jt_roja, @id_seleccion = @id_st1, @dorsal = 5, @id_generado = @id_c_tmp OUTPUT;
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @jt_no_alin, @id_seleccion = @id_st1, @dorsal = 20, @id_generado = @id_c_tmp OUTPUT;

    EXEC administracion.sp_InsertarMiembroCuerpoTecnico @nombre = 'Lionel', @apellido = 'Scaloni', @rol = 'DIRECTOR TECNICO', @id_seleccion = @id_st1, @id_generado = @id_ct_loc OUTPUT;
    EXEC administracion.sp_InsertarMiembroCuerpoTecnico @nombre = 'DT', @apellido = 'Ajeno', @rol = 'DIRECTOR TECNICO', @id_seleccion = @id_st4, @id_generado = @id_ct_aje OUTPUT;

    -- Alineamos a los jugadores en Partido 1 y Partido 2
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_f1, @id_jugador = @jt_acum, @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_f1, @id_jugador = @jt_doble, @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_f1, @id_jugador = @jt_roja, @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_f2, @id_jugador = @jt_acum, @es_titular = 1;

    -- 4.A. Primera tarjeta amarilla en Partido 1 (no genera suspensión)
    EXEC partido.sp_RegistrarTarjetaYSuspension
        @ID_Partido = @id_part_f1,
        @ID_Jugador = @jt_acum,
        @Minuto = 35,
        @Motivo = 'Sujeción reiterada',
        @Tipo = 'AMARILLA',
        @Es_Doble_Amarilla = 0;

    IF EXISTS (SELECT 1 FROM partido.Tarjeta WHERE ID_Partido = @id_part_f1 AND ID_Jugador = @jt_acum AND tipo = 'AMARILLA')
       AND NOT EXISTS (SELECT 1 FROM partido.Suspension WHERE ID_Jugador = @jt_acum)
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', '1ra amarilla registrada (sin suspensión)', 'Caso de Éxito', 'OK', '1ra amarilla asentada sin sanción.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', '1ra amarilla registrada (sin suspensión)', 'Caso de Éxito', 'FALLÓ', 'Comportamiento inesperado en 1ra amarilla.');

    -- 4.B. Segunda tarjeta amarilla en Partido 2 (genera suspensión automática por acumulación)
    EXEC partido.sp_RegistrarTarjetaYSuspension
        @ID_Partido = @id_part_f2,
        @ID_Jugador = @jt_acum,
        @Minuto = 70,
        @Motivo = 'Entrada tardía',
        @Tipo = 'AMARILLA',
        @Es_Doble_Amarilla = 0,
        @Partidos_Suspension = 1;

    DECLARE @id_susp_acum INT;
    SELECT TOP 1 @id_susp_acum = ID FROM partido.Suspension WHERE ID_Jugador = @jt_acum AND ID_Partido = @id_part_f2;

    IF @id_susp_acum IS NOT NULL
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Suspensión automática por 2 amarillas en partidos distintos', 'Caso de Éxito', 'OK', 'Suspensión de 1 fecha creada automáticamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Suspensión automática por 2 amarillas en partidos distintos', 'Caso de Éxito', 'FALLÓ', 'No se generó la suspensión por acumulación.');

    -- 4.C. Error 50023 (Caso obligatorio TP): Jugador suspendido no puede ser alineado en el siguiente partido (Partido 3)
    BEGIN TRY
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_f3, @id_jugador = @jt_acum, @es_titular = 1;
        INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo jugador suspendido en partido siguiente', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50023');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50023
            INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo jugador suspendido en partido siguiente', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarAlineacion', 'Bloqueo jugador suspendido en partido siguiente', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.D. Cumplimiento de suspensión en Partido 3 (Partido_Perdido_Suspension) y rehabilitación en Partido 4
    EXEC partido.sp_RegistrarCumplimientoSuspension @ID_Suspension = @id_susp_acum, @ID_Partido_Perdido = @id_part_f3;

    -- 4.E. Error 50031: Bloqueo de intento de descontar fecha de una suspensión ya cumplida (en Partido 4 antes de alinearlo)
    BEGIN TRY
        EXEC partido.sp_RegistrarCumplimientoSuspension @ID_Suspension = @id_susp_acum, @ID_Partido_Perdido = @id_part_f4;
        INSERT INTO @Reporte VALUES ('sp_RegistrarCumplimientoSuspension', 'Bloqueo descuento sobre suspensión ya cumplida', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50031');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50031
            INSERT INTO @Reporte VALUES ('sp_RegistrarCumplimientoSuspension', 'Bloqueo descuento sobre suspensión ya cumplida', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarCumplimientoSuspension', 'Bloqueo descuento sobre suspensión ya cumplida', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- Rehabilitación y alineación exitosa en Partido 4 tras haber cumplido en Partido 3
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_f4, @id_jugador = @jt_acum, @es_titular = 1;

    IF EXISTS (SELECT 1 FROM partido.Partido_Perdido_Suspension WHERE ID_Suspension = @id_susp_acum AND ID_Partido = @id_part_f3)
       AND EXISTS (SELECT 1 FROM partido.Suspension WHERE ID = @id_susp_acum AND partidos_descontados = 1)
       AND EXISTS (SELECT 1 FROM partido.Alineacion WHERE ID_Formacion = @id_form_f4 AND ID_Jugador = @jt_acum)
        INSERT INTO @Reporte VALUES ('sp_RegistrarCumplimientoSuspension', 'Descuento de fecha y rehabilitación en partido posterior', 'Caso de Éxito', 'OK', 'Fecha cumplida en Partido 3 y jugador habilitado en Partido 4.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarCumplimientoSuspension', 'Descuento de fecha y rehabilitación en partido posterior', 'Caso de Éxito', 'FALLÓ', 'No se descontó la fecha o no permitió alinear.');

    -- 4.F. Expulsión por doble amarilla en el mismo partido
    EXEC partido.sp_RegistrarTarjetaYSuspension
        @ID_Partido = @id_part_f1,
        @ID_Jugador = @jt_doble,
        @Minuto = 80,
        @Motivo = 'Segunda amonestación por cortar avance',
        @Tipo = 'AMARILLA',
        @Es_Doble_Amarilla = 1,
        @Partidos_Suspension = 1;

    IF EXISTS (SELECT 1 FROM partido.Suspension WHERE ID_Jugador = @jt_doble AND ID_Partido = @id_part_f1)
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Expulsión y suspensión por doble amarilla', 'Caso de Éxito', 'OK', 'Doble amarilla generó suspensión automática.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Expulsión y suspensión por doble amarilla', 'Caso de Éxito', 'FALLÓ', 'No se registró la suspensión por doble amarilla.');

    -- 4.G. Expulsión por roja directa con fechas parametrizadas (2 fechas), modificación y baja de suspensión
    EXEC partido.sp_RegistrarTarjetaYSuspension
        @ID_Partido = @id_part_f1,
        @ID_Jugador = @jt_roja,
        @Minuto = 89,
        @Motivo = 'Juego brusco grave',
        @Tipo = 'ROJA',
        @Es_Doble_Amarilla = 0,
        @Partidos_Suspension = 2;

    DECLARE @id_susp_roja INT;
    SELECT TOP 1 @id_susp_roja = ID FROM partido.Suspension WHERE ID_Jugador = @jt_roja;

    IF @id_susp_roja IS NOT NULL
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Expulsión por roja directa (2 fechas de sanción)', 'Caso de Éxito', 'OK', 'Roja directa generó suspensión de 2 partidos.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Expulsión por roja directa (2 fechas de sanción)', 'Caso de Éxito', 'FALLÓ', 'No se generó la suspensión de 2 fechas.');

    EXEC partido.sp_ModificarSuspension @ID_Suspension = @id_susp_roja, @Partidos_Totales = 3, @Motivo = 'Agravamiento de pena por informe arbitral';
    IF EXISTS (SELECT 1 FROM partido.Suspension WHERE ID = @id_susp_roja AND partidos_totales = 3)
        INSERT INTO @Reporte VALUES ('sp_ModificarSuspension', 'Modificación exitosa de fechas de suspensión', 'Caso de Éxito', 'OK', 'Sanción actualizada a 3 fechas.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ModificarSuspension', 'Modificación exitosa de fechas de suspensión', 'Caso de Éxito', 'FALLÓ', 'No se actualizó la suspensión.');

    EXEC partido.sp_EliminarSuspension @ID_Suspension = @id_susp_roja;
    IF NOT EXISTS (SELECT 1 FROM partido.Suspension WHERE ID = @id_susp_roja)
        INSERT INTO @Reporte VALUES ('sp_EliminarSuspension', 'Baja exitosa de suspensión', 'Caso de Éxito', 'OK', 'Suspensión eliminada correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarSuspension', 'Baja exitosa de suspensión', 'Caso de Éxito', 'FALLÓ', 'La suspensión sigue existiendo.');

    -- 4.H. Tarjeta a miembro del Cuerpo Técnico, modificación y baja de tarjeta
    EXEC partido.sp_RegistrarTarjetaYSuspension
        @ID_Partido = @id_part_f1,
        @ID_Cuerpo_Tecnico = @id_ct_loc,
        @Minuto = 55,
        @Motivo = 'Protestar fallos fuera del área técnica',
        @Tipo = 'AMARILLA';

    DECLARE @id_tarj_ct INT;
    SELECT TOP 1 @id_tarj_ct = ID FROM partido.Tarjeta WHERE ID_Partido = @id_part_f1 AND ID_Miembro_Cuerpo_Tecnico = @id_ct_loc;

    IF @id_tarj_ct IS NOT NULL
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Tarjeta amarilla a miembro del Cuerpo Técnico', 'Caso de Éxito', 'OK', 'Amonestación a DT registrada correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Tarjeta amarilla a miembro del Cuerpo Técnico', 'Caso de Éxito', 'FALLÓ', 'No se registró la tarjeta al DT.');

    EXEC partido.sp_ModificarTarjeta @ID_Tarjeta = @id_tarj_ct, @Minuto = 58;
    IF EXISTS (SELECT 1 FROM partido.Tarjeta WHERE ID = @id_tarj_ct AND minuto = 58)
        INSERT INTO @Reporte VALUES ('sp_ModificarTarjeta', 'Modificación exitosa de tarjeta', 'Caso de Éxito', 'OK', 'Minuto de tarjeta actualizado a 58.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_ModificarTarjeta', 'Modificación exitosa de tarjeta', 'Caso de Éxito', 'FALLÓ', 'No se modificó la tarjeta.');

    EXEC partido.sp_EliminarTarjeta @ID_Tarjeta = @id_tarj_ct;
    IF NOT EXISTS (SELECT 1 FROM partido.Tarjeta WHERE ID = @id_tarj_ct)
        INSERT INTO @Reporte VALUES ('sp_EliminarTarjeta', 'Baja exitosa de tarjeta', 'Caso de Éxito', 'OK', 'Tarjeta eliminada correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarTarjeta', 'Baja exitosa de tarjeta', 'Caso de Éxito', 'FALLÓ', 'La tarjeta sigue existiendo.');

    -- 4.I. Error 50004: Destinatario inválido (ambos nulos o ambos informados)
    BEGIN TRY
        EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_part_f1, @ID_Jugador = @jt_acum, @ID_Cuerpo_Tecnico = @id_ct_loc, @Minuto = 40, @Motivo = 'Error', @Tipo = 'AMARILLA';
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo destinatario simultáneo (Jugador y DT)', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50004');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50004
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo destinatario simultáneo (Jugador y DT)', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo destinatario simultáneo (Jugador y DT)', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.J. Error 50005: Partido inexistente en tarjeta
    BEGIN TRY
        EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = 999999, @ID_Jugador = @jt_acum, @Minuto = 40, @Motivo = 'Falta', @Tipo = 'AMARILLA';
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo partido inexistente', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50005');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50005
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo partido inexistente', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo partido inexistente', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.K. Error 50018: Minuto de tarjeta inválido
    BEGIN TRY
        EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_part_f1, @ID_Jugador = @jt_acum, @Minuto = 0, @Motivo = 'Falta', @Tipo = 'AMARILLA';
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo minuto inválido (<= 0)', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50018');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50018
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo minuto inválido (<= 0)', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo minuto inválido (<= 0)', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.L. Error 50006: Tipo de tarjeta inválido
    BEGIN TRY
        EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_part_f1, @ID_Jugador = @jt_acum, @Minuto = 50, @Motivo = 'Falta', @Tipo = 'AZUL';
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo tipo de tarjeta inexistente (AZUL)', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50006');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50006
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo tipo de tarjeta inexistente (AZUL)', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo tipo de tarjeta inexistente (AZUL)', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.M. Error 50019: Jugador sancionado no está en la alineación del partido
    BEGIN TRY
        EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_part_f1, @ID_Jugador = @jt_no_alin, @Minuto = 50, @Motivo = 'Protesta', @Tipo = 'AMARILLA';
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo jugador no alineado en el partido', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50019');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50019
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo jugador no alineado en el partido', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo jugador no alineado en el partido', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.N. Error 50007: Cuerpo técnico ajeno al partido
    BEGIN TRY
        EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_part_f1, @ID_Cuerpo_Tecnico = @id_ct_aje, @Minuto = 50, @Motivo = 'Protesta', @Tipo = 'AMARILLA';
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo miembro cuerpo técnico ajeno al partido', 'Caso de Falla', 'FALLÓ', 'Debió arrojar 50007');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50007
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo miembro cuerpo técnico ajeno al partido', 'Caso de Falla', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Bloqueo miembro cuerpo técnico ajeno al partido', 'Caso de Falla', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.O. Caso de Falla Múltiple en sp_RegistrarTarjetaYSuspension (50004 + 50018 + 50006 simultáneos)
    BEGIN TRY
        EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_part_f1, @ID_Jugador = NULL, @ID_Cuerpo_Tecnico = NULL, @Minuto = 150, @Motivo = 'Falta', @Tipo = 'VERDE';
        INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Validación múltiple: sin destinatario + min>140 + tipo inválido', 'Caso de Falla Múltiple', 'FALLÓ', 'Debió arrojar 50004, 50018 y 50006');
    END TRY
    BEGIN CATCH
        IF ERROR_MESSAGE() LIKE '%(50004)%' AND ERROR_MESSAGE() LIKE '%(50018)%' AND ERROR_MESSAGE() LIKE '%(50006)%'
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Validación múltiple: sin destinatario + min>140 + tipo inválido', 'Caso de Falla Múltiple', 'OK', ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarTarjetaYSuspension', 'Validación múltiple: sin destinatario + min>140 + tipo inválido', 'Caso de Falla Múltiple', 'FALLÓ', 'No acumuló todos: ' + ERROR_MESSAGE());
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Bloque 4', 'Excepción crítica en Bloque 4', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
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
    Procedimiento AS [SP Evaluado],
    Escenario AS [Escenario de Prueba],
    Tipo_Prueba AS [Tipo],
    Resultado AS [Estado],
    Detalle AS [Detalle / Mensaje]
FROM @Reporte
ORDER BY ID ASC;


