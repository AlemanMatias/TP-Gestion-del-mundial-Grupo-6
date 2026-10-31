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
     
   Script: 06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql
   Descripción: Goles, Tarjetas, Árbitros y Suspensiones.
                Implementación de SPs con ciclo ABM completo para árbitros, idiomas, designación arbitral
                con validación de nacionalidad neutral, goles con recálculo automático de marcador, tarjetas
                y gestión integral de suspensiones y cumplimiento de fechas.
*/

USE Mundial2026;
GO

-- ============================
-- 1. ABM DE ÁRBITROS E IDIOMAS
-- ============================

-- 1.1. ALTA DE ÁRBITRO
-- Registra un nuevo árbitro en el sistema validando datos obligatorios y existencia de su país de origen.
CREATE OR ALTER PROCEDURE arbitraje.sp_InsertarArbitro
    @Nombre VARCHAR(100),
    @Apellido VARCHAR(100),
    @Categoria VARCHAR(50),
    @ID_Pais INT,
    @ID INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar que todos los campos obligatorios estén informados
    IF @Nombre IS NULL OR LTRIM(RTRIM(@Nombre)) = ''
       OR @Apellido IS NULL OR LTRIM(RTRIM(@Apellido)) = ''
       OR @Categoria IS NULL OR LTRIM(RTRIM(@Categoria)) = ''
       OR @ID_Pais IS NULL
    BEGIN
        SET @mensaje_error += '(50010) Para dar de alta un árbitro se deben completar todos los campos obligatorios. ';
        IF @codigo_error = 0 SET @codigo_error = 50010;
    END

    -- Validar que el país de origen exista en administracion.Pais
    IF @ID_Pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @ID_Pais)
    BEGIN
        SET @mensaje_error += '(50016) El país indicado para el árbitro no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50016;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Inserción del árbitro y devolución del ID generado
        INSERT INTO arbitraje.Arbitro (nombre, apellido, categoria, ID_Pais)
        VALUES (@Nombre, @Apellido, @Categoria, @ID_Pais);

        SET @ID = SCOPE_IDENTITY();
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 1.2. MODIFICACIÓN DE ÁRBITRO
-- Actualiza los datos personales, categoría o país de un árbitro existente.
CREATE OR ALTER PROCEDURE arbitraje.sp_ModificarArbitro
    @ID INT,
    @Nombre VARCHAR(100) = NULL,
    @Apellido VARCHAR(100) = NULL,
    @Categoria VARCHAR(50) = NULL,
    @ID_Pais INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar que el árbitro exista
    IF @ID IS NULL OR NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID)
    BEGIN
        SET @mensaje_error += '(50011) El árbitro a modificar no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50011;
    END

    -- Validar que el nuevo país exista si fue informado
    IF @ID_Pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @ID_Pais)
    BEGIN
        SET @mensaje_error += '(50016) El país indicado para el árbitro no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50016;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Actualización parcial conservando los valores actuales si algún parámetro es NULL
        UPDATE arbitraje.Arbitro
        SET nombre = ISNULL(@Nombre, nombre),
            apellido = ISNULL(@Apellido, apellido),
            categoria = ISNULL(@Categoria, categoria),
            ID_Pais = ISNULL(@ID_Pais, ID_Pais)
        WHERE ID = @ID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 1.3. BAJA DE ÁRBITRO
-- Elimina un árbitro y sus idiomas asociados siempre que no posea designaciones arbitrales en partidos.
CREATE OR ALTER PROCEDURE arbitraje.sp_EliminarArbitro
    @ID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar que el árbitro exista
    IF @ID IS NULL OR NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID)
    BEGIN
        SET @mensaje_error += '(50012) El árbitro a eliminar no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50012;
    END

    -- Verificar que no tenga partidos asignados en arbitraje.Designacion_Arbitral
    IF EXISTS (SELECT 1 FROM arbitraje.Designacion_Arbitral WHERE ID_Arbitro = @ID)
    BEGIN
        SET @mensaje_error += '(50013) No se puede eliminar el árbitro porque posee designaciones arbitrales registradas. ';
        IF @codigo_error = 0 SET @codigo_error = 50013;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Eliminar primero sus idiomas asociados para mantener la integridad referencial
        DELETE FROM arbitraje.Idioma WHERE ID_Arbitro = @ID;
        DELETE FROM arbitraje.Arbitro WHERE ID = @ID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 1.4. ALTA DE IDIOMA DE ÁRBITRO
