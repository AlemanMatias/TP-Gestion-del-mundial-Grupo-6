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
     
   Script: 07_sp_publicidad.sql
   Descripción: Módulo 4 - Gestión de Publicidad.
                Implementación de SP con ciclo ABM completo para el esquema 'publicidad':
                Anunciantes, Campañas, Piezas de Contenido, Países de Interés (Pieza_Pais_Interes),
                Espacios Publicitarios (4 paneles simultáneos por partido) y Algoritmo de Asignación
                y Facturación de Exhibiciones Publicitarias (país participante, PBI per cápita, prime time).
*/

USE Mundial2026;
GO

-- =========================================================================================
-- 1. ABM DE ESPACIOS PUBLICITARIOS POR PARTIDO (publicidad.Espacio_publicitario)
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_GenerarEspaciosPartido
    @id_partido INT
AS
BEGIN
    SET NOCOUNT ON;

    -- verifica si el partido existe
    IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_partido)
        THROW 50001, 'El partido indicado no existe.', 1;

    -- verifica que el partido no tenga asignado espacios
    IF EXISTS (SELECT 1 FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_partido)
        THROW 50002, 'Los espacios publicitarios ya fueron generados previamente para este partido.', 1;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO publicidad.Espacio_publicitario (nombre, numero_slot, ID_Partido)
        VALUES 
            ('Panel Perimetral Norte', 1, @id_partido),
            ('Panel Perimetral Sur', 2, @id_partido),
            ('Panel Perimetral Este', 3, @id_partido),
            ('Panel Perimetral Oeste', 4, @id_partido);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.sp_EliminarEspaciosPartido
    @id_partido INT
AS
BEGIN
    SET NOCOUNT ON;

    -- verifica que los espacios existan
    IF NOT EXISTS (SELECT 1 FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_partido)
        THROW 50015, 'No existen espacios publicitarios generados para el partido indicado.', 1;

    IF EXISTS (
        SELECT 1 FROM publicidad.Exhibicion ex
        JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio
        WHERE ep.ID_Partido = @id_partido
    )
        THROW 50016, 'No se pueden eliminar los espacios porque ya poseen exhibiciones facturadas.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_partido;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =========================================================================================
-- 2. ABM DE ANUNCIANTES (publicidad.Anunciante)
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_RegistrarAnunciante
    @id INT = NULL,
    @nombre VARCHAR(100),
    @id_generado INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50003, 'El nombre del anunciante no puede estar vacío.', 1;

    IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE ID = @id)
        THROW 50004, 'El anunciante que intenta modificar no existe.', 1;

    IF EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE nombre = LTRIM(RTRIM(@nombre)) AND (@id IS NULL OR ID <> @id))
        THROW 50005, 'Ya existe un anunciante registrado con ese nombre.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        IF @id IS NULL
        BEGIN
            INSERT INTO publicidad.Anunciante (nombre) VALUES (LTRIM(RTRIM(@nombre)));
            SET @id_generado = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE publicidad.Anunciante SET nombre = LTRIM(RTRIM(@nombre)) WHERE ID = @id;
            SET @id_generado = @id;
        END
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.sp_EliminarAnunciante
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE ID = @id)
        THROW 50017, 'El anunciante que intenta eliminar no existe.', 1;

    IF EXISTS (SELECT 1 FROM publicidad.Campania WHERE ID_Anunciante = @id)
        THROW 50018, 'No se puede eliminar el anunciante porque posee campañas publicitarias asociadas.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM publicidad.Anunciante WHERE ID = @id;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =========================================================================================
-- 3. ABM DE CAMPAÑAS PUBLICITARIAS (publicidad.Campania)
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_RegistrarCampania
    @id INT = NULL,
    @nombre VARCHAR(100),
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @id_anunciante INT,
    @id_generado INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50019, 'El nombre de la campaña no puede estar vacío.', 1;

    IF @fecha_inicio > @fecha_fin
        THROW 50006, 'La fecha de inicio de la campaña no puede ser posterior a la fecha de fin.', 1;
    
    IF NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE ID = @id_anunciante)
        THROW 50007, 'El anunciante referenciado no existe en el sistema.', 1;

    IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE ID = @id)
        THROW 50008, 'La campaña que intenta modificar no existe.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        IF @id IS NULL
        BEGIN
            INSERT INTO publicidad.Campania (nombre, fecha_inicio, fecha_fin, ID_Anunciante)
            VALUES (LTRIM(RTRIM(@nombre)), @fecha_inicio, @fecha_fin, @id_anunciante);
            SET @id_generado = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE publicidad.Campania 
            SET nombre = LTRIM(RTRIM(@nombre)), 
                fecha_inicio = @fecha_inicio, 
                fecha_fin = @fecha_fin, 
                ID_Anunciante = @id_anunciante
            WHERE ID = @id;
            SET @id_generado = @id;
        END
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.sp_EliminarCampania
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE ID = @id)
        THROW 50020, 'La campaña especificada no existe.', 1;

    IF EXISTS (SELECT 1 FROM publicidad.Pieza_Contenido WHERE ID_Campania = @id)
        THROW 50021, 'No se puede eliminar la campaña porque posee piezas de contenido asociadas.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM publicidad.Campania WHERE ID = @id;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =========================================================================================
