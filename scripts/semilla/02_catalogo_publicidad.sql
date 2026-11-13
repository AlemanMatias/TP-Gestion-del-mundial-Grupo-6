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

   Script: 02_catalogo_publicidad.sql
   Descripción: Carga previa de anunciantes, campañas, piezas publicitarias y países de interés.
                (La asignación y facturación de publicidad se realiza partido a partido en los scripts 03 y 04).
*/

USE Mundial2026;
GO

SET NOCOUNT ON;
GO

PRINT 'Iniciando Script 02: Catálogo de Publicidad...';

-- Limpiar datos previos de publicidad si se vuelve a ejecutar el script
CREATE TABLE #partidos_con_exh (orden INT IDENTITY(1,1) PRIMARY KEY, id_partido INT);
INSERT INTO #partidos_con_exh (id_partido)
SELECT DISTINCT ep.ID_Partido
FROM publicidad.Exhibicion ex
JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio;

DECLARE @idx_cl INT = 1, @max_cl INT = (SELECT ISNULL(MAX(orden), 0) FROM #partidos_con_exh);
DECLARE @id_part_cl INT;
WHILE @idx_cl <= @max_cl
BEGIN
    SELECT @id_part_cl = id_partido FROM #partidos_con_exh WHERE orden = @idx_cl;
    EXEC publicidad.sp_EliminarExhibicionPartido @id_partido = @id_part_cl;
    SET @idx_cl += 1;
END;
DROP TABLE #partidos_con_exh;

CREATE TABLE #piezas_prev (orden INT IDENTITY(1,1) PRIMARY KEY, id_pieza INT);
INSERT INTO #piezas_prev (id_pieza) SELECT ID FROM publicidad.Pieza_Contenido ORDER BY ID DESC;
SET @idx_cl = 1;
SET @max_cl = (SELECT ISNULL(MAX(orden), 0) FROM #piezas_prev);
DECLARE @id_pieza_cl INT;
WHILE @idx_cl <= @max_cl
BEGIN
    SELECT @id_pieza_cl = id_pieza FROM #piezas_prev WHERE orden = @idx_cl;
    EXEC publicidad.sp_EliminarPiezaContenido @id = @id_pieza_cl;
    SET @idx_cl += 1;
END;
DROP TABLE #piezas_prev;

CREATE TABLE #camp_prev (orden INT IDENTITY(1,1) PRIMARY KEY, id_camp INT);
INSERT INTO #camp_prev (id_camp) SELECT ID FROM publicidad.Campania ORDER BY ID DESC;
SET @idx_cl = 1;
SET @max_cl = (SELECT ISNULL(MAX(orden), 0) FROM #camp_prev);
DECLARE @id_camp_cl INT;
WHILE @idx_cl <= @max_cl
BEGIN
    SELECT @id_camp_cl = id_camp FROM #camp_prev WHERE orden = @idx_cl;
    EXEC publicidad.sp_EliminarCampania @id = @id_camp_cl;
    SET @idx_cl += 1;
END;
DROP TABLE #camp_prev;

CREATE TABLE #anun_prev (orden INT IDENTITY(1,1) PRIMARY KEY, id_anun INT);
INSERT INTO #anun_prev (id_anun) SELECT ID FROM publicidad.Anunciante ORDER BY ID DESC;
SET @idx_cl = 1;
SET @max_cl = (SELECT ISNULL(MAX(orden), 0) FROM #anun_prev);
DECLARE @id_anun_cl INT;
WHILE @idx_cl <= @max_cl
BEGIN
    SELECT @id_anun_cl = id_anun FROM #anun_prev WHERE orden = @idx_cl;
    EXEC publicidad.sp_EliminarAnunciante @id = @id_anun_cl;
    SET @idx_cl += 1;
END;
DROP TABLE #anun_prev;

-- =========================================================================
-- 1. ANUNCIANTES
-- =========================================================================
PRINT '1. Cargando anunciantes...';

DECLARE @id_anun_adidas    INT, @id_anun_cocacola INT, @id_anun_visa    INT, @id_anun_meli  INT, @id_anun_qatar INT;
DECLARE @id_anun_sony      INT, @id_anun_itau     INT, @id_anun_hyundai INT, @id_anun_rolex INT, @id_anun_bud   INT;

EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Adidas',                  @id_generado = @id_anun_adidas OUTPUT;
EXEC publicidad.sp_RegistrarAnunciante @nombre = 'The Coca-Cola Company',   @id_generado = @id_anun_cocacola OUTPUT;
EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Visa Inc.',               @id_generado = @id_anun_visa OUTPUT;
EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Mercado Libre',           @id_generado = @id_anun_meli OUTPUT;
EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Qatar Airways',           @id_generado = @id_anun_qatar OUTPUT;
EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Sony Corporation',        @id_generado = @id_anun_sony OUTPUT;
EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Banco Itaú',              @id_generado = @id_anun_itau OUTPUT;
EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Hyundai Motor Company',   @id_generado = @id_anun_hyundai OUTPUT;
EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Rolex SA',                @id_generado = @id_anun_rolex OUTPUT;
EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Budweiser (AB InBev)',    @id_generado = @id_anun_bud OUTPUT;

-- =========================================================================
-- 2. CAMPAÑAS
-- =========================================================================
PRINT '2. Cargando campañas...';

DECLARE @camp_adidas_wc   INT, @camp_coca_tour  INT, @camp_visa_na     INT, @camp_meli_env   INT;
DECLARE @camp_qatar_wc    INT, @camp_ps5_stad   INT, @camp_itau_bra    INT, @camp_hyundai_ev INT;
DECLARE @camp_bud_grupos  INT, @camp_adidas_grp INT, @camp_rolex_elim  INT, @camp_adidas_fin INT;

EXEC publicidad.sp_RegistrarCampania @nombre = 'Adidas World Cup 2026',      @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_adidas,   @id_generado = @camp_adidas_wc OUTPUT;
EXEC publicidad.sp_RegistrarCampania @nombre = 'Coca-Cola Tour 2026',        @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_cocacola, @id_generado = @camp_coca_tour OUTPUT;
EXEC publicidad.sp_RegistrarCampania @nombre = 'Visa North America 2026',    @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_visa,     @id_generado = @camp_visa_na OUTPUT;
EXEC publicidad.sp_RegistrarCampania @nombre = 'Mercado Libre Envíos 2026',  @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_meli,     @id_generado = @camp_meli_env OUTPUT;
EXEC publicidad.sp_RegistrarCampania @nombre = 'Qatar Airways FIFA 2026',    @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_qatar,    @id_generado = @camp_qatar_wc OUTPUT;
EXEC publicidad.sp_RegistrarCampania @nombre = 'PlayStation 5 Stadium 2026', @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_sony,     @id_generado = @camp_ps5_stad OUTPUT;
EXEC publicidad.sp_RegistrarCampania @nombre = 'Banco Itaú Brasil 2026',     @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_itau,     @id_generado = @camp_itau_bra OUTPUT;
EXEC publicidad.sp_RegistrarCampania @nombre = 'Hyundai Movilidad 2026',     @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_hyundai,  @id_generado = @camp_hyundai_ev OUTPUT;
EXEC publicidad.sp_RegistrarCampania @nombre = 'Budweiser Fase de Grupos',   @fecha_inicio = '2026-06-01', @fecha_fin = '2026-06-27', @id_anunciante = @id_anun_bud,      @id_generado = @camp_bud_grupos OUTPUT;
EXEC publicidad.sp_RegistrarCampania @nombre = 'Adidas Apertura Grupos',     @fecha_inicio = '2026-06-01', @fecha_fin = '2026-06-27', @id_anunciante = @id_anun_adidas,   @id_generado = @camp_adidas_grp OUTPUT;
EXEC publicidad.sp_RegistrarCampania @nombre = 'Rolex Fase Eliminatoria',    @fecha_inicio = '2026-06-28', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_rolex,    @id_generado = @camp_rolex_elim OUTPUT;
EXEC publicidad.sp_RegistrarCampania @nombre = 'Adidas Fase Final',          @fecha_inicio = '2026-06-28', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_adidas,   @id_generado = @camp_adidas_fin OUTPUT;

-- Prueba de validación: campaña con fechas invertidas
BEGIN TRY
    EXEC publicidad.sp_RegistrarCampania
        @nombre        = 'Campaña Fechas Invertidas',
        @fecha_inicio  = '2026-08-15',
        @fecha_fin     = '2026-06-01',
        @id_anunciante = @id_anun_adidas;
END TRY
BEGIN CATCH
    PRINT 'Bloqueo esperado (fechas de campaña): ' + ERROR_MESSAGE();
END CATCH;

-- =========================================================================
-- 3. PIEZAS DE CONTENIDO Y PAÍSES DE INTERÉS
-- =========================================================================
PRINT '3. Cargando piezas de contenido y países de interés...';

DECLARE @id_arg INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'ARG');
DECLARE @id_bra INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'BRA');
DECLARE @id_ury INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'URY');
DECLARE @id_pry INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'PRY');
DECLARE @id_col INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'COL');
DECLARE @id_ecu INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'ECU');
DECLARE @id_mex INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'MEX');
DECLARE @id_pan INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'PAN');
DECLARE @id_usa INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'USA');
DECLARE @id_can INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'CAN');
DECLARE @id_esp INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'ESP');
DECLARE @id_prt INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'PRT');
DECLARE @id_fra INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'FRA');
DECLARE @id_deu INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'DEU');
DECLARE @id_gbr INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'GBR');
DECLARE @id_che INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'CHE');
DECLARE @id_nld INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'NLD');
DECLARE @id_bel INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'BEL');
DECLARE @id_hrv INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'HRV');
DECLARE @id_aut INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'AUT');
DECLARE @id_swe INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'SWE');
DECLARE @id_nor INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'NOR');
DECLARE @id_tur INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'TUR');
DECLARE @id_jpn INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'JPN');
DECLARE @id_kor INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'KOR');
DECLARE @id_qat INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'QAT');
DECLARE @id_nzl INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'NZL');
DECLARE @id_zaf INT = (SELECT ID FROM administracion.Pais WHERE codigo_iso = 'ZAF');

