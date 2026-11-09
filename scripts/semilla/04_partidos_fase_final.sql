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

   Script: 04_partidos_fase_final.sql
   Descripción: Desarrollo partido a partido de los 10 encuentros de Fase Eliminatoria y Final
                (Partido 17 al Partido 26).
*/

USE Mundial2026;
GO

SET NOCOUNT ON;
GO

PRINT 'Iniciando Script 04: Partidos de Fase Eliminatoria y Final (17 al 26)...';

-- Limpiar datos previos de fases eliminatorias (orden >= 2) si se vuelve a ejecutar este script
IF EXISTS (
    SELECT 1 FROM partido.Formacion_Partido fp
    JOIN partido.Partido p ON p.ID = fp.ID_Partido
    JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase
    WHERE f.orden >= 2
)
BEGIN
    DECLARE @id_del INT, @i_del INT, @max_del INT;

    DECLARE @t_exh_del TABLE (fila INT IDENTITY(1,1), id_p INT);
    INSERT INTO @t_exh_del (id_p)
    SELECT DISTINCT ep.ID_Partido
    FROM publicidad.Exhibicion ex
    JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio
    JOIN partido.Partido p ON p.ID = ep.ID_Partido
    JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase
    WHERE f.orden >= 2;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_exh_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @id_del = id_p FROM @t_exh_del WHERE fila = @i_del;
        EXEC publicidad.sp_EliminarExhibicionPartido @id_partido = @id_del;
        SET @i_del += 1;
    END;

    DECLARE @t_goles_del TABLE (fila INT IDENTITY(1,1), id_reg INT);
    INSERT INTO @t_goles_del (id_reg)
    SELECT g.ID FROM partido.Gol g JOIN partido.Partido p ON p.ID = g.ID_Partido JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase WHERE f.orden >= 2;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_goles_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @id_del = id_reg FROM @t_goles_del WHERE fila = @i_del;
        EXEC partido.sp_EliminarGol @ID_Gol = @id_del;
        SET @i_del += 1;
    END;

    DECLARE @t_sust_del TABLE (fila INT IDENTITY(1,1), id_reg INT);
    INSERT INTO @t_sust_del (id_reg)
    SELECT s.ID FROM partido.Sustitucion s JOIN partido.Partido p ON p.ID = s.ID_Partido JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase WHERE f.orden >= 2;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_sust_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @id_del = id_reg FROM @t_sust_del WHERE fila = @i_del;
        EXEC partido.sp_EliminarSustitucion @id_sustitucion = @id_del;
        SET @i_del += 1;
    END;

    DECLARE @t_susp_del TABLE (fila INT IDENTITY(1,1), id_reg INT);
    INSERT INTO @t_susp_del (id_reg)
    SELECT su.ID FROM partido.Suspension su JOIN partido.Partido p ON p.ID = su.ID_Partido JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase WHERE f.orden >= 2;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_susp_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @id_del = id_reg FROM @t_susp_del WHERE fila = @i_del;
        EXEC partido.sp_EliminarSuspension @ID_Suspension = @id_del;
        SET @i_del += 1;
    END;

    DECLARE @t_tarj_del TABLE (fila INT IDENTITY(1,1), id_reg INT);
    INSERT INTO @t_tarj_del (id_reg)
    SELECT t.ID FROM partido.Tarjeta t JOIN partido.Partido p ON p.ID = t.ID_Partido JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase WHERE f.orden >= 2;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_tarj_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @id_del = id_reg FROM @t_tarj_del WHERE fila = @i_del;
        EXEC partido.sp_EliminarTarjeta @ID_Tarjeta = @id_del;
        SET @i_del += 1;
    END;

    DECLARE @del_p INT, @del_s INT;
    DECLARE @t_form_del TABLE (fila INT IDENTITY(1,1), id_p INT, id_s INT);
    INSERT INTO @t_form_del (id_p, id_s)
    SELECT fp.ID_Partido, fp.ID_Seleccion FROM partido.Formacion_Partido fp JOIN partido.Partido p ON p.ID = fp.ID_Partido JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase WHERE f.orden >= 2;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_form_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @del_p = id_p, @del_s = id_s FROM @t_form_del WHERE fila = @i_del;
        EXEC partido.sp_EliminarFormacion @id_partido = @del_p, @id_seleccion = @del_s;
        SET @i_del += 1;
    END;

    DECLARE @del_a INT;
    DECLARE @t_arb_del TABLE (fila INT IDENTITY(1,1), id_p INT, id_a INT);
    INSERT INTO @t_arb_del (id_p, id_a)
    SELECT da.ID_Partido, da.ID_Arbitro FROM arbitraje.Designacion_Arbitral da JOIN partido.Partido p ON p.ID = da.ID_Partido JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase WHERE f.orden >= 2;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_arb_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @del_p = id_p, @del_a = id_a FROM @t_arb_del WHERE fila = @i_del;
        EXEC arbitraje.sp_EliminarDesignacionArbitro @ID_Partido = @del_p, @ID_Arbitro = @del_a;
        SET @i_del += 1;
    END;