-- Asocia una nueva lengua a un árbitro existente verificando que no esté duplicada.
CREATE OR ALTER PROCEDURE arbitraje.sp_InsertarIdiomaArbitro
    @ID_Arbitro INT,
    @Lengua VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia del árbitro
    IF @ID_Arbitro IS NULL OR NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID_Arbitro)
    BEGIN
        SET @mensaje_error += '(50015) El árbitro especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50015;
    END

    -- Validar que la lengua sea informada
    IF @Lengua IS NULL OR LTRIM(RTRIM(@Lengua)) = ''
    BEGIN
        SET @mensaje_error += '(50017) La lengua es obligatoria. ';
        IF @codigo_error = 0 SET @codigo_error = 50017;
    END

    -- Validar que el árbitro no tenga ya cargado ese mismo idioma
    IF @ID_Arbitro IS NOT NULL AND @Lengua IS NOT NULL AND LTRIM(RTRIM(@Lengua)) <> ''
       AND EXISTS (SELECT 1 FROM arbitraje.Idioma WHERE ID_Arbitro = @ID_Arbitro AND lengua = @Lengua)
    BEGIN
        SET @mensaje_error += '(50014) El idioma especificado ya se encuentra registrado para este árbitro. ';
        IF @codigo_error = 0 SET @codigo_error = 50014;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO arbitraje.Idioma (lengua, ID_Arbitro)
        VALUES (@Lengua, @ID_Arbitro);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 1.5. MODIFICACIÓN DE IDIOMA DE ÁRBITRO
-- Reemplaza un idioma previamente registrado para un árbitro por una nueva lengua.
CREATE OR ALTER PROCEDURE arbitraje.sp_ModificarIdiomaArbitro
    @ID_Arbitro INT,
    @Lengua VARCHAR(50),
    @NuevaLengua VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia del árbitro y que tenga cargado el idioma a reemplazar
    IF @ID_Arbitro IS NULL OR NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID_Arbitro)
    BEGIN
        SET @mensaje_error += '(50015) El árbitro especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50015;
    END
    ELSE IF @Lengua IS NOT NULL AND NOT EXISTS (SELECT 1 FROM arbitraje.Idioma WHERE ID_Arbitro = @ID_Arbitro AND lengua = @Lengua)
    BEGIN
        SET @mensaje_error += '(50014) El árbitro no tiene registrado el idioma que se intenta modificar. ';
        IF @codigo_error = 0 SET @codigo_error = 50014;
    END

    -- Validar que tanto la lengua actual como la nueva lengua estén informadas
    IF @Lengua IS NULL OR LTRIM(RTRIM(@Lengua)) = '' OR @NuevaLengua IS NULL OR LTRIM(RTRIM(@NuevaLengua)) = ''
    BEGIN
        SET @mensaje_error += '(50017) Para modificar un idioma debe especificar la lengua actual y la nueva lengua. ';
        IF @codigo_error = 0 SET @codigo_error = 50017;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE arbitraje.Idioma
        SET lengua = @NuevaLengua
        WHERE ID_Arbitro = @ID_Arbitro AND lengua = @Lengua;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 1.6. BAJA DE IDIOMA DE ÁRBITRO
-- Desvincula un idioma registrado de un árbitro específico.
CREATE OR ALTER PROCEDURE arbitraje.sp_EliminarIdiomaArbitro
    @ID_Arbitro INT,
    @Lengua VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar que el árbitro exista y tenga registrado ese idioma
    IF @ID_Arbitro IS NULL OR NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID_Arbitro)
    BEGIN
        SET @mensaje_error += '(50015) El árbitro especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50015;
    END
    ELSE IF @Lengua IS NULL OR NOT EXISTS (SELECT 1 FROM arbitraje.Idioma WHERE ID_Arbitro = @ID_Arbitro AND lengua = @Lengua)
    BEGIN
        SET @mensaje_error += '(50014) El idioma especificado no se encuentra registrado para este árbitro. ';
        IF @codigo_error = 0 SET @codigo_error = 50014;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM arbitraje.Idioma
        WHERE ID_Arbitro = @ID_Arbitro AND lengua = @Lengua;

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
-- 2. ABM DE DESIGNACIÓN ARBITRAL (arbitraje.Designacion_Arbitral)
-- =========================================================================================

-- 2.1. DESIGNACIÓN DE ÁRBITRO A PARTIDO
-- Asigna un árbitro a un partido con su rol específico, controlando neutralidad de nacionalidad
-- (no puede compartir país con ninguna de las dos selecciones del partido) y que no esté duplicado.
CREATE OR ALTER PROCEDURE arbitraje.sp_DesignarArbitro
    @ID_Partido INT,
    @ID_Arbitro INT,
    @Rol VARCHAR(30),
    @Informe VARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia del árbitro y del partido
    IF NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID_Arbitro)
       OR NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
    BEGIN
        SET @mensaje_error += '(50001) El árbitro o el partido especificado no existen. ';
        IF @codigo_error = 0 SET @codigo_error = 50001;
    END

    -- Bloquear si el país del árbitro coincide con el país de la selección local o visitante
    IF EXISTS (
        SELECT 1 
        FROM partido.Partido p
        JOIN administracion.Seleccion sl ON sl.ID = p.ID_Seleccion_Local
        JOIN administracion.Seleccion sv ON sv.ID = p.ID_Seleccion_Visitante
        JOIN arbitraje.Arbitro a ON a.ID = @ID_Arbitro
        WHERE p.ID = @ID_Partido 
          AND (a.ID_Pais = sl.ID_Pais OR a.ID_Pais = sv.ID_Pais)
    )
    BEGIN
        SET @mensaje_error += '(50002) Conflicto de nacionalidad estricto: Un árbitro no puede dirigir un partido de su propio país. ';
        IF @codigo_error = 0 SET @codigo_error = 50002;
    END

    -- Validar que el árbitro no esté ya designado en ese partido
    IF EXISTS (
        SELECT 1 FROM arbitraje.Designacion_Arbitral 
        WHERE ID_Partido = @ID_Partido AND ID_Arbitro = @ID_Arbitro
    )
    BEGIN
        SET @mensaje_error += '(50003) El árbitro ya se encuentra designado para este partido. ';
        IF @codigo_error = 0 SET @codigo_error = 50003;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    -- A partir de dieciseisavos emitir advertencia si procede de un entorno cercano o cruzado
    DECLARE @OrdenFase SMALLINT;
    SELECT @OrdenFase = f.orden 
    FROM partido.Partido p
    JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase
    WHERE p.ID = @ID_Partido;

    IF @OrdenFase >= 2
    BEGIN
        PRINT 'ADVERTENCIA FIFA: El partido pertenece a una fase de eliminación directa (orden >= 2). Verifique posibles cruces futuros de confederación.';
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO arbitraje.Designacion_Arbitral (ID_Partido, ID_Arbitro, rol, informe)
        VALUES (@ID_Partido, @ID_Arbitro, @Rol, @Informe);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 2.2. MODIFICACIÓN DE DESIGNACIÓN ARBITRAL