-- 4. ABM DE PIEZAS DE CONTENIDO (publicidad.Pieza_Contenido)
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_RegistrarPiezaContenido
    @id INT = NULL,
    @nombre VARCHAR(100),
    @idioma VARCHAR(30),
    @costo DECIMAL(12,2),
    @id_campania INT,
    @id_generado INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = '' OR @idioma IS NULL OR LTRIM(RTRIM(@idioma)) = ''
        THROW 50022, 'El nombre y el idioma de la pieza publicitaria son obligatorios.', 1;

    IF @costo < 0
        THROW 50009, 'El costo de la pieza publicitaria no puede ser negativo.', 1;

    IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE ID = @id_campania)
        THROW 50010, 'La campaña referenciada no existe.', 1;

    IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM publicidad.Pieza_Contenido WHERE ID = @id)
        THROW 50011, 'La pieza de contenido que intenta modificar no existe.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        IF @id IS NULL
        BEGIN
            INSERT INTO publicidad.Pieza_Contenido (nombre, idioma, costo, ID_Campania)
            VALUES (LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@idioma)), @costo, @id_campania);
            SET @id_generado = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE publicidad.Pieza_Contenido 
            SET nombre = LTRIM(RTRIM(@nombre)), 
                idioma = LTRIM(RTRIM(@idioma)), 
                costo = @costo, 
                ID_Campania = @id_campania
            WHERE ID = @id;
            SET @id_generado = @id;
        END
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.sp_EliminarPiezaContenido
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM publicidad.Pieza_Contenido WHERE ID = @id)
        THROW 50023, 'La pieza de contenido especificada no existe.', 1;

    IF EXISTS (SELECT 1 FROM publicidad.Exhibicion WHERE ID_Pieza = @id)
        THROW 50024, 'No se puede eliminar la pieza de contenido porque registra exhibiciones facturadas en partidos.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM publicidad.Pieza_Pais_Interes WHERE ID_Pieza = @id;
        DELETE FROM publicidad.Pieza_Contenido WHERE ID = @id;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =========================================================================================
-- 5. ABM DE PAÍSES DE INTERÉS DE UNA PIEZA (publicidad.Pieza_Pais_Interes)
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_GestionarPaisInteresPieza
    @id_pieza INT,
    @id_pais INT,
    @accion VARCHAR(10) = 'INSERTAR' -- 'INSERTAR' o 'ELIMINAR'
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM publicidad.Pieza_Contenido WHERE ID = @id_pieza)
        THROW 50025, 'La pieza de contenido indicada no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @id_pais)
        THROW 50026, 'El país de interés indicado no existe.', 1;

    IF @accion NOT IN ('INSERTAR', 'ELIMINAR')
        THROW 50027, 'La acción debe ser INSERTAR o ELIMINAR.', 1;

    IF @accion = 'INSERTAR' AND EXISTS (
        SELECT 1 FROM publicidad.Pieza_Pais_Interes WHERE ID_Pieza = @id_pieza AND ID_Pais = @id_pais
    )
        THROW 50028, 'El país indicado ya se encuentra asociado como mercado de interés para esta pieza.', 1;

    IF @accion = 'ELIMINAR' AND NOT EXISTS (
        SELECT 1 FROM publicidad.Pieza_Pais_Interes WHERE ID_Pieza = @id_pieza AND ID_Pais = @id_pais
    )
        THROW 50028, 'El país indicado no se encuentra asociado a esta pieza.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        IF @accion = 'INSERTAR'
        BEGIN
            INSERT INTO publicidad.Pieza_Pais_Interes (ID_Pieza, ID_Pais)
            VALUES (@id_pieza, @id_pais);
        END
        ELSE IF @accion = 'ELIMINAR'
        BEGIN
            DELETE FROM publicidad.Pieza_Pais_Interes
            WHERE ID_Pieza = @id_pieza AND ID_Pais = @id_pais;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =========================================================================================
-- 6. ALGORITMO DE ASIGNACIÓN Y BAJA DE EXHIBICIÓN PUBLICITARIA (publicidad.Exhibicion)
-- =========================================================================================

