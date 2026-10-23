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
     
   Script: test_07_publicidad.sql
   Descripción: Lote de pruebas unitarias para los Stored Procedures de 07_sp_publicidad.sql.
                - Anunciantes (alta, modificación, baja y validaciones).
                - Campañas publicitarias (alta, modificación, baja, vigencia y validaciones).
                - Piezas de contenido y Países de interés (alta, modificación, baja y validaciones).
                - Espacios publicitarios (4 paneles simultáneos por partido) y Algoritmo de Priorización
                  de Exhibición Publicitaria
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
PRINT 'INICIANDO LOTE DE PRUEBAS 1:1 - MÓDULO PUBLICIDAD (07)';
PRINT '======================================================================';

-- =========================================================================================
-- 1. BLOQUE DE PRUEBAS: ABM DE ANUNCIANTES (sp_RegistrarAnunciante y sp_EliminarAnunciante)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    -- 1.A. Alta exitosa de anunciante
    DECLARE @id_anun1 INT;
    EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Adidas Test Oficial', @id_generado = @id_anun1 OUTPUT;

    IF @id_anun1 IS NOT NULL AND EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE ID = @id_anun1 AND nombre = 'Adidas Test Oficial')
        INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Alta exitosa de anunciante', 'Caso de Éxito', 'OK', 'Anunciante creado con ID: ' + CAST(@id_anun1 AS VARCHAR));
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Alta exitosa de anunciante', 'Caso de Éxito', 'FALLÓ', 'No se registró el anunciante.');

    -- 1.B. Modificación exitosa de anunciante
    EXEC publicidad.sp_RegistrarAnunciante @id = @id_anun1, @nombre = 'Adidas Global 2026';

    IF EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE ID = @id_anun1 AND nombre = 'Adidas Global 2026')
        INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Modificación exitosa de anunciante', 'Caso de Éxito', 'OK', 'Nombre actualizado a Adidas Global 2026.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Modificación exitosa de anunciante', 'Caso de Éxito', 'FALLÓ', 'No se actualizó el nombre.');

    -- 1.C. Error 50003: Nombre de anunciante vacío
    BEGIN TRY
        EXEC publicidad.sp_RegistrarAnunciante @nombre = '   ';
        INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Bloqueo nombre de anunciante vacío', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50003');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50003
            INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Bloqueo nombre de anunciante vacío', 'Validación THROW', 'OK', 'Capturado 50003: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Bloqueo nombre de anunciante vacío', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.D. Error 50005: Anunciante duplicado
    BEGIN TRY
        EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Adidas Global 2026';
        INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Bloqueo nombre de anunciante duplicado', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50005');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50005
            INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Bloqueo nombre de anunciante duplicado', 'Validación THROW', 'OK', 'Capturado 50005: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Bloqueo nombre de anunciante duplicado', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.E. Error 50004: Modificación de anunciante inexistente
    BEGIN TRY
        EXEC publicidad.sp_RegistrarAnunciante @id = 999999, @nombre = 'Inexistente';
        INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Bloqueo modificación anunciante inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50004');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50004
            INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Bloqueo modificación anunciante inexistente', 'Validación THROW', 'OK', 'Capturado 50004: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarAnunciante', 'Bloqueo modificación anunciante inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 1.F. Baja exitosa de anunciante sin campañas
    EXEC publicidad.sp_EliminarAnunciante @id = @id_anun1;
    IF NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE ID = @id_anun1)
        INSERT INTO @Reporte VALUES ('sp_EliminarAnunciante', 'Baja exitosa de anunciante', 'Caso de Éxito', 'OK', 'Anunciante eliminado correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarAnunciante', 'Baja exitosa de anunciante', 'Caso de Éxito', 'FALLÓ', 'El anunciante sigue existiendo.');

    -- 1.G. Error 50017: Baja de anunciante inexistente
    BEGIN TRY
        EXEC publicidad.sp_EliminarAnunciante @id = @id_anun1;
        INSERT INTO @Reporte VALUES ('sp_EliminarAnunciante', 'Bloqueo baja de anunciante inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50017');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50017
            INSERT INTO @Reporte VALUES ('sp_EliminarAnunciante', 'Bloqueo baja de anunciante inexistente', 'Validación THROW', 'OK', 'Capturado 50017: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarAnunciante', 'Bloqueo baja de anunciante inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Bloque 1', 'Excepción crítica en Bloque 1', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

-- =========================================================================================
-- 2. BLOQUE DE PRUEBAS: ABM DE CAMPAÑAS PUBLICITARIAS (sp_RegistrarCampania y sp_EliminarCampania)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_anun_c INT, @id_camp1 INT;
    EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Coca-Cola Test', @id_generado = @id_anun_c OUTPUT;

    -- 2.A. Alta exitosa de campaña
    EXEC publicidad.sp_RegistrarCampania
        @nombre = 'Magia Mundialista 2026',
        @fecha_inicio = '2026-06-01',
        @fecha_fin = '2026-07-31',
        @id_anunciante = @id_anun_c,
        @id_generado = @id_camp1 OUTPUT;

    IF @id_camp1 IS NOT NULL AND EXISTS (SELECT 1 FROM publicidad.Campania WHERE ID = @id_camp1)
        INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Alta exitosa de campaña publicitaria', 'Caso de Éxito', 'OK', 'Campaña creada con ID: ' + CAST(@id_camp1 AS VARCHAR));
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Alta exitosa de campaña publicitaria', 'Caso de Éxito', 'FALLÓ', 'No se insertó la campaña.');

    -- 2.B. Modificación exitosa de campaña
    EXEC publicidad.sp_RegistrarCampania
        @id = @id_camp1,
        @nombre = 'Magia Mundialista Extendida',
        @fecha_inicio = '2026-06-01',
        @fecha_fin = '2026-08-15',
        @id_anunciante = @id_anun_c;

    IF EXISTS (SELECT 1 FROM publicidad.Campania WHERE ID = @id_camp1 AND nombre = 'Magia Mundialista Extendida')
        INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Modificación exitosa de campaña', 'Caso de Éxito', 'OK', 'Nombre y fecha fin actualizados.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Modificación exitosa de campaña', 'Caso de Éxito', 'FALLÓ', 'No se actualizó la campaña.');

    -- 2.C. Error 50019: Nombre de campaña vacío
    BEGIN TRY
        EXEC publicidad.sp_RegistrarCampania @nombre = '', @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-01', @id_anunciante = @id_anun_c;
        INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo nombre de campaña vacío', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50019');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50019
            INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo nombre de campaña vacío', 'Validación THROW', 'OK', 'Capturado 50019: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo nombre de campaña vacío', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.D. Error 50006: Fechas de campaña invertidas (inicio > fin)
    BEGIN TRY
        EXEC publicidad.sp_RegistrarCampania @nombre = 'Campaña Inválida', @fecha_inicio = '2026-08-01', @fecha_fin = '2026-06-01', @id_anunciante = @id_anun_c;
        INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo fecha inicio mayor a fecha fin', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50006');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50006
            INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo fecha inicio mayor a fecha fin', 'Validación THROW', 'OK', 'Capturado 50006: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo fecha inicio mayor a fecha fin', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.E. Error 50007: Anunciante inexistente
    BEGIN TRY
        EXEC publicidad.sp_RegistrarCampania @nombre = 'Campaña Sin Anunciante', @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-01', @id_anunciante = 999999;
        INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo anunciante inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50007');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50007
            INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo anunciante inexistente', 'Validación THROW', 'OK', 'Capturado 50007: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo anunciante inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.F. Error 50008: Modificación de campaña inexistente
    BEGIN TRY
        EXEC publicidad.sp_RegistrarCampania @id = 999999, @nombre = 'Campaña Fantasma', @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-01', @id_anunciante = @id_anun_c;
        INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo modificación campaña inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50008');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50008
            INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo modificación campaña inexistente', 'Validación THROW', 'OK', 'Capturado 50008: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarCampania', 'Bloqueo modificación campaña inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.G. Error 50018: Bloqueo baja de anunciante con campañas asociadas
    BEGIN TRY
        EXEC publicidad.sp_EliminarAnunciante @id = @id_anun_c;
        INSERT INTO @Reporte VALUES ('sp_EliminarAnunciante', 'Bloqueo baja anunciante con campañas', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50018');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50018
            INSERT INTO @Reporte VALUES ('sp_EliminarAnunciante', 'Bloqueo baja anunciante con campañas', 'Validación THROW', 'OK', 'Capturado 50018: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarAnunciante', 'Bloqueo baja anunciante con campañas', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 2.H. Baja exitosa de campaña
    EXEC publicidad.sp_EliminarCampania @id = @id_camp1;
    IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE ID = @id_camp1)
        INSERT INTO @Reporte VALUES ('sp_EliminarCampania', 'Baja exitosa de campaña sin piezas', 'Caso de Éxito', 'OK', 'Campaña eliminada correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarCampania', 'Baja exitosa de campaña sin piezas', 'Caso de Éxito', 'FALLÓ', 'La campaña sigue existiendo.');

    -- 2.I. Error 50020: Baja de campaña inexistente
    BEGIN TRY
        EXEC publicidad.sp_EliminarCampania @id = @id_camp1;
        INSERT INTO @Reporte VALUES ('sp_EliminarCampania', 'Bloqueo baja de campaña inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50020');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50020
            INSERT INTO @Reporte VALUES ('sp_EliminarCampania', 'Bloqueo baja de campaña inexistente', 'Validación THROW', 'OK', 'Capturado 50020: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarCampania', 'Bloqueo baja de campaña inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Bloque 2', 'Excepción crítica en Bloque 2', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

-- =========================================================================================
-- 3. BLOQUE DE PRUEBAS: ABM DE PIEZAS DE CONTENIDO Y PAÍSES DE INTERÉS
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_pi INT, @id_anun_p INT, @id_camp_p INT, @id_pieza1 INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Interes Test', @pbi_percapita = 42000, @huso_horario = '-03:00', @id_generado = @id_pais_pi OUTPUT;
    EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Visa Test', @id_generado = @id_anun_p OUTPUT;
    EXEC publicidad.sp_RegistrarCampania @nombre = 'Campaña Visa 2026', @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_p, @id_generado = @id_camp_p OUTPUT;

    -- 3.A. Alta exitosa de pieza de contenido
    EXEC publicidad.sp_RegistrarPiezaContenido
        @nombre = 'Spot Visa Español',
        @idioma = 'Español',
        @costo = 15000.00,
        @id_campania = @id_camp_p,
        @id_generado = @id_pieza1 OUTPUT;

    IF @id_pieza1 IS NOT NULL AND EXISTS (SELECT 1 FROM publicidad.Pieza_Contenido WHERE ID = @id_pieza1)
        INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Alta exitosa de pieza publicitaria', 'Caso de Éxito', 'OK', 'Pieza creada con ID: ' + CAST(@id_pieza1 AS VARCHAR));
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Alta exitosa de pieza publicitaria', 'Caso de Éxito', 'FALLÓ', 'No se insertó la pieza.');

    -- 3.B. Modificación exitosa de pieza de contenido
    EXEC publicidad.sp_RegistrarPiezaContenido
        @id = @id_pieza1,
        @nombre = 'Spot Visa Latam HD',
        @idioma = 'Español',
        @costo = 18500.00,
        @id_campania = @id_camp_p;

    IF EXISTS (SELECT 1 FROM publicidad.Pieza_Contenido WHERE ID = @id_pieza1 AND costo = 18500.00)
        INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Modificación exitosa de pieza publicitaria', 'Caso de Éxito', 'OK', 'Nombre y costo actualizados a $18.500.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Modificación exitosa de pieza publicitaria', 'Caso de Éxito', 'FALLÓ', 'No se actualizó la pieza.');

    -- 3.C. Error 50022: Nombre o idioma vacío en pieza
    BEGIN TRY
        EXEC publicidad.sp_RegistrarPiezaContenido @nombre = '', @idioma = 'Español', @costo = 1000, @id_campania = @id_camp_p;
        INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo nombre o idioma vacío', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50022');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50022
            INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo nombre o idioma vacío', 'Validación THROW', 'OK', 'Capturado 50022: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo nombre o idioma vacío', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.D. Error 50009: Costo negativo
    BEGIN TRY
        EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Negativo', @idioma = 'Inglés', @costo = -500, @id_campania = @id_camp_p;
        INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo costo negativo en pieza', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50009');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50009
            INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo costo negativo en pieza', 'Validación THROW', 'OK', 'Capturado 50009: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo costo negativo en pieza', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.E. Error 50010: Campaña inexistente
    BEGIN TRY
        EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Spot Huérfano', @idioma = 'Inglés', @costo = 5000, @id_campania = 999999;
        INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo campaña inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50010');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50010
            INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo campaña inexistente', 'Validación THROW', 'OK', 'Capturado 50010: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo campaña inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.F. Error 50011: Modificar pieza inexistente
    BEGIN TRY
        EXEC publicidad.sp_RegistrarPiezaContenido @id = 999999, @nombre = 'Spot Fantasma', @idioma = 'Inglés', @costo = 5000, @id_campania = @id_camp_p;
        INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo modificación pieza inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50011');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50011
            INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo modificación pieza inexistente', 'Validación THROW', 'OK', 'Capturado 50011: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_RegistrarPiezaContenido', 'Bloqueo modificación pieza inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.G. Error 50021: Bloqueo baja de campaña con piezas asociadas
    BEGIN TRY
        EXEC publicidad.sp_EliminarCampania @id = @id_camp_p;
        INSERT INTO @Reporte VALUES ('sp_EliminarCampania', 'Bloqueo baja campaña con piezas activas', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50021');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50021
            INSERT INTO @Reporte VALUES ('sp_EliminarCampania', 'Bloqueo baja campaña con piezas activas', 'Validación THROW', 'OK', 'Capturado 50021: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarCampania', 'Bloqueo baja campaña con piezas activas', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.H. Alta exitosa de país de interés para la pieza
    EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = @id_pieza1, @id_pais = @id_pais_pi, @accion = 'INSERTAR';
    IF EXISTS (SELECT 1 FROM publicidad.Pieza_Pais_Interes WHERE ID_Pieza = @id_pieza1 AND ID_Pais = @id_pais_pi)
        INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Asociación exitosa de país de interés', 'Caso de Éxito', 'OK', 'País vinculado a la pieza publicitaria.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Asociación exitosa de país de interés', 'Caso de Éxito', 'FALLÓ', 'No se vinculó el país a la pieza.');

    -- 3.I. Error 50028: País de interés duplicado para la misma pieza
    BEGIN TRY
        EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = @id_pieza1, @id_pais = @id_pais_pi, @accion = 'INSERTAR';
        INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo país de interés duplicado', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50028');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50028
            INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo país de interés duplicado', 'Validación THROW', 'OK', 'Capturado 50028: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo país de interés duplicado', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.J. Error 50025: Pieza inexistente al asociar país
    BEGIN TRY
        EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = 999999, @id_pais = @id_pais_pi, @accion = 'INSERTAR';
        INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo pieza inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50025');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50025
            INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo pieza inexistente', 'Validación THROW', 'OK', 'Capturado 50025: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo pieza inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.K. Error 50026: País inexistente al asociar a pieza
    BEGIN TRY
        EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = @id_pieza1, @id_pais = 999999, @accion = 'INSERTAR';
        INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo país inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50026');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50026
            INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo país inexistente', 'Validación THROW', 'OK', 'Capturado 50026: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo país inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.L. Error 50027: Acción inválida en país de interés
    BEGIN TRY
        EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = @id_pieza1, @id_pais = @id_pais_pi, @accion = 'REEMPLAZAR';
        INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo acción inválida', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50027');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50027
            INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo acción inválida', 'Validación THROW', 'OK', 'Capturado 50027: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Bloqueo acción inválida', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 3.M. Baja exitosa de país de interés
    EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = @id_pieza1, @id_pais = @id_pais_pi, @accion = 'ELIMINAR';
    IF NOT EXISTS (SELECT 1 FROM publicidad.Pieza_Pais_Interes WHERE ID_Pieza = @id_pieza1 AND ID_Pais = @id_pais_pi)
        INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Baja exitosa de país de interés', 'Caso de Éxito', 'OK', 'País desvinculado correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_GestionarPaisInteresPieza', 'Baja exitosa de país de interés', 'Caso de Éxito', 'FALLÓ', 'El país sigue vinculado.');

    -- 3.N. Baja exitosa de pieza de contenido
    EXEC publicidad.sp_EliminarPiezaContenido @id = @id_pieza1;
    IF NOT EXISTS (SELECT 1 FROM publicidad.Pieza_Contenido WHERE ID = @id_pieza1)
        INSERT INTO @Reporte VALUES ('sp_EliminarPiezaContenido', 'Baja exitosa de pieza de contenido', 'Caso de Éxito', 'OK', 'Pieza eliminada correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarPiezaContenido', 'Baja exitosa de pieza de contenido', 'Caso de Éxito', 'FALLÓ', 'La pieza sigue existiendo.');

    -- 3.O. Error 50023: Baja de pieza inexistente
    BEGIN TRY
        EXEC publicidad.sp_EliminarPiezaContenido @id = @id_pieza1;
        INSERT INTO @Reporte VALUES ('sp_EliminarPiezaContenido', 'Bloqueo baja pieza inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50023');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50023
            INSERT INTO @Reporte VALUES ('sp_EliminarPiezaContenido', 'Bloqueo baja pieza inexistente', 'Validación THROW', 'OK', 'Capturado 50023: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarPiezaContenido', 'Bloqueo baja pieza inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Bloque 3', 'Excepción crítica en Bloque 3', 'Error Crítico', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;

-- =========================================================================================
-- 4. BLOQUE DE PRUEBAS: ALGORITMO DE ASIGNACIÓN Y CASO OBLIGATORIO PRIME TIME (>4 MERCADOS)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    /*
       Escenario Obligatorio TP (Sección IV - Criterios de Aceptación):
       "Un partido cuyo horario caiga en prime time simultáneamente en más de cuatro mercados candidatos,
        de forma que el sistema deba aplicar el criterio de priorización para elegir solo cuatro."
       
       Configuración horaria:
       - Sede en huso '-05:00', partido a las 16:00 hs local -> Hora UTC = 21:00 hs.
       - 6 países candidatos cuyos husos horarios ubican las 21:00 UTC dentro del Prime Time (19:00 a 23:00 hs):
         1. País Local (huso -02:00 -> 19:00 hs local, PBI 20.000) -> Juega el partido (Prioridad 1)
         2. País Visitante (huso -01:00 -> 20:00 hs local, PBI 22.000) -> Juega el partido (Prioridad 1)
         3. Mercado Rico A (huso +00:00 -> 21:00 hs local, PBI 65.000) -> Mayor PBI en Prime Time (Prioridad 2)
         4. Mercado Rico B (huso +01:00 -> 22:00 hs local, PBI 50.000) -> 2do Mayor PBI en Prime Time (Prioridad 2)
         5. Mercado Medio C (huso +02:00 -> 23:00 hs local, PBI 28.000) -> En Prime Time pero 5to (Queda afuera)
         6. Mercado Bajo D (huso -02:00 -> 19:00 hs local, PBI 15.000) -> En Prime Time pero 6to (Queda afuera)
    */
    DECLARE @p_loc INT, @p_vis INT, @p_ricoA INT, @p_ricoB INT, @p_medC INT, @p_bajoD INT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Pub Local', @pbi_percapita = 20000, @huso_horario = '-02:00', @id_generado = @p_loc OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Pub Visita', @pbi_percapita = 22000, @huso_horario = '-01:00', @id_generado = @p_vis OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Mercado Rico A', @pbi_percapita = 65000, @huso_horario = '+00:00', @id_generado = @p_ricoA OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Mercado Rico B', @pbi_percapita = 50000, @huso_horario = '+01:00', @id_generado = @p_ricoB OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Mercado Medio C', @pbi_percapita = 28000, @huso_horario = '+02:00', @id_generado = @p_medC OUTPUT;
    EXEC administracion.sp_InsertarPais @nombre = 'Pais Mercado Bajo D', @pbi_percapita = 15000, @huso_horario = '-02:00', @id_generado = @p_bajoD OUTPUT;

    DECLARE @id_sede_pub INT, @id_fase_pub INT, @sel_loc_pub INT, @sel_vis_pub INT;
    EXEC administracion.sp_InsertarSede @nombre = 'Estadio Publicidad Prime', @ciudad = 'Nueva York', @capacidad = 82000, @huso_horario = '-05:00', @id_pais = @p_loc, @id_generado = @id_sede_pub OUTPUT;
    EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase Publicidad Test', @orden = 1, @id_generado = @id_fase_pub OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @p_loc, @confederacion = 'CONMEBOL', @grupo_asignado = 'F', @id_generado = @sel_loc_pub OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @p_vis, @confederacion = 'UEFA', @grupo_asignado = 'F', @id_generado = @sel_vis_pub OUTPUT;

    -- Al crear el partido, sp_CrearPartido invoca automáticamente sp_GenerarEspaciosPartido
    EXEC partido.sp_CrearPartido @id_sede = @id_sede_pub, @id_fase = @id_fase_pub, @fecha_hora_local = '2026-06-25 16:00:00', @id_local = @sel_loc_pub, @id_visitante = @sel_vis_pub;
    DECLARE @id_part_pub INT;
    SELECT TOP 1 @id_part_pub = ID FROM partido.Partido WHERE ID_Sede = @id_sede_pub ORDER BY ID DESC;

    -- 4.A. Error 50002: Bloqueo de regeneración duplicada de espacios para el mismo partido
    BEGIN TRY
        EXEC publicidad.sp_GenerarEspaciosPartido @id_partido = @id_part_pub;
        INSERT INTO @Reporte VALUES ('sp_GenerarEspaciosPartido', 'Bloqueo espacios duplicados en partido', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50002');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50002
            INSERT INTO @Reporte VALUES ('sp_GenerarEspaciosPartido', 'Bloqueo espacios duplicados en partido', 'Validación THROW', 'OK', 'Capturado 50002: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_GenerarEspaciosPartido', 'Bloqueo espacios duplicados en partido', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.B. Error 50001: Generar espacios en partido inexistente
    BEGIN TRY
        EXEC publicidad.sp_GenerarEspaciosPartido @id_partido = 999999;
        INSERT INTO @Reporte VALUES ('sp_GenerarEspaciosPartido', 'Bloqueo partido inexistente', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50001');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50001
            INSERT INTO @Reporte VALUES ('sp_GenerarEspaciosPartido', 'Bloqueo partido inexistente', 'Validación THROW', 'OK', 'Capturado 50001: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_GenerarEspaciosPartido', 'Bloqueo partido inexistente', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- Creamos anunciante, campaña vigente y las 6 piezas candidatas en Prime Time
    DECLARE @id_anun_prime INT, @id_camp_prime INT;
    DECLARE @pz1 INT, @pz2 INT, @pz3 INT, @pz4 INT, @pz5 INT, @pz6 INT;
    EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Qatar Airways Prime Test', @id_generado = @id_anun_prime OUTPUT;
    EXEC publicidad.sp_RegistrarCampania @nombre = 'Campaña Global Prime 2026', @fecha_inicio = '2026-06-01', @fecha_fin = '2026-07-31', @id_anunciante = @id_anun_prime, @id_generado = @id_camp_prime OUTPUT;

    EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Pieza 1 - Pais Local', @idioma = 'Español', @costo = 10000, @id_campania = @id_camp_prime, @id_generado = @pz1 OUTPUT;
    EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Pieza 2 - Pais Visita', @idioma = 'Portugués', @costo = 12000, @id_campania = @id_camp_prime, @id_generado = @pz2 OUTPUT;
    EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Pieza 3 - Mercado Rico A', @idioma = 'Inglés', @costo = 25000, @id_campania = @id_camp_prime, @id_generado = @pz3 OUTPUT;
    EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Pieza 4 - Mercado Rico B', @idioma = 'Francés', @costo = 20000, @id_campania = @id_camp_prime, @id_generado = @pz4 OUTPUT;
    EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Pieza 5 - Mercado Medio C', @idioma = 'Alemán', @costo = 15000, @id_campania = @id_camp_prime, @id_generado = @pz5 OUTPUT;
    EXEC publicidad.sp_RegistrarPiezaContenido @nombre = 'Pieza 6 - Mercado Bajo D', @idioma = 'Italiano', @costo = 8000, @id_campania = @id_camp_prime, @id_generado = @pz6 OUTPUT;

    EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = @pz1, @id_pais = @p_loc, @accion = 'INSERTAR';
    EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = @pz2, @id_pais = @p_vis, @accion = 'INSERTAR';
    EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = @pz3, @id_pais = @p_ricoA, @accion = 'INSERTAR';
    EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = @pz4, @id_pais = @p_ricoB, @accion = 'INSERTAR';
    EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = @pz5, @id_pais = @p_medC, @accion = 'INSERTAR';
    EXEC publicidad.sp_GestionarPaisInteresPieza @id_pieza = @pz6, @id_pais = @p_bajoD, @accion = 'INSERTAR';

    -- 4.C. Ejecución de sp_AsignarPublicidadPartido con 6 candidatos simultáneos en Prime Time
    EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_part_pub;

    DECLARE @cant_asignadas INT, @entraron_top4 INT, @entraron_descartadas INT;
    SELECT @cant_asignadas = COUNT(*)
    FROM publicidad.Exhibicion ex
    JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio
    WHERE ep.ID_Partido = @id_part_pub;

    SELECT @entraron_top4 = COUNT(*)
    FROM publicidad.Exhibicion ex
    JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio
    WHERE ep.ID_Partido = @id_part_pub AND ex.ID_Pieza IN (@pz1, @pz2, @pz3, @pz4);

    SELECT @entraron_descartadas = COUNT(*)
    FROM publicidad.Exhibicion ex
    JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio
    WHERE ep.ID_Partido = @id_part_pub AND ex.ID_Pieza IN (@pz5, @pz6);

    IF @cant_asignadas = 4 AND @entraron_top4 = 4 AND @entraron_descartadas = 0
        INSERT INTO @Reporte VALUES ('sp_AsignarPublicidadPartido', 'Priorización exitosa entre 6 mercados en Prime Time', 'Caso Obligatorio TP', 'OK', 'Eligió exactamente las 4 piezas prioritarias y descartó las 2 restantes.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_AsignarPublicidadPartido', 'Priorización exitosa entre 6 mercados en Prime Time', 'Caso Obligatorio TP', 'FALLÓ', 'No seleccionó las 4 piezas esperadas.');

    -- 4.D. Error 50014: Bloqueo de doble asignación publicitaria para el mismo partido
    BEGIN TRY
        EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_part_pub;
        INSERT INTO @Reporte VALUES ('sp_AsignarPublicidadPartido', 'Bloqueo publicidad ya asignada en el partido', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50014');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50014
            INSERT INTO @Reporte VALUES ('sp_AsignarPublicidadPartido', 'Bloqueo publicidad ya asignada en el partido', 'Validación THROW', 'OK', 'Capturado 50014: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_AsignarPublicidadPartido', 'Bloqueo publicidad ya asignada en el partido', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.E. Error 50024: Bloqueo baja de pieza que ya registra exhibiciones facturadas
    BEGIN TRY
        EXEC publicidad.sp_EliminarPiezaContenido @id = @pz1;
        INSERT INTO @Reporte VALUES ('sp_EliminarPiezaContenido', 'Bloqueo baja pieza con exhibición facturada', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50024');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50024
            INSERT INTO @Reporte VALUES ('sp_EliminarPiezaContenido', 'Bloqueo baja pieza con exhibición facturada', 'Validación THROW', 'OK', 'Capturado 50024: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarPiezaContenido', 'Bloqueo baja pieza con exhibición facturada', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.F. Error 50016: Bloqueo baja de espacios publicitarios con exhibición activa
    BEGIN TRY
        EXEC publicidad.sp_EliminarEspaciosPartido @id_partido = @id_part_pub;
        INSERT INTO @Reporte VALUES ('sp_EliminarEspaciosPartido', 'Bloqueo baja espacios con exhibiciones activas', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50016');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50016
            INSERT INTO @Reporte VALUES ('sp_EliminarEspaciosPartido', 'Bloqueo baja espacios con exhibiciones activas', 'Validación THROW', 'OK', 'Capturado 50016: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarEspaciosPartido', 'Bloqueo baja espacios con exhibiciones activas', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.G. Baja exitosa de exhibiciones del partido (sp_EliminarExhibicionPartido)
    EXEC publicidad.sp_EliminarExhibicionPartido @id_partido = @id_part_pub;
    IF NOT EXISTS (
        SELECT 1 FROM publicidad.Exhibicion ex
        JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio
        WHERE ep.ID_Partido = @id_part_pub
    )
        INSERT INTO @Reporte VALUES ('sp_EliminarExhibicionPartido', 'Baja exitosa de exhibiciones del partido', 'Caso de Éxito', 'OK', 'Exhibiciones del partido liberadas correctamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarExhibicionPartido', 'Baja exitosa de exhibiciones del partido', 'Caso de Éxito', 'FALLÓ', 'Siguen existiendo exhibiciones.');

    -- 4.H. Error 50029: Baja de exhibiciones en partido sin pauta asignada
    BEGIN TRY
        EXEC publicidad.sp_EliminarExhibicionPartido @id_partido = @id_part_pub;
        INSERT INTO @Reporte VALUES ('sp_EliminarExhibicionPartido', 'Bloqueo baja exhibiciones inexistentes', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50029');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50029
            INSERT INTO @Reporte VALUES ('sp_EliminarExhibicionPartido', 'Bloqueo baja exhibiciones inexistentes', 'Validación THROW', 'OK', 'Capturado 50029: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_EliminarExhibicionPartido', 'Bloqueo baja exhibiciones inexistentes', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.I. Baja exitosa de espacios publicitarios tras liberar exhibiciones
    EXEC publicidad.sp_EliminarEspaciosPartido @id_partido = @id_part_pub;
    IF NOT EXISTS (SELECT 1 FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_part_pub)
        INSERT INTO @Reporte VALUES ('sp_EliminarEspaciosPartido', 'Baja exitosa de espacios publicitarios', 'Caso de Éxito', 'OK', 'Los 4 paneles del partido fueron eliminados.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_EliminarEspaciosPartido', 'Baja exitosa de espacios publicitarios', 'Caso de Éxito', 'FALLÓ', 'Los espacios siguen existiendo.');

    -- 4.J. Error 50013: Bloqueo de asignación publicitaria en partido sin espacios generados
    BEGIN TRY
        EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = @id_part_pub;
        INSERT INTO @Reporte VALUES ('sp_AsignarPublicidadPartido', 'Bloqueo asignación en partido sin espacios', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50013');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50013
            INSERT INTO @Reporte VALUES ('sp_AsignarPublicidadPartido', 'Bloqueo asignación en partido sin espacios', 'Validación THROW', 'OK', 'Capturado 50013: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @Reporte VALUES ('sp_AsignarPublicidadPartido', 'Bloqueo asignación en partido sin espacios', 'Validación THROW', 'FALLÓ', 'Error inesperado: ' + CAST(ERROR_NUMBER() AS VARCHAR));
    END CATCH;

    -- 4.K. Regeneración exitosa de los 4 espacios publicitarios del partido
    EXEC publicidad.sp_GenerarEspaciosPartido @id_partido = @id_part_pub;
    IF (SELECT COUNT(*) FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_part_pub) = 4
        INSERT INTO @Reporte VALUES ('sp_GenerarEspaciosPartido', 'Generación exitosa de 4 espacios por partido', 'Caso de Éxito', 'OK', '4 paneles perimetrales regenerados exitosamente.');
    ELSE
        INSERT INTO @Reporte VALUES ('sp_GenerarEspaciosPartido', 'Generación exitosa de 4 espacios por partido', 'Caso de Éxito', 'FALLÓ', 'No se generaron los 4 espacios.');

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
    Procedimiento,
    Escenario,
    Tipo_Prueba,
    Resultado,
    Detalle
FROM @Reporte
ORDER BY ID ASC;

-- Resumen estadístico
SELECT 
    Resultado, 
    COUNT(*) AS Total
FROM @Reporte
GROUP BY Resultado;
GO
