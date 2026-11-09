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

   Script: 03_partidos_fase_grupos.sql
   Descripción: Desarrollo partido a partido de los 16 encuentros de Fase de Grupos
                (Partido 1 al Partido 16).
*/

USE Mundial2026;
GO

SET NOCOUNT ON;
GO

PRINT 'Iniciando Script 03: Partidos de Fase de Grupos (1 al 16)...';

-- Limpiar datos previos de partidos si se vuelve a correr desde cero
IF EXISTS (SELECT 1 FROM partido.Formacion_Partido)
   OR EXISTS (SELECT 1 FROM partido.Gol)
   OR EXISTS (SELECT 1 FROM partido.Tarjeta)
BEGIN
    DECLARE @id_del INT, @i_del INT, @max_del INT;

    DECLARE @t_exh_del TABLE (fila INT IDENTITY(1,1), id_p INT);
    INSERT INTO @t_exh_del (id_p)
    SELECT DISTINCT ep.ID_Partido FROM publicidad.Exhibicion ex JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_exh_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @id_del = id_p FROM @t_exh_del WHERE fila = @i_del;
        EXEC publicidad.sp_EliminarExhibicionPartido @id_partido = @id_del;
        SET @i_del += 1;
    END;

    DECLARE @t_goles_del TABLE (fila INT IDENTITY(1,1), id_reg INT);
    INSERT INTO @t_goles_del (id_reg) SELECT ID FROM partido.Gol;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_goles_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @id_del = id_reg FROM @t_goles_del WHERE fila = @i_del;
        EXEC partido.sp_EliminarGol @ID_Gol = @id_del;
        SET @i_del += 1;
    END;

    DECLARE @t_sust_del TABLE (fila INT IDENTITY(1,1), id_reg INT);
    INSERT INTO @t_sust_del (id_reg) SELECT ID FROM partido.Sustitucion;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_sust_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @id_del = id_reg FROM @t_sust_del WHERE fila = @i_del;
        EXEC partido.sp_EliminarSustitucion @id_sustitucion = @id_del;
        SET @i_del += 1;
    END;

    DECLARE @t_susp_del TABLE (fila INT IDENTITY(1,1), id_reg INT);
    INSERT INTO @t_susp_del (id_reg) SELECT ID FROM partido.Suspension;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_susp_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @id_del = id_reg FROM @t_susp_del WHERE fila = @i_del;
        EXEC partido.sp_EliminarSuspension @ID_Suspension = @id_del;
        SET @i_del += 1;
    END;

    DECLARE @t_tarj_del TABLE (fila INT IDENTITY(1,1), id_reg INT);
    INSERT INTO @t_tarj_del (id_reg) SELECT ID FROM partido.Tarjeta;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_tarj_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @id_del = id_reg FROM @t_tarj_del WHERE fila = @i_del;
        EXEC partido.sp_EliminarTarjeta @ID_Tarjeta = @id_del;
        SET @i_del += 1;
    END;

    DECLARE @del_p INT, @del_s INT;
    DECLARE @t_form_del TABLE (fila INT IDENTITY(1,1), id_p INT, id_s INT);
    INSERT INTO @t_form_del (id_p, id_s) SELECT ID_Partido, ID_Seleccion FROM partido.Formacion_Partido;
    SET @i_del = 1; SET @max_del = (SELECT ISNULL(MAX(fila), 0) FROM @t_form_del);
    WHILE @i_del <= @max_del
    BEGIN
        SELECT @del_p = id_p, @del_s = id_s FROM @t_form_del WHERE fila = @i_del;
        EXEC partido.sp_EliminarFormacion @id_partido = @del_p, @id_seleccion = @del_s;
        SET @i_del += 1;
    END;

    DECLARE @del_a INT;
    DECLARE @t_arb_del TABLE (fila INT IDENTITY(1,1), id_p INT, id_a INT);
    INSERT INTO @t_arb_del (id_p, id_a) SELECT ID_Partido, ID_Arbitro FROM arbitraje.Designacion_Arbitral;
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
-- VARIABLES DE FASE, SEDES Y SELECCIONES
-- =========================================================================
DECLARE @fase_grupos INT = (SELECT ID FROM administracion.Fase_Torneo WHERE nombre = 'Fase de Grupos');