-- Permite actualizar el rol o cargar/editar el informe arbitral post-partido de un árbitro designado.
CREATE OR ALTER PROCEDURE arbitraje.sp_ModificarDesignacionArbitro
    @ID_Partido INT,
    @ID_Arbitro INT,
    @Rol VARCHAR(30) = NULL,
    @Informe VARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar que la designación arbitral exista para ese partido y árbitro
    IF NOT EXISTS (
        SELECT 1 FROM arbitraje.Designacion_Arbitral 
        WHERE ID_Partido = @ID_Partido AND ID_Arbitro = @ID_Arbitro
    )
    BEGIN
        SET @mensaje_error += '(50008) No existe la designación arbitral especificada para modificar. ';
        IF @codigo_error = 0 SET @codigo_error = 50008;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE arbitraje.Designacion_Arbitral
        SET rol = ISNULL(@Rol, rol),
            informe = ISNULL(@Informe, informe)
        WHERE ID_Partido = @ID_Partido AND ID_Arbitro = @ID_Arbitro;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 2.3. BAJA DE DESIGNACIÓN ARBITRAL
-- Remueve la asignación de un árbitro en un partido determinado.
CREATE OR ALTER PROCEDURE arbitraje.sp_EliminarDesignacionArbitro
    @ID_Partido INT,
    @ID_Arbitro INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar que la designación exista antes de eliminarla
    IF NOT EXISTS (
        SELECT 1 FROM arbitraje.Designacion_Arbitral 
        WHERE ID_Partido = @ID_Partido AND ID_Arbitro = @ID_Arbitro
    )
    BEGIN
        SET @mensaje_error += '(50009) No existe la designación arbitral especificada para eliminar. ';
        IF @codigo_error = 0 SET @codigo_error = 50009;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM arbitraje.Designacion_Arbitral
        WHERE ID_Partido = @ID_Partido AND ID_Arbitro = @ID_Arbitro;

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
-- 3. ABM DE TARJETAS Y SUSPENSIONES (partido.Tarjeta, partido.Suspension y partido.Partido_Perdido_Suspension)
-- =========================================================================================