/*
    Paso 1) El SP recibe el @id_partido, valida que existan sus 4 espacios publicitarios disponibles y toma los datos del partido (fecha_hora_local, fecha_hora_utc y los países de la selección local y visitante).
    Paso 2) Conversión de huso horario para cada mercado objetivo: según los países asociados a cada pieza en la tabla Pieza_Pais_Interes, convierte la hora UTC del partido al huso horario de cada país destino para determinar si cae en horario Prime Time (19:00 a 23:59 hs).
    Paso 3) Filtro de vigencia y evaluación de candidatas: entran como candidatas todas las piezas cuya campaña esté vigente en la fecha del partido (fecha_inicio <= fecha_partido <= fecha_fin), evaluando para cada una: si su país juega el partido, su PBI per cápita, si está en Prime Time y el costo de la pieza.
    Paso 4) Se establece un ranking (TOP 4) de las piezas más rentables/prioritarias ordenando por: 1° País participante en el partido, 2° Mayor PBI per cápita del mercado, 3° Horario Prime Time en el país destino y 4° Mayor costo de la pieza.
    Paso 5) Se asignan las 4 piezas ganadoras a los 4 espacios publicitarios del partido en la tabla Exhibicion, registrando el orden de prioridad (1, 2 o 3) y el monto facturado.
*/

CREATE OR ALTER PROCEDURE publicidad.sp_AsignarPublicidadPartido
    @id_partido INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_partido)
        THROW 50012, 'El partido indicado no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_partido)
        THROW 50013, 'Aún no se han generado los espacios (slots) para este partido.', 1;

    IF EXISTS (
        SELECT 1 FROM publicidad.Exhibicion ex 
        JOIN publicidad.Espacio_publicitario ep ON ex.ID_espacio = ep.ID 
        WHERE ep.ID_Partido = @id_partido
    )
        THROW 50014, 'La publicidad de este partido ya fue asignada previamente.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Tabla temporal para calcular puntajes por mercado de interés
        DECLARE @Puntajes TABLE (
            ID_Pieza INT,
            costo DECIMAL(12,2),
            es_pais_participante INT,
            pbi_percapita DECIMAL(12,2),
            es_prime_time INT
        );

        -- Se insertan en la tabla temporal 
        INSERT INTO @Puntajes (ID_Pieza, costo, es_pais_participante, pbi_percapita, es_prime_time)
        SELECT 
            pc.ID,
            pc.costo,
            CASE WHEN p.ID IN (sl.ID_Pais, sv.ID_Pais) THEN 1 ELSE 0 END,
            p.pbi_percapita,
            CASE WHEN DATEPART(HOUR, DATEADD(HOUR, CAST(SUBSTRING(p.huso_horario, 1, 3) AS INT), part.fecha_hora_utc)) BETWEEN 19 AND 23 THEN 1 ELSE 0 END
        FROM publicidad.Pieza_Contenido pc
        JOIN publicidad.Campania c ON c.ID = pc.ID_Campania
        JOIN publicidad.Pieza_Pais_Interes ppi ON ppi.ID_Pieza = pc.ID
        JOIN administracion.Pais p ON p.ID = ppi.ID_Pais
        JOIN partido.Partido part ON part.ID = @id_partido
        JOIN administracion.Seleccion sl ON sl.ID = part.ID_Seleccion_Local
        JOIN administracion.Seleccion sv ON sv.ID = part.ID_Seleccion_Visitante
        WHERE c.fecha_inicio <= CAST(part.fecha_hora_local AS DATE) 
          AND c.fecha_fin >= CAST(part.fecha_hora_local AS DATE);

        -- Tabla temporal para elegir las 4 mejores piezas candidatas
        DECLARE @Top4 TABLE (
            fila INT IDENTITY(1,1),
            ID_Pieza INT,
            orden_prioridad TINYINT,
            monto_facturado DECIMAL(12,2)
        );

        INSERT INTO @Top4 (ID_Pieza, orden_prioridad, monto_facturado)
        SELECT TOP 4
            ID_Pieza,
            CAST(CASE 
                WHEN MAX(es_pais_participante) = 1 THEN 1 
                WHEN MAX(pbi_percapita) > 30000 THEN 2
                WHEN MAX(es_prime_time) = 1 THEN 3
                ELSE 3 
            END AS TINYINT),
            MAX(costo)
        FROM @Puntajes
        GROUP BY ID_Pieza
        ORDER BY 
            MAX(es_pais_participante) DESC, 
            MAX(pbi_percapita) DESC, 
            MAX(es_prime_time) DESC, 
            MAX(costo) DESC;

        -- Insertar en la tabla de exhibición
        INSERT INTO publicidad.Exhibicion (ID_espacio, ID_Pieza, orden_prioridad, monto_facturado)
        SELECT 
            ep.ID,
            t.ID_Pieza,
            t.orden_prioridad,
            t.monto_facturado
        FROM @Top4 t
        JOIN (
            SELECT ID, ROW_NUMBER() OVER(ORDER BY numero_slot) AS fila 
            FROM publicidad.Espacio_publicitario 
            WHERE ID_Partido = @id_partido
        ) ep ON ep.fila = t.fila;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.sp_EliminarExhibicionPartido
    @id_partido INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM publicidad.Exhibicion ex
        JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio
        WHERE ep.ID_Partido = @id_partido
    )
        THROW 50029, 'No existen exhibiciones publicitarias asignadas para este partido.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE ex
        FROM publicidad.Exhibicion ex
        JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio
        WHERE ep.ID_Partido = @id_partido;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
