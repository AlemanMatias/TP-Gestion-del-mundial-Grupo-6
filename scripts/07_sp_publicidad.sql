/*
  Entrega 5 - Bases de Datos Aplicada - Comisión 02-5600
  Fecha: Octubre 2026
  Integrantes: Aleman Flores Matias, Gamarra Bravo Sidney, Perreira Carlos, Villa Brenda
  Descripción:
     Implementación de Stored Procedures (ABM) para el esquema 'publicidad'.
     Generación de espacios publicitarios y asignación de publicidad.
*/

USE Mundial2026;
GO

-- =========================================================================================
-- SP: Generar espacios publicitarios para un partido
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_GenerarEspaciosPartido
    @id_partido INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_partido)
        THROW 50001, 'El partido indicado no existe.', 1;

    IF EXISTS (SELECT 1 FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_partido)
        THROW 50002, 'Los espacios publicitarios ya fueron generados previamente para este partido.', 1;

    INSERT INTO publicidad.Espacio_publicitario (nombre, numero_slot, ID_Partido)
    VALUES 
        ('Panel Perimetral Norte', 1, @id_partido),
        ('Panel Perimetral Sur', 2, @id_partido),
        ('Panel Perimetral Este', 3, @id_partido),
        ('Panel Perimetral Oeste', 4, @id_partido);
END;
GO

-- =========================================================================================
-- SP: Registrar o modificar Anunciante
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_RegistrarAnunciante
    @id INT = NULL,
    @nombre VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF LTRIM(RTRIM(@nombre)) = ''
        THROW 50003, 'El nombre del anunciante no puede estar vacío.', 1;

    IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE ID = @id)
        THROW 50004, 'El anunciante que intenta modificar no existe.', 1;

    IF EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE nombre = @nombre AND (@id IS NULL OR ID <> @id))
        THROW 50005, 'Ya existe un anunciante registrado con ese nombre.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @id IS NULL
            INSERT INTO publicidad.Anunciante (nombre) VALUES (LTRIM(RTRIM(@nombre)));
        ELSE
            UPDATE publicidad.Anunciante SET nombre = LTRIM(RTRIM(@nombre)) WHERE ID = @id;
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =========================================================================================
-- SP: Registrar o modificar Campaña
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_RegistrarCampania
    @id INT = NULL,
    @nombre VARCHAR(100),
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @id_anunciante INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @fecha_inicio > @fecha_fin
        THROW 50006, 'La fecha de inicio de la campaña no puede ser posterior a la fecha de fin.', 1;
    
    IF NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE ID = @id_anunciante)
        THROW 50007, 'El anunciante referenciado no existe en el sistema.', 1;

    IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE ID = @id)
        THROW 50008, 'La campaña que intenta modificar no existe.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @id IS NULL
            INSERT INTO publicidad.Campania (nombre, fecha_inicio, fecha_fin, ID_Anunciante)
            VALUES (LTRIM(RTRIM(@nombre)), @fecha_inicio, @fecha_fin, @id_anunciante);
        ELSE
            UPDATE publicidad.Campania 
            SET nombre = LTRIM(RTRIM(@nombre)), 
                fecha_inicio = @fecha_inicio, 
                fecha_fin = @fecha_fin, 
                ID_Anunciante = @id_anunciante
            WHERE ID = @id;
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =========================================================================================
-- SP: Registrar o modificar Pieza de Contenido
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_RegistrarPiezaContenido
    @id INT = NULL,
    @nombre VARCHAR(100),
    @idioma VARCHAR(30),
    @costo DECIMAL(12,2),
    @id_campania INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @costo < 0
        THROW 50009, 'El costo de la pieza publicitaria no puede ser negativo.', 1;

    IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE ID = @id_campania)
        THROW 50010, 'La campaña referenciada no existe.', 1;

    IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM publicidad.Pieza_Contenido WHERE ID = @id)
        THROW 50011, 'La pieza de contenido que intenta modificar no existe.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF @id IS NULL
            INSERT INTO publicidad.Pieza_Contenido (nombre, idioma, costo, ID_Campania)
            VALUES (LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@idioma)), @costo, @id_campania);
        ELSE
            UPDATE publicidad.Pieza_Contenido 
            SET nombre = LTRIM(RTRIM(@nombre)), 
                idioma = LTRIM(RTRIM(@idioma)), 
                costo = @costo, 
                ID_Campania = @id_campania
            WHERE ID = @id;
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =========================================================================================
-- SP: Asignar publicidad a un partido (Algoritmo de Prioridad)
-- =========================================================================================
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

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Tabla temporal para calcular puntajes
        DECLARE @Puntajes TABLE (
            ID_Pieza INT,
            costo DECIMAL(12,2),
            es_pais_participante INT,
            pbi_percapita DECIMAL(12,2),
            es_prime_time INT
        );

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

        -- Tabla temporal para elegir las 4 mejores
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
    END CATCH
END;
GO