-- 3.1. REGISTRO DE TARJETA Y GENERACIÓN AUTOMÁTICA DE SUSPENSIÓN
-- Registra una tarjeta (AMARILLA o ROJA) para un jugador alineado o miembro del cuerpo técnico.
-- Si el sancionado es un jugador y recibe roja directa, doble amarilla o alcanza el umbral de amarillas
-- acumuladas en el torneo, genera automáticamente la sanción en partido.Suspension.
CREATE OR ALTER PROCEDURE partido.sp_RegistrarTarjetaYSuspension
    @ID_Partido INT,
    @ID_Jugador INT = NULL,
    @ID_Cuerpo_Tecnico INT = NULL,
    @Minuto SMALLINT,
    @Motivo VARCHAR(100),
    @Tipo VARCHAR(10), -- 'AMARILLA' o 'ROJA'
    @Es_Doble_Amarilla BIT = 0,
    @Partidos_Suspension INT = 1, -- parámetro para elegir cuántas fechas suspender (por defecto 1)
    @Umbral_Amarillas INT = 2 -- parámetro de acumulación de amarillas en el torneo para suspensión (por defecto 2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar destinatario único (exclusivamente jugador o miembro del cuerpo técnico, nunca ambos ni ninguno)
    IF (@ID_Jugador IS NOT NULL AND @ID_Cuerpo_Tecnico IS NOT NULL) OR (@ID_Jugador IS NULL AND @ID_Cuerpo_Tecnico IS NULL)
    BEGIN
        SET @mensaje_error += '(50004) La tarjeta debe ser exclusivamente para un jugador o para un miembro del cuerpo técnico. ';
        IF @codigo_error = 0 SET @codigo_error = 50004;
    END

    -- Validar existencia del partido
    IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
    BEGIN
        SET @mensaje_error += '(50005) El partido especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50005;
    END

    -- Validar minuto reglamentario (1 a 140 considerando adición y alargue)
    IF @Minuto <= 0 OR @Minuto > 140
    BEGIN
        SET @mensaje_error += '(50018) El minuto de la tarjeta es inválido. ';
        IF @codigo_error = 0 SET @codigo_error = 50018;
    END

    -- Validar tipo de tarjeta permitido
    IF @Tipo NOT IN ('AMARILLA', 'ROJA')
    BEGIN
        SET @mensaje_error += '(50006) El tipo de tarjeta debe ser AMARILLA o ROJA. ';
        IF @codigo_error = 0 SET @codigo_error = 50006;
    END

    -- Validar que el destinatario pertenezca al partido antes de insertar
    IF @ID_Jugador IS NOT NULL AND @ID_Cuerpo_Tecnico IS NULL
       AND EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM partido.Alineacion al
            JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
            WHERE fp.ID_Partido = @ID_Partido AND al.ID_Jugador = @ID_Jugador
        )
        BEGIN
            SET @mensaje_error += '(50019) El jugador sancionado no está inscripto en la alineación oficial de este partido. ';
            IF @codigo_error = 0 SET @codigo_error = 50019;
        END
    END
    ELSE IF @ID_Cuerpo_Tecnico IS NOT NULL AND @ID_Jugador IS NULL
         AND EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM administracion.Miembro_Cuerpo_Tecnico ct
            JOIN partido.Partido p ON p.ID = @ID_Partido
            WHERE ct.ID = @ID_Cuerpo_Tecnico
              AND (ct.ID_Seleccion = p.ID_Seleccion_Local OR ct.ID_Seleccion = p.ID_Seleccion_Visitante)
        )
        BEGIN
            SET @mensaje_error += '(50007) El miembro del cuerpo técnico no existe o no pertenece a los equipos de este partido. ';
            IF @codigo_error = 0 SET @codigo_error = 50007;
        END
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Insertar tarjeta
        INSERT INTO partido.Tarjeta (ID_Partido, ID_Jugador, ID_Miembro_Cuerpo_Tecnico, minuto, motivo, tipo, es_doble_amarilla)
        VALUES (@ID_Partido, @ID_Jugador, @ID_Cuerpo_Tecnico, @Minuto, @Motivo, @Tipo, @Es_Doble_Amarilla);

        -- Si es jugador, evaluar acumulación de amarillas o roja directa
        IF @ID_Jugador IS NOT NULL
        BEGIN
            DECLARE @TotalAmarillas INT;
            
            IF @Tipo = 'AMARILLA'
            BEGIN
                SELECT @TotalAmarillas = COUNT(*) 
                FROM partido.Tarjeta 
                WHERE ID_Jugador = @ID_Jugador AND tipo = 'AMARILLA';

                -- Si acumula el umbral de amarillas parametrizado (ej: 2 amarillas) o es doble amarilla, generar suspensión automática
                IF (@TotalAmarillas > 0 AND @TotalAmarillas % @Umbral_Amarillas = 0) OR @Es_Doble_Amarilla = 1
                BEGIN
                    INSERT INTO partido.Suspension (ID_Jugador, ID_Partido, partidos_totales, partidos_descontados, motivo)
                    VALUES (@ID_Jugador, @ID_Partido, @Partidos_Suspension, 0, 'Suspensión automática por acumulación de tarjetas amarillas o doble amarilla.');
                END
            END
            ELSE IF @Tipo = 'ROJA'
            BEGIN
                -- Roja directa con la cantidad de fechas elegida
                INSERT INTO partido.Suspension (ID_Jugador, ID_Partido, partidos_totales, partidos_descontados, motivo)
                VALUES (@ID_Jugador, @ID_Partido, @Partidos_Suspension, 0, 'Suspensión automática por expulsión con tarjeta roja directa.');
            END
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

-- 3.2. MODIFICACIÓN DE TARJETA
-- Permite corregir minuto, motivo, tipo o marca de doble amarilla de una tarjeta registrada.
CREATE OR ALTER PROCEDURE partido.sp_ModificarTarjeta
    @ID_Tarjeta INT,
    @Minuto SMALLINT = NULL,
    @Motivo VARCHAR(100) = NULL,
    @Tipo VARCHAR(10) = NULL,
    @Es_Doble_Amarilla BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar que la tarjeta exista
    IF NOT EXISTS (SELECT 1 FROM partido.Tarjeta WHERE ID = @ID_Tarjeta)
    BEGIN
        SET @mensaje_error += '(50028) La tarjeta especificada no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50028;
    END

    -- Validar rango de minuto si se envía
    IF @Minuto IS NOT NULL AND (@Minuto <= 0 OR @Minuto > 140)
    BEGIN
        SET @mensaje_error += '(50018) El minuto de la tarjeta es inválido. ';
        IF @codigo_error = 0 SET @codigo_error = 50018;
    END

    -- Validar tipo de tarjeta si se envía
    IF @Tipo IS NOT NULL AND @Tipo NOT IN ('AMARILLA', 'ROJA')
    BEGIN
        SET @mensaje_error += '(50006) El tipo de tarjeta debe ser AMARILLA o ROJA. ';
        IF @codigo_error = 0 SET @codigo_error = 50006;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE partido.Tarjeta
        SET minuto = ISNULL(@Minuto, minuto),
            motivo = ISNULL(@Motivo, motivo),
            tipo = ISNULL(@Tipo, tipo),
            es_doble_amarilla = ISNULL(@Es_Doble_Amarilla, es_doble_amarilla)
        WHERE ID = @ID_Tarjeta;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 3.3. BAJA DE TARJETA