DECLARE @id_pieza INT;

-- Pieza 1
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Adidas Selección Argentina', @idioma = 'Español', @costo = 95000.00, @id_campania = @camp_adidas_wc, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_arg;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_ury;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_pry;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_col;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_ecu;

-- Pieza 2
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Banner Mercado Libre Sudamérica', @idioma = 'Español', @costo = 82000.00, @id_campania = @camp_meli_env, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_arg;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_bra;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_mex;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_col;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_ury;

-- Pieza 3
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Banco Itaú Selección Brasil', @idioma = 'Portugués', @costo = 91000.00, @id_campania = @camp_itau_bra, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_bra;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_prt;

-- Pieza 4
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Coca-Cola Latinoamérica', @idioma = 'Español', @costo = 78000.00, @id_campania = @camp_coca_tour, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_mex;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_pan;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_esp;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_arg;

-- Pieza 5
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Visa Pagos sin Contacto', @idioma = 'Inglés', @costo = 125000.00, @id_campania = @camp_visa_na, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_usa;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_can;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_nzl;

-- Pieza 6
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Rolex Cronómetro Oficial', @idioma = 'Inglés', @costo = 145000.00, @id_campania = @camp_rolex_elim, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_che;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_usa;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_gbr;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_nor;

-- Pieza 7
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Rolex Edición Suiza y Francia', @idioma = 'Francés', @costo = 138000.00, @id_campania = @camp_rolex_elim, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_che;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_fra;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_bel;