DECLARE @sede_azteca   INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'Estadio Azteca');
DECLARE @sede_bmo      INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'BMO Field');
DECLARE @sede_hardrock INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'Hard Rock Stadium');
DECLARE @sede_metlife  INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'MetLife Stadium');
DECLARE @sede_att      INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'AT&T Stadium');
DECLARE @sede_sofi     INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'SoFi Stadium');
DECLARE @sede_bcplace  INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'BC Place');
DECLARE @sede_akron    INT = (SELECT ID FROM administracion.Sede WHERE nombre = 'Estadio Akron');

DECLARE @sel_mex INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'MEX');
DECLARE @sel_rsa INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'ZAF');
DECLARE @sel_arg INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'ARG');
DECLARE @sel_can INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'CAN');
DECLARE @sel_aut INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'AUT');
DECLARE @sel_nzl INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'NZL');
DECLARE @sel_usa INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'USA');
DECLARE @sel_fra INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'FRA');
DECLARE @sel_bra INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'BRA');
DECLARE @sel_esp INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'ESP');
DECLARE @sel_jpn INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'JPN');
DECLARE @sel_ger INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'DEU');
DECLARE @sel_col INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'COL');
DECLARE @sel_eng INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'ENG');
DECLARE @sel_uru INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'URY');
DECLARE @sel_por INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'PRT');
DECLARE @sel_par INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'PRY');
DECLARE @sel_ned INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'NLD');
DECLARE @sel_ecu INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'ECU');
DECLARE @sel_bel INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'BEL');
DECLARE @sel_cro INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'HRV');
DECLARE @sel_sco INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'SCO');
DECLARE @sel_sui INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'CHE');
DECLARE @sel_tur INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'TUR');
DECLARE @sel_pan INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'PAN');
DECLARE @sel_swe INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'SWE');
DECLARE @sel_nor INT = (SELECT s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.codigo_iso = 'NOR');

DECLARE @id_partido INT, @id_arb_principal INT, @j1 INT, @j2 INT;

-- =========================================================================
-- PARTIDO 1: MÉXICO vs SUDÁFRICA (11/06/2026)
-- =========================================================================
PRINT 'Partido 1: México vs Sudáfrica...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_mex AND ID_Seleccion_Visitante = @sel_rsa)
    EXEC partido.sp_CrearPartido @id_sede = @sede_azteca, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-11 15:00:00', @id_local = @sel_mex, @id_visitante = @sel_rsa;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_mex AND ID_Seleccion_Visitante = @sel_rsa;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_mex, @esquema = '4-3-3';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_rsa, @esquema = '4-4-2';

-- Goles: #9 MEX (dos goles) y #9 RSA (un gol)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_mex AND dorsal = 9  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_mex AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_mex, @Minuto = 25, @Tipo = 'Cabezazo', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_rsa AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_rsa, @Minuto = 54, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_mex AND dorsal = 9 AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_mex AND dorsal = 7 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_mex, @Minuto = 67, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_mex AND dorsal = 4 AND estado = 1;
EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_partido, @ID_Jugador = @j1, @Minuto = 74, @Motivo = 'Sujeción de camiseta', @Tipo = 'AMARILLA';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 83500;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Partido inaugural finalizado 2-1. Desarrollo normal.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 2: ARGENTINA vs CANADÁ (12/06/2026)
-- =========================================================================
PRINT 'Partido 2: Argentina vs Canadá...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_can)
    EXEC partido.sp_CrearPartido @id_sede = @sede_bmo, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-12 18:00:00', @id_local = @sel_arg, @id_visitante = @sel_can;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_can;