-- Elimina una tarjeta registrada del sistema.
CREATE OR ALTER PROCEDURE partido.sp_EliminarTarjeta
    @ID_Tarjeta INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia de la tarjeta
    IF NOT EXISTS (SELECT 1 FROM partido.Tarjeta WHERE ID = @ID_Tarjeta)
    BEGIN
        SET @mensaje_error += '(50029) La tarjeta especificada no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50029;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM partido.Tarjeta WHERE ID = @ID_Tarjeta;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 3.4. REGISTRO DE CUMPLIMIENTO DE FECHA DE SUSPENSIÓN
-- Computa un partido posterior de la selección del jugador (en el que no fue alineado) como fecha cumplida,
-- asentando la trazabilidad en partido.Partido_Perdido_Suspension e incrementando partidos_descontados.
CREATE OR ALTER PROCEDURE partido.sp_RegistrarCumplimientoSuspension
    @ID_Suspension INT,
    @ID_Partido_Perdido INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    DECLARE @ID_Jugador INT, @ID_Partido_Origen INT, @Totales TINYINT, @Descontados TINYINT;
    SELECT 
        @ID_Jugador = ID_Jugador,
        @ID_Partido_Origen = ID_Partido,
        @Totales = partidos_totales,
        @Descontados = partidos_descontados
    FROM partido.Suspension
    WHERE ID = @ID_Suspension;

    -- Validar que la suspensión exista
    IF @ID_Jugador IS NULL
    BEGIN
        SET @mensaje_error += '(50030) La suspensión especificada no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50030;
    END

    -- Validar que la suspensión aún tenga fechas pendientes por cumplir
    IF @ID_Jugador IS NOT NULL AND @Descontados >= @Totales
    BEGIN
        SET @mensaje_error += '(50031) La suspensión ya fue cumplida en su totalidad. ';
        IF @codigo_error = 0 SET @codigo_error = 50031;
    END

    -- Validar existencia del partido donde se pretende descontar la fecha
    IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido_Perdido)
    BEGIN
        SET @mensaje_error += '(50032) El partido indicado para descontar la suspensión no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50032;
    END
    ELSE IF @ID_Jugador IS NOT NULL
    BEGIN
        -- Validar que la selección del jugador suspendido participe en ese partido
        IF NOT EXISTS (
            SELECT 1 FROM partido.Partido p
            JOIN administracion.Convocatoria c ON c.ID_Jugador = @ID_Jugador
            WHERE p.ID = @ID_Partido_Perdido
              AND (p.ID_Seleccion_Local = c.ID_Seleccion OR p.ID_Seleccion_Visitante = c.ID_Seleccion)
        )
        BEGIN
            SET @mensaje_error += '(50032) La selección del jugador suspendido no participa en el partido indicado. ';
            IF @codigo_error = 0 SET @codigo_error = 50032;
        END

        -- Validar que el partido donde cumple la sanción sea cronológicamente posterior al partido donde fue sancionado
        IF EXISTS (
            SELECT 1 FROM partido.Partido P_Perdido
            JOIN partido.Partido P_Origen ON P_Origen.ID = @ID_Partido_Origen
            WHERE P_Perdido.ID = @ID_Partido_Perdido
              AND P_Perdido.fecha_hora_local <= P_Origen.fecha_hora_local
        )
        BEGIN
            SET @mensaje_error += '(50032) El partido donde se cumple la sanción debe ser cronológicamente posterior al partido donde se originó. ';
            IF @codigo_error = 0 SET @codigo_error = 50032;
        END

        -- Validar que el jugador efectivamente no haya sido alineado en el partido que se descuenta
        IF EXISTS (
            SELECT 1 FROM partido.Alineacion al
            JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
            WHERE fp.ID_Partido = @ID_Partido_Perdido AND al.ID_Jugador = @ID_Jugador
        )
        BEGIN
            SET @mensaje_error += '(50033) El jugador figura alineado en ese partido, por lo que no puede computarse como fecha cumplida. ';
            IF @codigo_error = 0 SET @codigo_error = 50033;
        END

        -- Validar que este mismo partido no haya sido descontado antes para esta suspensión
        IF EXISTS (
            SELECT 1 FROM partido.Partido_Perdido_Suspension
            WHERE ID_Suspension = @ID_Suspension AND ID_Partido = @ID_Partido_Perdido
        )
        BEGIN
            SET @mensaje_error += '(50033) Este partido ya fue descontado previamente para esta suspensión. ';
            IF @codigo_error = 0 SET @codigo_error = 50033;
        END
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Registrar el partido perdido por suspensión y descontar una fecha en la sanción
        INSERT INTO partido.Partido_Perdido_Suspension (ID_Suspension, ID_Partido)
        VALUES (@ID_Suspension, @ID_Partido_Perdido);

        UPDATE partido.Suspension
        SET partidos_descontados = partidos_descontados + 1
        WHERE ID = @ID_Suspension;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 3.5. MODIFICACIÓN DE SUSPENSIÓN