END;
GO



-- =========================================================================
-- VARIABLES DE FASES, SEDES Y SELECCIONES
-- =========================================================================
DECLARE @fase_16vos   INT = (SELECT ID FROM administracion.Fase_Torneo WHERE nombre = 'Dieciseisavos de Final');
DECLARE @fase_octavos INT = (SELECT ID FROM administracion.Fase_Torneo WHERE nombre = 'Octavos de Final');
DECLARE @fase_cuartos INT = (SELECT ID FROM administracion.Fase_Torneo WHERE nombre = 'Cuartos de Final');
DECLARE @fase_semi    INT = (SELECT ID FROM administracion.Fase_Torneo WHERE nombre = 'Semifinal');
DECLARE @fase_tercer  INT = (SELECT ID FROM administracion.Fase_Torneo WHERE nombre = 'Tercer Puesto');
DECLARE @fase_final   INT = (SELECT ID FROM administracion.Fase_Torneo WHERE nombre = 'Final');

DECLARE @sede_azteca   INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'Estadio Azteca');
DECLARE @sede_hardrock INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'Hard Rock Stadium');
DECLARE @sede_metlife  INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'MetLife Stadium');
DECLARE @sede_att      INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'AT&T Stadium');
DECLARE @sede_sofi     INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'SoFi Stadium');

DECLARE @sel_arg INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'ARG');
DECLARE @sel_mex INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'MEX');
DECLARE @sel_bra INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'BRA');
DECLARE @sel_uru INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'URY');
DECLARE @sel_eng INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'ENG');
DECLARE @sel_ger INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'DEU');
DECLARE @sel_ned INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'NLD');
DECLARE @sel_esp INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'ESP');
DECLARE @sel_fra INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'FRA');
DECLARE @sel_por INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'PRT');

DECLARE @id_partido INT, @id_arb_principal INT, @j1 INT, @j2 INT;

-- =========================================================================
-- PARTIDO 17: ARGENTINA vs MÉXICO (03/07/2026)
-- =========================================================================
PRINT 'Partido 17 (Dieciseisavos): Argentina vs México...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_16vos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_mex)
    EXEC partido.sp_CrearPartido @id_sede = @sede_azteca, @id_fase = @fase_16vos, @fecha_hora_local = '2026-07-03 16:00:00', @id_local = @sel_arg, @id_visitante = @sel_mex;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_16vos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_mex;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