-- Prueba de validación: intentar designar un árbitro argentino en un partido de Argentina
BEGIN TRY
    DECLARE @id_arb_arg INT = (SELECT TOP 1 a.ID FROM arbitraje.Arbitro a JOIN administracion.Pais p ON p.ID = a.ID_Pais WHERE p.codigo_iso = 'ARG');
    EXEC arbitraje.sp_DesignarArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_arg, @Rol = 'Árbitro Principal', @Informe = NULL;
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado (árbitro misma nacionalidad): ' + ERROR_MESSAGE();
END CATCH;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_arg, @esquema = '4-3-3', @dorsales_titulares = '23,4,13,19,3,7,5,20,10,9,22,6';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_can, @esquema = '4-2-3-1';

-- Min 14: Cambio por lesión antes de los 20 minutos (Sale Tagliafico #3 titular, Entra Medina #25 suplente)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 3  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 25 AND estado = 1;
EXEC partido.sp_RegistrarSustitucion @id_partido = @id_partido, @id_jugador_sale = @j1, @id_jugador_entra = @j2, @minuto = 14, @motivo = 'Lesión';

-- Min 27: 1ra Amarilla a Cristian Romero (#13 ARG)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 13 AND estado = 1;
EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_partido, @ID_Jugador = @j1, @Minuto = 27, @Motivo = 'Falta táctica en mitad de cancha', @Tipo = 'AMARILLA';

-- Min 35: 1ra Amarilla a Nicolás Otamendi (#19 ARG)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 19 AND estado = 1;
EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_partido, @ID_Jugador = @j1, @Minuto = 35, @Motivo = 'Discusión con rival', @Tipo = 'AMARILLA';

-- Min 38: Gol en contra de Canadá (#4 CAN) a favor de Argentina
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_can AND dorsal = 4 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 38, @Tipo = 'En contra', @Periodo = 'Primer Tiempo';

-- Min 70: 2da Amarilla y expulsión por DOBLE AMARILLA a Nicolás Otamendi (#19 ARG)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 19 AND estado = 1;
EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_partido, @ID_Jugador = @j1, @Minuto = 70, @Motivo = 'Infracción reiterada', @Tipo = 'AMARILLA', @Es_Doble_Amarilla = 1;

-- Min 73: Gol de Julián Álvarez (#9 ARG) con asistencia de Alexis Mac Allister (#20 ARG)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 9  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 20 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_arg, @Minuto = 73, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 44800;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Argentina 2-0. Cambio por lesión de Tagliafico al minuto 14. Expulsado Otamendi por doble amarilla al minuto 70.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 3: AUSTRIA vs NUEVA ZELANDA (13/06/2026)
-- =========================================================================
PRINT 'Partido 3: Austria vs Nueva Zelanda...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_aut AND ID_Seleccion_Visitante = @sel_nzl)
    EXEC partido.sp_CrearPartido @id_sede = @sede_bmo, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-13 14:00:00', @id_local = @sel_aut, @id_visitante = @sel_nzl;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_aut AND ID_Seleccion_Visitante = @sel_nzl;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_aut, @esquema = '4-2-3-1';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_nzl, @esquema = '4-4-2';

-- Gol: #9 AUT
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_aut AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_aut, @Minuto = 44, @Tipo = 'Tiro Libre', @Periodo = 'Primer Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 41200;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Austria 1-0 sin incidentes.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 4: ESTADOS UNIDOS vs FRANCIA (14/06/2026)
-- =========================================================================
PRINT 'Partido 4: Estados Unidos vs Francia...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_usa AND ID_Seleccion_Visitante = @sel_fra)
    EXEC partido.sp_CrearPartido @id_sede = @sede_hardrock, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-14 20:00:00', @id_local = @sel_usa, @id_visitante = @sel_fra;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_usa AND ID_Seleccion_Visitante = @sel_fra;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_usa, @esquema = '4-3-3';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_fra, @esquema = '4-2-3-1';

-- Goles: #10 USA, #10 FRA y #9 FRA
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_usa AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_usa, @Minuto = 15, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_fra AND dorsal = 10 AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_fra AND dorsal = 7  AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_fra, @Minuto = 33, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_fra AND dorsal = 9  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_fra AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_fra, @Minuto = 81, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 64100;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Francia 2-1. Desarrollo normal.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 5: BRASIL vs ESPAÑA (15/06/2026)
-- =========================================================================
PRINT 'Partido 5: Brasil vs España...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_esp)
    EXEC partido.sp_CrearPartido @id_sede = @sede_metlife, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-15 21:00:00', @id_local = @sel_bra, @id_visitante = @sel_esp;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_esp;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_bra, @esquema = '4-2-3-1';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_esp, @esquema = '4-3-3';

-- Goles: #9 BRA, #9 ESP y #10 BRA
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 9 AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 8 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_bra, @Minuto = 29, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_esp AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_esp, @Minuto = 41, @Tipo = 'Cabezazo', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bra, @Minuto = 76, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 81900;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Brasil 2-1 sobre España.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 6: ALEMANIA vs COLOMBIA (16/06/2026)
-- =========================================================================
PRINT 'Partido 6: Alemania vs Colombia...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_ger AND ID_Seleccion_Visitante = @sel_col)
    EXEC partido.sp_CrearPartido @id_sede = @sede_att, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-16 17:00:00', @id_local = @sel_ger, @id_visitante = @sel_col;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_ger AND ID_Seleccion_Visitante = @sel_col;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_ger, @esquema = '4-2-3-1';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_col, @esquema = '4-3-3';

-- Goles: #9 GER y #10 GER
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_ger AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_ger, @Minuto = 35, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_ger AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_ger, @Minuto = 62, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 78500;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Alemania 2-0.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 7: INGLATERRA vs URUGUAY (17/06/2026)
-- =========================================================================
PRINT 'Partido 7: Inglaterra vs Uruguay...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_eng AND ID_Seleccion_Visitante = @sel_uru)
    EXEC partido.sp_CrearPartido @id_sede = @sede_sofi, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-17 19:00:00', @id_local = @sel_eng, @id_visitante = @sel_uru;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_eng AND ID_Seleccion_Visitante = @sel_uru;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_eng, @esquema = '4-3-3';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_uru, @esquema = '4-4-2';

-- Goles: #9 ENG y #9 URU
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_eng AND dorsal = 9  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_eng AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_eng, @Minuto = 50, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_uru AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_uru, @Minuto = 78, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 69800;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Empate 1-1 sin incidentes.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 8: PORTUGAL vs PARAGUAY (18/06/2026)
-- =========================================================================
PRINT 'Partido 8: Portugal vs Paraguay...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_por AND ID_Seleccion_Visitante = @sel_par)
    EXEC partido.sp_CrearPartido @id_sede = @sede_bcplace, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-18 16:00:00', @id_local = @sel_por, @id_visitante = @sel_par;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_por AND ID_Seleccion_Visitante = @sel_par;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_por, @esquema = '4-3-3';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_par, @esquema = '4-4-2';

-- Goles: #9 POR y #7 POR
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_por AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_por, @Minuto = 32, @Tipo = 'Penal', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_por AND dorsal = 7 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_por, @Minuto = 65, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 52300;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Portugal 2-0.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 9: PAÍSES BAJOS vs ECUADOR (19/06/2026)
-- =========================================================================
PRINT 'Partido 9: Países Bajos vs Ecuador...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_ned AND ID_Seleccion_Visitante = @sel_ecu)
    EXEC partido.sp_CrearPartido @id_sede = @sede_hardrock, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-19 18:00:00', @id_local = @sel_ned, @id_visitante = @sel_ecu;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_ned AND ID_Seleccion_Visitante = @sel_ecu;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_ned, @esquema = '3-5-2';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_ecu, @esquema = '4-4-2';

-- Goles: #9 NED, #11 ECU y #10 NED
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_ned AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_ned, @Minuto = 18, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_ecu AND dorsal = 11 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_ecu, @Minuto = 49, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_ned AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_ned, @Minuto = 58, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 62400;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Países Bajos 2-1.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 10: BÉLGICA vs CROACIA (20/06/2026)
-- =========================================================================
PRINT 'Partido 10: Bélgica vs Croacia...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_bel AND ID_Seleccion_Visitante = @sel_cro)
    EXEC partido.sp_CrearPartido @id_sede = @sede_att, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-20 15:00:00', @id_local = @sel_bel, @id_visitante = @sel_cro;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_bel AND ID_Seleccion_Visitante = @sel_cro;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_bel, @esquema = '3-4-3';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_cro, @esquema = '4-3-3';

-- Goles: #9 BEL y #10 CRO
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bel AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bel, @Minuto = 22, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_cro AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_cro, @Minuto = 68, @Tipo = 'Penal', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 76800;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Empate 1-1.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 11: ESCOCIA vs SUIZA (21/06/2026)
-- =========================================================================
PRINT 'Partido 11: Escocia vs Suiza...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_sco AND ID_Seleccion_Visitante = @sel_sui)
    EXEC partido.sp_CrearPartido @id_sede = @sede_akron, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-21 20:00:00', @id_local = @sel_sco, @id_visitante = @sel_sui;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_sco AND ID_Seleccion_Visitante = @sel_sui;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_sco, @esquema = '4-4-2';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_sui, @esquema = '4-2-3-1';

-- Gol: #9 SUI
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_sui AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_sui, @Minuto = 60, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 46200;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Suiza 1-0.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 12: TURQUÍA vs PANAMÁ (22/06/2026)
-- =========================================================================
PRINT 'Partido 12: Turquía vs Panamá...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_tur AND ID_Seleccion_Visitante = @sel_pan)
    EXEC partido.sp_CrearPartido @id_sede = @sede_azteca, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-22 17:00:00', @id_local = @sel_tur, @id_visitante = @sel_pan;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_tur AND ID_Seleccion_Visitante = @sel_pan;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_tur, @esquema = '4-2-3-1';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_pan, @esquema = '5-4-1';

-- Goles: #8 TUR y #9 TUR
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_tur AND dorsal = 8 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_tur, @Minuto = 30, @Tipo = 'Tiro Libre', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_tur AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_tur, @Minuto = 75, @Tipo = 'Cabezazo', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 72100;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Turquía 2-0.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 13: SUECIA vs NORUEGA (23/06/2026)
-- =========================================================================
PRINT 'Partido 13: Suecia vs Noruega...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_swe AND ID_Seleccion_Visitante = @sel_nor)
    EXEC partido.sp_CrearPartido @id_sede = @sede_sofi, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-23 18:00:00', @id_local = @sel_swe, @id_visitante = @sel_nor;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_swe AND ID_Seleccion_Visitante = @sel_nor;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_swe, @esquema = '4-4-2';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_nor, @esquema = '4-3-3';

-- Gol: #9 SWE
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_swe AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_swe, @Minuto = 52, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 65400;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Suecia 1-0.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 14: ARGENTINA vs NUEVA ZELANDA (24/06/2026)
-- =========================================================================
PRINT 'Partido 14: Argentina vs Nueva Zelanda...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_nzl)
    EXEC partido.sp_CrearPartido @id_sede = @sede_metlife, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-24 20:00:00', @id_local = @sel_arg, @id_visitante = @sel_nzl;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_nzl;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;

-- Cargar planillas (Otamendi #19 queda afuera por suspensión de doble amarilla: Argentina presenta 25 jugadores y Lisandro #6 entra al 11 titular)
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_arg, @esquema = '4-3-3', @dorsales_titulares = '23,4,13,19,3,7,5,20,10,9,22,6';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_nzl, @esquema = '5-4-1';

-- Prueba de validación: intentar alinear a Otamendi (#19 ARG) estando suspendido
BEGIN TRY
    DECLARE @id_form_arg14 INT = (SELECT ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido AND ID_Seleccion = @sel_arg);
    SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 19 AND estado = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_arg14, @id_jugador = @j1, @es_titular = 0;
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado (Otamendi suspendido por doble amarilla en ARG vs NZL): ' + ERROR_MESSAGE();
END CATCH;

-- Min 28: Gol de penal de Messi (#10 ARG)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 28, @Tipo = 'Penal', @Periodo = 'Primer Tiempo';

-- Min 58: Gol de tiro libre de Messi (#10 ARG)
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_arg, @Minuto = 58, @Tipo = 'Tiro Libre', @Periodo = 'Segundo Tiempo';

-- Ventana 1 de cambios (minuto 60): Sale Rodrigo De Paul (#7 titular), Entra Exequiel Palacios (#14 suplente)
DECLARE @s_arg_sale1 INT = (SELECT ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 7  AND estado = 1);
DECLARE @s_arg_entr1 INT = (SELECT ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 14 AND estado = 1);
EXEC partido.sp_RegistrarSustitucion @id_partido = @id_partido, @id_jugador_sale = @s_arg_sale1, @id_jugador_entra = @s_arg_entr1, @minuto = 60, @motivo = 'Táctico';

-- Min 64: 2da Amarilla del torneo a Cristian Romero (#13 ARG) -> Suspensión automática por acumulación para el partido vs Austria
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 13 AND estado = 1;
EXEC partido.sp_RegistrarTarjetaYSuspension @ID_Partido = @id_partido, @ID_Jugador = @j1, @Minuto = 64, @Motivo = 'Falta táctica', @Tipo = 'AMARILLA';

-- Ventana 2 de cambios (minuto 72): Sale Alexis Mac Allister (#20 titular), Entra Ángel Di María (#15 suplente)
DECLARE @s_arg_sale2 INT = (SELECT ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 20 AND estado = 1);
DECLARE @s_arg_entr2 INT = (SELECT ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 15 AND estado = 1);
EXEC partido.sp_RegistrarSustitucion @id_partido = @id_partido, @id_jugador_sale = @s_arg_sale2, @id_jugador_entra = @s_arg_entr2, @minuto = 72, @motivo = 'Táctico';

-- Ventana 3 de cambios (minuto 80): Sale Lautaro Martínez (#22 titular), Entra Thiago Almada (#16 suplente) (3ra y última ventana en juego)
DECLARE @s_arg_sale3 INT = (SELECT ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 22 AND estado = 1);
DECLARE @s_arg_entr3 INT = (SELECT ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 16 AND estado = 1);
EXEC partido.sp_RegistrarSustitucion @id_partido = @id_partido, @id_jugador_sale = @s_arg_sale3, @id_jugador_entra = @s_arg_entr3, @minuto = 80, @motivo = 'Cansancio';

-- Prueba de validación: intento de 4ta ventana en tiempo regular (minuto 86) -> debe fallar con error 50037
BEGIN TRY
    DECLARE @s_arg_sale4 INT = (SELECT ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 5  AND estado = 1);
    DECLARE @s_arg_entr4 INT = (SELECT ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 24 AND estado = 1);
    EXEC partido.sp_RegistrarSustitucion @id_partido = @id_partido, @id_jugador_sale = @s_arg_sale4, @id_jugador_entra = @s_arg_entr4, @minuto = 86, @motivo = 'Intento de 4ta ventana';
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado (4ta ventana no permitida en ARG vs NZL): ' + ERROR_MESSAGE();
END CATCH;

-- Min 84: Gol de Julián Álvarez (#9 ARG) con asistencia de Di María (#15 ARG, recién ingresado)
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 9  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 15 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_arg, @Minuto = 84, @Tipo = 'Cabezazo', @Periodo = 'Segundo Tiempo';

-- Cierre del partido y descuento de la fecha de suspensión cumplida por Nicolás Otamendi (#19 ARG)
EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 82000;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Argentina 3-0. Otamendi cumplió fecha de suspensión. Amonestado Romero al minuto 64 (acumula 2 amarillas).';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;

DECLARE @id_susp_otamendi INT = (
    SELECT TOP 1 su.ID FROM partido.Suspension su
    JOIN administracion.Convocatoria c ON c.ID_Jugador = su.ID_Jugador
    WHERE c.ID_Seleccion = @sel_arg AND c.dorsal = 19 AND su.partidos_descontados < su.partidos_totales
);
EXEC partido.sp_RegistrarCumplimientoSuspension @ID_Suspension = @id_susp_otamendi, @ID_Partido_Perdido = @id_partido;


-- =========================================================================
-- PARTIDO 15: BRASIL vs JAPÓN (25/06/2026)
-- =========================================================================
PRINT 'Partido 15: Brasil vs Japón...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_jpn)
    EXEC partido.sp_CrearPartido @id_sede = @sede_hardrock, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-25 19:00:00', @id_local = @sel_bra, @id_visitante = @sel_jpn;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_bra AND ID_Seleccion_Visitante = @sel_jpn;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_bra, @esquema = '4-2-3-1';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_jpn, @esquema = '4-4-2';

-- Goles: #9 BRA, #10 BRA y #9 JPN
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bra, @Minuto = 22, @Tipo = 'Penal', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_bra AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_bra, @Minuto = 44, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_jpn AND dorsal = 9 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = NULL, @ID_Seleccion = @sel_jpn, @Minuto = 60, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 63900;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Brasil 2-1 sobre Japón.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;


-- =========================================================================
-- PARTIDO 16: ARGENTINA vs AUSTRIA (29/06/2026)
-- =========================================================================
PRINT 'Partido 16: Argentina vs Austria...';

IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_aut)
    EXEC partido.sp_CrearPartido @id_sede = @sede_att, @id_fase = @fase_grupos, @fecha_hora_local = '2026-06-29 21:00:00', @id_local = @sel_arg, @id_visitante = @sel_aut;
SELECT @id_partido = ID FROM partido.Partido WHERE ID_Fase = @fase_grupos AND ID_Seleccion_Local = @sel_arg AND ID_Seleccion_Visitante = @sel_aut;

EXEC arbitraje.sp_AuxDesignarArbitrosPartido @id_partido = @id_partido, @id_arbitro_principal = @id_arb_principal OUTPUT;

-- Cargar planillas (Romero #13 queda afuera automáticamente por estar suspendido: Argentina presenta 25 jugadores y Lisandro #6 entra al 11 titular)
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_arg, @esquema = '4-3-3', @dorsales_titulares = '23,4,13,19,3,7,5,20,10,9,22,6';
EXEC partido.sp_AuxCargarPlanillaEquipo @id_partido = @id_partido, @id_seleccion = @sel_aut, @esquema = '4-2-3-1';

-- Prueba de validación: intentar alinear a Romero (#13 ARG) estando suspendido
BEGIN TRY
    DECLARE @id_form_arg INT = (SELECT ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido AND ID_Seleccion = @sel_arg);
    SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 13 AND estado = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_arg, @id_jugador = @j1, @es_titular = 0;
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado (Romero suspendido en ARG vs AUT): ' + ERROR_MESSAGE();
END CATCH;

-- Goles: #9 ARG y #22 ARG
SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 9  AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 20 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_arg, @Minuto = 34, @Tipo = 'Jugada', @Periodo = 'Primer Tiempo';

SELECT @j1 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 22 AND estado = 1;
SELECT @j2 = ID_Jugador FROM administracion.Convocatoria WHERE ID_Seleccion = @sel_arg AND dorsal = 10 AND estado = 1;
EXEC partido.sp_RegistrarGol @ID_Partido = @id_partido, @ID_Jugador_autor = @j1, @ID_Jugador_asistencia = @j2, @ID_Seleccion = @sel_arg, @Minuto = 82, @Tipo = 'Jugada', @Periodo = 'Segundo Tiempo';

-- Cierre del partido y descuento de la fecha de suspensión cumplida por Romero (#13 ARG)
EXEC partido.sp_RegistrarAsistenciaPublico @id_partido = @id_partido, @asistencia_publico = 79200;
EXEC arbitraje.sp_ModificarDesignacionArbitro @ID_Partido = @id_partido, @ID_Arbitro = @id_arb_principal, @Rol = 'Árbitro Principal', @Informe = 'Victoria de Argentina 2-0. Cristian Romero cumplió su fecha de suspensión.';
EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_partido;

DECLARE @id_susp_romero INT = (
    SELECT TOP 1 su.ID FROM partido.Suspension su
    JOIN administracion.Convocatoria c ON c.ID_Jugador = su.ID_Jugador
    WHERE c.ID_Seleccion = @sel_arg AND c.dorsal = 13 AND su.partidos_descontados < su.partidos_totales
);
EXEC partido.sp_RegistrarCumplimientoSuspension @ID_Suspension = @id_susp_romero, @ID_Partido_Perdido = @id_partido;

PRINT 'Script 03 finalizado (16 partidos de Fase de Grupos completados).';
GO