-- Actualiza la cantidad total de fechas de sanción o el motivo disciplinario (sin ser menor a las ya cumplidas).
CREATE OR ALTER PROCEDURE partido.sp_ModificarSuspension
    @ID_Suspension INT,
    @Partidos_Totales TINYINT = NULL,
    @Motivo VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    DECLARE @Descontados TINYINT;
    SELECT @Descontados = partidos_descontados FROM partido.Suspension WHERE ID = @ID_Suspension;

    -- Validar que la suspensión exista
    IF @Descontados IS NULL
    BEGIN
        SET @mensaje_error += '(50034) La suspensión especificada no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50034;
    END

    -- Validar que el nuevo total de fechas no sea inferior a las fechas que el jugador ya cumplió
    IF @Descontados IS NOT NULL AND @Partidos_Totales IS NOT NULL AND @Partidos_Totales < @Descontados
    BEGIN
        SET @mensaje_error += '(50035) La cantidad total de partidos de suspensión no puede ser menor a las fechas ya cumplidas. ';
        IF @codigo_error = 0 SET @codigo_error = 50035;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE partido.Suspension
        SET partidos_totales = ISNULL(@Partidos_Totales, partidos_totales),
            motivo = ISNULL(@Motivo, motivo)
        WHERE ID = @ID_Suspension;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 3.6. BAJA DE SUSPENSIÓN
-- Elimina una suspensión y su historial de partidos perdidos asociados.
CREATE OR ALTER PROCEDURE partido.sp_EliminarSuspension
    @ID_Suspension INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia de la suspensión
    IF NOT EXISTS (SELECT 1 FROM partido.Suspension WHERE ID = @ID_Suspension)
    BEGIN
        SET @mensaje_error += '(50036) La suspensión especificada no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50036;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Borrar primero el detalle de partidos perdidos por integridad referencial
        DELETE FROM partido.Partido_Perdido_Suspension WHERE ID_Suspension = @ID_Suspension;
        DELETE FROM partido.Suspension WHERE ID = @ID_Suspension;

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
-- 4. ABM DE GOLES Y RECÁLCULO AUTOMÁTICO DE MARCADOR (partido.Gol)
-- =========================================================================================