-- Pieza 8
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Banner Adidas Selecciones Europeas', @idioma = 'Alemán', @costo = 110000.00, @id_campania = @camp_adidas_wc, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_deu;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_aut;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_nld;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_swe;

-- Pieza 9
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Coca-Cola Zero Europa', @idioma = 'Inglés', @costo = 105000.00, @id_campania = @camp_coca_tour, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_gbr;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_nld;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_hrv;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_tur;

-- Pieza 10
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot PS5 EA Sports FC 26', @idioma = 'Japonés', @costo = 115000.00, @id_campania = @camp_ps5_stad, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_jpn;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_usa;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_gbr;

-- Pieza 11
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot PS5 Torneo Europeo', @idioma = 'Francés', @costo = 112000.00, @id_campania = @camp_ps5_stad, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_fra;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_esp;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_prt;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_deu;

-- Pieza 12
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Qatar Airways Vuelos al Mundial', @idioma = 'Árabe', @costo = 118000.00, @id_campania = @camp_qatar_wc, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_qat;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_usa;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_fra;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_gbr;

-- Pieza 13
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Hyundai Autos Eléctricos', @idioma = 'Coreano', @costo = 98000.00, @id_campania = @camp_hyundai_ev, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_kor;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_nor;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_deu;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_zaf;

-- Pieza 14
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Banner Budweiser Fase de Grupos', @idioma = 'Inglés', @costo = 89000.00, @id_campania = @camp_bud_grupos, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_usa;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_mex;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_can;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_gbr;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_bra;

-- Pieza 15
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Banner Adidas Botines Fase de Grupos', @idioma = 'Español', @costo = 84000.00, @id_campania = @camp_adidas_grp, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_esp;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_arg;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_col;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_mex;

-- Pieza 16
EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Adidas Fase Final', @idioma = 'Español', @costo = 135000.00, @id_campania = @camp_adidas_fin, @id_generado = @id_pieza OUTPUT;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_arg;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_bra;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_fra;
EXEC publicidad.sp_InsertarPaisInteresPieza @id_pieza = @id_pieza, @id_pais = @id_esp;

SELECT 
    (SELECT COUNT(*) FROM publicidad.Anunciante)         AS total_anunciantes,
    (SELECT COUNT(*) FROM publicidad.Campania)           AS total_campanias,
    (SELECT COUNT(*) FROM publicidad.Pieza_Contenido)    AS total_piezas,
    (SELECT COUNT(*) FROM publicidad.Pieza_Pais_Interes) AS total_paises_interes;

PRINT 'Script 02 finalizado.';
GO