-- Romero (#13 ARG) vuelve a firmar planilla (26 jugadores) tras haber cumplido su fecha contra Austria
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_arg, @esquema = '4-3-3', @dorsales_titulares = '23,4,13,19,3,7,5,20,10,9,22,6';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_mex, @esquema = '4-2-3-1';

-- Goles: #10 ARG, #9 MEX y #9 ARG
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 10 AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 20 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_arg, @Minuto = 37, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_mex AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_mex, @Minuto = 54, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 68, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

-- Min 80: Tarjeta Roja directa a Cristian Romero (#13 ARG) por falta de último recurso -> Genera suspensión para Octavos
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 13 AND estado = 1;
EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_partido, @ID_Jugador = @j1, @Minuto = 80, @Motivo = 'Falta de último recurso', @Tipo = 'ROJA';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 86900;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Argentina 2-1 sobre México. Expulsión por tarjeta roja directa a Cristian Romero al minuto 80.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 18: BRASIL vs URUGUAY (03/07/2026)
-- =========================================================================
PRINT 'Partido 18 (Dieciseisavos): Brasil vs Uruguay...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_16vos AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_uru)
    EXEC partido.sp_CrearPartido @id_sede = @sede_hardrock, @id_fase = @fase_16vos, @fecha_hora_local = '2026-07-03 20:00:00', @id_local = @sel_bra, @id_visitante = @sel_uru;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_16vos AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_uru;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_bra, @esquema = '4-2-3-1';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_uru, @esquema = '4-3-3';

-- Goles: #9 BRA y #7 BRA
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bra, @Minuto = 40, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 7 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bra, @Minuto = 85, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 64500;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Brasil 2-0 sobre Uruguay.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 19: ARGENTINA vs INGLATERRA (07/07/2026)
-- =========================================================================
PRINT 'Partido 19 (Octavos): Argentina vs Inglaterra...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_octavos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_eng)
    EXEC partido.sp_CrearPartido @id_sede = @sede_metlife, @id_fase = @fase_octavos, @fecha_hora_local = '2026-07-07 17:00:00', @id_local = @sel_arg, @id_visitante = @sel_eng;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_octavos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_eng;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;

-- Cargar planillas (Romero #13 queda afuera por suspensión de tarjeta roja: Argentina presenta 25 jugadores y Lisandro #6 entra al 11 titular)
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_arg, @esquema = '4-3-3', @dorsales_titulares = '23,4,13,19,3,7,5,20,10,9,22,6';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_eng, @esquema = '4-2-3-1';

-- Prueba de validación: intentar alinear a Romero (#13 ARG) suspendido por tarjeta roja directa
BEGIN TRY
    DECLARE @id_form_arg19 INT = (SELECT ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido AND ID_Seleccion = @sel_arg);
    SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 13 AND estado = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_arg19, @id_jugador = @j1, @es_titular = 0;
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado (Romero suspendido por roja directa en ARG vs ENG): ' + ERROR_MESSAGE();
END CATCH;

-- Goles: #10 ARG, #9 ENG y #9 ARG
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 42, @Tipo = 'Penal', @Periodo = 'Primer Tiempo';

-- Min 60: 1ra Amarilla a Rodrigo De Paul (#7 ARG)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 7 AND estado = 1;
EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_partido, @ID_Jugador = @j1, @Minuto = 60, @Motivo = 'Falta táctica', @Tipo = 'AMARILLA';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_eng AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_eng, @Minuto = 61, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 9 AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 7 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_arg, @Minuto = 79, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

-- Cierre del partido y descuento de la fecha de suspensión cumplida por Cristian Romero (#13 ARG)
EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 82400;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Argentina 2-1 sobre Inglaterra. Cristian Romero cumplió su fecha de suspensión.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;

DECLARE @id_susp_romero19 INT = (
    SELECT TOP 1 su.ID FROM partido.Suspension su
    JOIN administracion.Convocatoria c ON c.ID_Jugador = su.ID_Jugador
    WHERE c.ID_Seleccion = @sel_arg AND c.dorsal = 13 AND su.partidos_descontados < su.partidos_totales
);
EXEC partido.sp_RegistrarCumplimientoSuspension @ID_Suspension = @id_susp_romero19, @ID_Partido_Perdido = @id_partido;


-- =========================================================================
-- PARTIDO 20: BRASIL vs ALEMANIA (07/07/2026)
-- =========================================================================
PRINT 'Partido 20 (Octavos): Brasil vs Alemania...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_octavos AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_ger)
    EXEC partido.sp_CrearPartido @id_sede = @sede_att, @id_fase = @fase_octavos, @fecha_hora_local = '2026-07-07 21:00:00', @id_local = @sel_bra, @id_visitante = @sel_ger;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_octavos AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_ger;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_bra, @esquema = '4-2-3-1';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_ger, @esquema = '4-3-3';

-- Goles: #9 BRA, #9 GER y #10 BRA
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bra, @Minuto = 35, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_ger AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_ger, @Minuto = 58, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bra, @Minuto = 73, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 79900;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Brasil 2-1 sobre Alemania.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 21: ARGENTINA vs PAÍSES BAJOS (11/07/2026)
-- Empate 2-2 en juego y definición por tanda de penales (4-3 para Argentina)
-- =========================================================================
PRINT 'Partido 21 (Cuartos): Argentina vs Países Bajos (con definición por penales)...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_cuartos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_ned)
    EXEC partido.sp_CrearPartido @id_sede = @sede_sofi, @id_fase = @fase_cuartos, @fecha_hora_local = '2026-07-11 16:00:00', @id_local = @sel_arg, @id_visitante = @sel_ned;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_cuartos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_ned;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_arg, @esquema = '4-3-3', @dorsales_titulares = '23,4,13,19,3,7,5,20,10,9,22,6';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_ned, @esquema = '3-5-2';

-- Min 35: Gol de Messi (#10 ARG) con asistencia de Mac Allister (#20 ARG) -> 1-0
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 10 AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 20 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_arg, @Minuto = 35, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

-- Min 43: Amarilla a Leandro Paredes (#5 ARG)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 5 AND estado = 1;
EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_partido, @ID_Jugador = @j1, @Minuto = 43, @Motivo = 'Discusión con rival', @Tipo = 'AMARILLA';

-- Min 73: Gol de Julián Álvarez (#9 ARG) -> 2-0
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 73, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

-- Min 75: Cambio en Argentina (Sale Gonzalo Montiel #4 titular, Entra Lisandro Martínez #6 suplente)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 4 AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 6 AND estado = 1;
EXEC partido.sp_RegistrarSustitucion @id_partido = @id_partido, @id_jugador_sale = @j1, @id_jugador_entra = @j2, @minuto = 75, @motivo = 'Táctico';

-- Min 83: Gol de #9 NED -> 2-1
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_ned AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_ned, @Minuto = 83, @Tipo = 'Cabezazo', @Periodo = 'Segundo Tiempo';

-- Min 90: Gol de #9 NED -> Empate 2-2
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_ned AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_ned, @Minuto = 90, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

-- Tanda de Definición por Penales (Argentina gana 4 a 3 por penales; el marcador del partido se mantiene 2-2)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 120, @Tipo = 'Penal', @Periodo = 'Definición por penales';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_ned AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_ned, @Minuto = 120, @Tipo = 'Penal', @Periodo = 'Definición por penales';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 7 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 120, @Tipo = 'Penal', @Periodo = 'Definición por penales';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_ned AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_ned, @Minuto = 120, @Tipo = 'Penal', @Periodo = 'Definición por penales';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 20 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 120, @Tipo = 'Penal', @Periodo = 'Definición por penales';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_ned AND dorsal = 8 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_ned, @Minuto = 120, @Tipo = 'Penal', @Periodo = 'Definición por penales';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 22 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 120, @Tipo = 'Penal', @Periodo = 'Definición por penales';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 70100;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Empate 2-2 en tiempo de juego. Clasifica Argentina 4-3 en definición por penales.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 22: BRASIL vs ESPAÑA (11/07/2026)
-- =========================================================================
PRINT 'Partido 22 (Cuartos): Brasil vs España...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_cuartos AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_esp)
    EXEC partido.sp_CrearPartido @id_sede = @sede_hardrock, @id_fase = @fase_cuartos, @fecha_hora_local = '2026-07-11 20:00:00', @id_local = @sel_bra, @id_visitante = @sel_esp;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_cuartos AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_esp;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_bra, @esquema = '4-2-3-1';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_esp, @esquema = '4-3-3';

-- Goles: #9 BRA, #10 ESP y #10 BRA
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bra, @Minuto = 25, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_esp AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_esp, @Minuto = 52, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bra, @Minuto = 69, @Tipo = 'Penal', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 64700;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Brasil 2-1 sobre España.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 23: ARGENTINA vs FRANCIA (14/07/2026)
-- =========================================================================
PRINT 'Partido 23 (Semifinal): Argentina vs Francia...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_semi AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_fra)
    EXEC partido.sp_CrearPartido @id_sede = @sede_metlife, @id_fase = @fase_semi, @fecha_hora_local = '2026-07-14 20:00:00', @id_local = @sel_arg, @id_visitante = @sel_fra;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_semi AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_fra;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_arg, @esquema = '4-3-3', @dorsales_titulares = '23,4,13,19,3,7,5,20,10,9,22,6';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_fra, @esquema = '4-2-3-1';

-- Goles: #10 ARG, #10 FRA y #9 ARG
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 31, @Tipo = 'Tiro Libre', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_fra AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_fra, @Minuto = 65, @Tipo = 'Penal', @Periodo = 'Segundo Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 9  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 20 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_arg, @Minuto = 76, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 82500;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Argentina 2-1 sobre Francia. Argentina clasifica a la Final.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 24: BRASIL vs PORTUGAL (15/07/2026)
-- =========================================================================
PRINT 'Partido 24 (Semifinal): Brasil vs Portugal...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_semi AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_por)
    EXEC partido.sp_CrearPartido @id_sede = @sede_att, @id_fase = @fase_semi, @fecha_hora_local = '2026-07-15 20:00:00', @id_local = @sel_bra, @id_visitante = @sel_por;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_semi AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_por;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_bra, @esquema = '4-2-3-1';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_por, @esquema = '4-3-3';

-- Min 60: Cambio en Brasil (Sale #9, Entra Rodrygo #25)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 9  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 25 AND estado = 1;
EXEC partido.sp_RegistrarSustitucion @id_partido = @id_partido, @id_jugador_sale = @j1, @id_jugador_entra = @j2, @minuto = 60, @motivo = 'Táctico';

-- Min 82: Gol de #7 BRA con asistencia de Rodrygo (#25 BRA)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 7  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 25 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_bra, @Minuto = 82, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 80000;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Brasil 1-0 sobre Portugal. Brasil clasifica a la Final.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 25: FRANCIA vs PORTUGAL (18/07/2026)
-- =========================================================================
PRINT 'Partido 25 (Tercer Puesto): Francia vs Portugal...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_tercer AND ID_Seleccion_Local = @sel_fra AND ID_Seleccion_Visitante = @sel_por)
    EXEC partido.sp_CrearPartido @id_sede = @sede_hardrock, @id_fase = @fase_tercer, @fecha_hora_local = '2026-07-18 17:00:00', @id_local = @sel_fra, @id_visitante = @sel_por;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_tercer AND ID_Seleccion_Local = @sel_fra AND ID_Seleccion_Visitante = @sel_por;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_fra, @esquema = '4-2-3-1';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_por, @esquema = '4-3-3';

-- Goles: #9 FRA, #9 POR y #10 FRA
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_fra AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_fra, @Minuto = 28, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_por AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_por, @Minuto = 55, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_fra AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_fra, @Minuto = 74, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 63500;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Francia 2-1 por el tercer puesto.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 26: ARGENTINA vs BRASIL (19/07/2026)
-- =========================================================================
PRINT 'Partido 26 (Final): Argentina vs Brasil...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_final AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_bra)
    EXEC partido.sp_CrearPartido @id_sede = @sede_metlife, @id_fase = @fase_final, @fecha_hora_local = '2026-07-19 16:00:00', @id_local = @sel_arg, @id_visitante = @sel_bra;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_final AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_bra;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;

-- Ambos equipos presentan sus 26 jugadores en la Final
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_arg, @esquema = '4-3-3', @dorsales_titulares = '23,4,13,19,3,7,5,20,10,9,22,6';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_bra, @esquema = '4-2-3-1';

-- Min 23: Gol de penal de Messi (#10 ARG) -> 1-0
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 23, @Tipo = 'Penal', @Periodo = 'Primer Tiempo';

-- Min 36: Gol de Julián Álvarez (#9 ARG) con asistencia de Mac Allister (#20 ARG) -> 2-0
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 9  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 20 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_arg, @Minuto = 36, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

-- Min 44: Gol de #9 BRA -> 2-1
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bra, @Minuto = 44, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

-- Min 55: Amarilla a #7 BRA
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 7 AND estado = 1;
EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_partido, @ID_Jugador = @j1, @Minuto = 55, @Motivo = 'Reclamo al árbitro', @Tipo = 'AMARILLA';

-- Min 61: Gol de tiro libre de #10 BRA -> 2-2
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bra, @Minuto = 61, @Tipo = 'Tiro Libre', @Periodo = 'Segundo Tiempo';

-- Min 65: Cambio en Brasil (Sale #9, Entra Rodrygo #25)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 9  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 25 AND estado = 1;
EXEC partido.sp_RegistrarSustitucion @id_partido = @id_partido, @id_jugador_sale = @j1, @id_jugador_entra = @j2, @minuto = 65, @motivo = 'Táctico';

-- Min 68: Cambio en Argentina (Sale Julián Álvarez #9, Entra Ángel Di María #15)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 9  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 15 AND estado = 1;
EXEC partido.sp_RegistrarSustitucion @id_partido = @id_partido, @id_jugador_sale = @j1, @id_jugador_entra = @j2, @minuto = 68, @motivo = 'Táctico';

-- Min 78: Gol de Ángel Di María (#15 ARG, recién ingresado) con asistencia de Messi (#10 ARG) -> 3-2
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 15 AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_arg, @Minuto = 78, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

-- Min 82: Cambio en Argentina (Sale Leandro Paredes #5, Entra Enzo Fernández #24)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 5  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 24 AND estado = 1;
EXEC partido.sp_RegistrarSustitucion @id_partido = @id_partido, @id_jugador_sale = @j1, @id_jugador_entra = @j2, @minuto = 82, @motivo = 'Táctico';

-- Min 85: 2da amarilla del torneo a De Paul (#7 ARG) -> Queda con suspensión activa por acumulación al terminar el Mundial
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 7 AND estado = 1;
EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_partido, @ID_Jugador = @j1, @Minuto = 85, @Motivo = 'Cortar avance rival', @Tipo = 'AMARILLA';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 82500;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Final del torneo: Argentina 3 - Brasil 2. Ambos equipos con plantel completo.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;

-- Pruebas de validación de publicidad sobre el último partido
BEGIN TRY
    EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado (doble asignación de publicidad): ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    DECLARE @id_pieza_fact INT = (SELECT TOP 1 ID_Pieza FROM publicidad.Exhibicion);
    EXEC publicidad.sp_EliminarPiezaContenido @id = @id_pieza_fact;
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado (eliminar pieza ya facturada): ' + ERROR_MESSAGE();
END CATCH;

-- =========================================================================
-- RESUMEN FINAL DEL TORNEO
-- =========================================================================
SELECT 
    (SELECT COUNT(*) FROM partido.Partido)                                                                       AS total_partidos,
    (SELECT COUNT(*) FROM partido.Formacion_Partido)                                                             AS total_formaciones,
    (SELECT COUNT(*) FROM partido.Alineacion)                                                                    AS total_alineaciones,
    (SELECT COUNT(*) FROM partido.Sustitucion)                                                                   AS total_cambios,
    (SELECT COUNT(*) FROM partido.Gol WHERE periodo <> 'Definición por penales')                                 AS goles_en_juego,
    (SELECT COUNT(*) FROM partido.Gol WHERE periodo = 'Definición por penales')                                  AS goles_tanda_penales,
    (SELECT COUNT(*) FROM partido.Tarjeta)                                                                       AS total_tarjetas,
    (SELECT COUNT(*) FROM partido.Suspension)                                                                    AS total_suspensiones,
    (SELECT COUNT(*) FROM partido.Partido_Perdido_Suspension)                                                    AS suspensiones_cumplidas,
    (SELECT COUNT(*) FROM publicidad.Exhibicion)                                                                 AS paneles_publicidad_facturados;

PRINT 'Script 04 finalizado (Torneo completo).';
GO