-- 4.1. REGISTRO DE GOL Y ACTUALIZACIÓN AUTOMÁTICA DEL MARCADOR
-- Registra un gol validando que autor y asistente estén en la planilla del partido, minuto, tipo y período,
-- y recalcula automáticamente goles_local y goles_visitante en partido.Partido (excluyendo tanda de penales).
CREATE OR ALTER PROCEDURE partido.sp_RegistrarGol
    @ID_Partido INT,
    @ID_Jugador_autor INT,
    @ID_Jugador_asistencia INT = NULL,
    @ID_Seleccion INT,
    @Minuto SMALLINT,
    @Tipo VARCHAR(30), -- 'Jugada', 'Penal', 'Tiro Libre', 'En contra', 'Cabezazo'
    @Periodo VARCHAR(30) -- 'Primer Tiempo', 'Segundo Tiempo', 'Adicionales', 'Alargue', 'Tiempo Extra', 'Definición por penales'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia de partido
    IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
    BEGIN
        SET @mensaje_error += '(50020) El partido especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50020;
    END
    ELSE
    BEGIN
        -- Validar que la selección a la que se le computa el gol participe en el partido
        IF NOT EXISTS (
            SELECT 1 FROM partido.Partido 
            WHERE ID = @ID_Partido AND (ID_Seleccion_Local = @ID_Seleccion OR ID_Seleccion_Visitante = @ID_Seleccion)
        )
        BEGIN
            SET @mensaje_error += '(50024) La selección indicada no participa en este partido. ';
            IF @codigo_error = 0 SET @codigo_error = 50024;
        END

        -- Validar que el autor del gol esté inscripto en la alineación del partido
        IF NOT EXISTS (
            SELECT 1 
            FROM partido.Alineacion al
            JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
            WHERE fp.ID_Partido = @ID_Partido AND al.ID_Jugador = @ID_Jugador_autor
        )
        BEGIN
            SET @mensaje_error += '(50021) El jugador autor del gol no está inscripto en la planilla/alineación de este partido. ';
            IF @codigo_error = 0 SET @codigo_error = 50021;
        END
    END

    -- Validar minuto reglamentario
    IF @Minuto <= 0 OR @Minuto > 140
    BEGIN
        SET @mensaje_error += '(50025) El minuto del gol es inválido. ';
        IF @codigo_error = 0 SET @codigo_error = 50025;
    END

    -- Validar tipo y período del gol
    IF @Tipo NOT IN ('Jugada', 'Penal', 'Tiro Libre', 'En contra', 'Cabezazo')
    BEGIN
        SET @mensaje_error += '(50037) El tipo de gol no es válido. Valores permitidos: Jugada, Penal, Tiro Libre, En contra, Cabezazo. ';
        IF @codigo_error = 0 SET @codigo_error = 50037;
    END

    IF @Periodo NOT IN ('Primer Tiempo', 'Segundo Tiempo', 'Adicionales', 'Alargue', 'Tiempo Extra', 'Definición por penales')
    BEGIN
        SET @mensaje_error += '(50038) El período del gol no es válido. ';
        IF @codigo_error = 0 SET @codigo_error = 50038;
    END

    -- Validar jugadas de pelota parada o en contra que no admiten asistencia
    IF @Tipo IN ('Penal', 'Tiro Libre', 'En contra') AND @ID_Jugador_asistencia IS NOT NULL
    BEGIN
        SET @mensaje_error += '(50040) Los goles de penal, tiro libre o en contra no admiten jugador asistente. ';
        IF @codigo_error = 0 SET @codigo_error = 50040;
    END

    -- En Fase de Grupos no existen Alargue/Tiempo Extra ni Definición por penales
    IF @Periodo IN ('Alargue', 'Tiempo Extra', 'Definición por penales')
    BEGIN
        IF EXISTS (
            SELECT 1 FROM partido.Partido p
            JOIN administracion.Fase_Torneo ft ON ft.ID = p.ID_Fase
            WHERE p.ID = @ID_Partido AND (ft.orden = 1 OR ft.nombre LIKE '%Grupo%')
        )
        BEGIN
            SET @mensaje_error += '(50042) No se admiten alargues ni definiciones por penales en partidos de Fase de Grupos. ';
            IF @codigo_error = 0 SET @codigo_error = 50042;
        END
    END

    -- Validar reglas específicas de Definición por penales
    IF @Periodo = 'Definición por penales'
    BEGIN
        IF @Tipo <> 'Penal'
        BEGIN
            SET @mensaje_error += '(50041) En la definición por penales el tipo de gol debe ser exclusivamente Penal. ';
            IF @codigo_error = 0 SET @codigo_error = 50041;
        END

        IF EXISTS (
            SELECT 1 FROM partido.Partido
            WHERE ID = @ID_Partido AND ISNULL(goles_local, 0) <> ISNULL(goles_visitante, 0)
        )
        BEGIN
            SET @mensaje_error += '(50043) Solo se puede registrar una definición por penales si el partido se encuentra empatado. ';
            IF @codigo_error = 0 SET @codigo_error = 50043;
        END
    END

    -- Validar asistencia si fue enviada
    IF @ID_Jugador_asistencia IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
           AND NOT EXISTS (
               SELECT 1 
               FROM partido.Alineacion al
               JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
               WHERE fp.ID_Partido = @ID_Partido AND al.ID_Jugador = @ID_Jugador_asistencia
           )
        BEGIN
            SET @mensaje_error += '(50022) El jugador que asiste no está inscripto en la planilla/alineación de este partido. ';
            IF @codigo_error = 0 SET @codigo_error = 50022;
        END

        IF @ID_Jugador_asistencia = @ID_Jugador_autor
        BEGIN
            SET @mensaje_error += '(50023) El autor del gol y el asistente no pueden ser el mismo jugador. ';
            IF @codigo_error = 0 SET @codigo_error = 50023;
        END
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO partido.Gol (ID_Partido, ID_Jugador_autor, ID_Jugador_asistencia, ID_Seleccion, minuto, tipo, periodo)
        VALUES (@ID_Partido, @ID_Jugador_autor, @ID_Jugador_asistencia, @ID_Seleccion, @Minuto, @Tipo, @Periodo);

        -- Actualizar el marcador del partido (excluyendo la tanda de Definición por penales)
        UPDATE p
        SET goles_local = ISNULL((
                SELECT COUNT(*) FROM partido.Gol g
                WHERE g.ID_Partido = p.ID 
                  AND g.ID_Seleccion = p.ID_Seleccion_Local
                  AND g.periodo <> 'Definición por penales'
            ), 0),
            goles_visitante = ISNULL((
                SELECT COUNT(*) FROM partido.Gol g
                WHERE g.ID_Partido = p.ID 
                  AND g.ID_Seleccion = p.ID_Seleccion_Visitante
                  AND g.periodo <> 'Definición por penales'
            ), 0)
        FROM partido.Partido p
        WHERE p.ID = @ID_Partido;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 4.2. MODIFICACIÓN DE GOL
-- Permite corregir el jugador autor, asistente, minuto, tipo o período de un gol ya registrado.
CREATE OR ALTER PROCEDURE partido.sp_ModificarGol
    @ID_Gol INT,
    @ID_Jugador_autor INT = NULL,
    @ID_Jugador_asistencia INT = NULL,
    @Minuto SMALLINT = NULL,
    @Tipo VARCHAR(30) = NULL,
    @Periodo VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    DECLARE @ID_Partido INT, @AutorActual INT;
    SELECT @ID_Partido = ID_Partido, @AutorActual = ID_Jugador_autor
    FROM partido.Gol WHERE ID = @ID_Gol;

    -- Validar que el gol exista
    IF @ID_Partido IS NULL
    BEGIN
        SET @mensaje_error += '(50026) El gol especificado no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50026;
    END

    -- Validar rango de minuto si se envía
    IF @Minuto IS NOT NULL AND (@Minuto <= 0 OR @Minuto > 140)
    BEGIN
        SET @mensaje_error += '(50025) El minuto del gol es inválido. ';
        IF @codigo_error = 0 SET @codigo_error = 50025;
    END

    -- Validar tipo de gol si se envía
    IF @Tipo IS NOT NULL AND @Tipo NOT IN ('Jugada', 'Penal', 'Tiro Libre', 'En contra', 'Cabezazo')
    BEGIN
        SET @mensaje_error += '(50037) El tipo de gol no es válido. Valores permitidos: Jugada, Penal, Tiro Libre, En contra, Cabezazo. ';
        IF @codigo_error = 0 SET @codigo_error = 50037;
    END

    -- Validar período del gol si se envía
    IF @Periodo IS NOT NULL AND @Periodo NOT IN ('Primer Tiempo', 'Segundo Tiempo', 'Adicionales', 'Alargue', 'Tiempo Extra', 'Definición por penales')
    BEGIN
        SET @mensaje_error += '(50038) El período del gol no es válido. ';
        IF @codigo_error = 0 SET @codigo_error = 50038;
    END

    -- Validar que el nuevo autor esté en la alineación del partido
    IF @ID_Partido IS NOT NULL AND @ID_Jugador_autor IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM partido.Alineacion al
        JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
        WHERE fp.ID_Partido = @ID_Partido AND al.ID_Jugador = @ID_Jugador_autor
    )
    BEGIN
        SET @mensaje_error += '(50021) El nuevo jugador autor del gol no está inscripto en la alineación de este partido. ';
        IF @codigo_error = 0 SET @codigo_error = 50021;
    END

    -- Validar nuevo asistente si se envía
    IF @ID_Jugador_asistencia IS NOT NULL
    BEGIN
        IF @ID_Partido IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM partido.Alineacion al
            JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
            WHERE fp.ID_Partido = @ID_Partido AND al.ID_Jugador = @ID_Jugador_asistencia
        )
        BEGIN
            SET @mensaje_error += '(50022) El jugador asistente no está inscripto en la alineación de este partido. ';
            IF @codigo_error = 0 SET @codigo_error = 50022;
        END

        IF @ID_Jugador_asistencia = ISNULL(@ID_Jugador_autor, @AutorActual)
        BEGIN
            SET @mensaje_error += '(50023) El autor del gol y el asistente no pueden ser el mismo jugador. ';
            IF @codigo_error = 0 SET @codigo_error = 50023;
        END
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE partido.Gol
        SET ID_Jugador_autor = ISNULL(@ID_Jugador_autor, ID_Jugador_autor),
            ID_Jugador_asistencia = ISNULL(@ID_Jugador_asistencia, ID_Jugador_asistencia),
            minuto = ISNULL(@Minuto, minuto),
            tipo = ISNULL(@Tipo, tipo),
            periodo = ISNULL(@Periodo, periodo)
        WHERE ID = @ID_Gol;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- 4.3. BAJA DE GOL Y RECÁLCULO AUTOMÁTICO DEL MARCADOR
-- Elimina un gol (ej. anulado por VAR) y actualiza automáticamente goles_local y goles_visitante del partido.
CREATE OR ALTER PROCEDURE partido.sp_EliminarGol
    @ID_Gol INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    DECLARE @ID_Partido INT;
    SELECT @ID_Partido = ID_Partido FROM partido.Gol WHERE ID = @ID_Gol;

    -- Validar que el gol exista
    IF @ID_Partido IS NULL
    BEGIN
        SET @mensaje_error += '(50027) El gol especificado no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50027;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM partido.Gol WHERE ID = @ID_Gol;

        -- Recalcular automáticamente el marcador del partido tras anular el gol (excluyendo Definición por penales)
        UPDATE p
        SET goles_local = ISNULL((
                SELECT COUNT(*) FROM partido.Gol g
                WHERE g.ID_Partido = p.ID 
                  AND g.ID_Seleccion = p.ID_Seleccion_Local
                  AND g.periodo <> 'Definición por penales'
            ), 0),
            goles_visitante = ISNULL((
                SELECT COUNT(*) FROM partido.Gol g
                WHERE g.ID_Partido = p.ID 
                  AND g.ID_Seleccion = p.ID_Seleccion_Visitante
                  AND g.periodo <> 'Definición por penales'
            ), 0)
        FROM partido.Partido p
        WHERE p.ID = @ID_Partido;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
