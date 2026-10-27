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
   Descripción: Módulo 3 - Goles, Tarjetas, Árbitros y Suspensiones.
                Implementación de SPs con ciclo ABM completo para árbitros, idiomas, designación arbitral
                con validación de nacionalidad neutral, goles con recálculo automático de marcador, tarjetas
                y gestión integral de suspensiones y cumplimiento de fechas (Partido_Perdido_Suspension).
*/

USE Mundial2026;
GO

-- =========================================================================================
-- 1. ABM DE ÁRBITROS E IDIOMAS (arbitraje.Arbitro y arbitraje.Idioma)
-- =========================================================================================

CREATE OR ALTER PROCEDURE arbitraje.sp_GestionarArbitro
    @Operacion VARCHAR(10), -- 'ALTA', 'MODIFICAR', 'BAJA'
    @ID INT = NULL OUTPUT,
    @Nombre VARCHAR(100) = NULL,
    @Apellido VARCHAR(100) = NULL,
    @Categoria VARCHAR(50) = NULL,
    @ID_Pais INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Operacion = 'ALTA'
    BEGIN
        IF @Nombre IS NULL OR @Apellido IS NULL OR @Categoria IS NULL OR @ID_Pais IS NULL
            THROW 50010, 'Para dar de alta un árbitro se deben completar todos los campos obligatorios.', 1;

        IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @ID_Pais)
            THROW 50016, 'El país indicado para el árbitro no existe en el sistema.', 1;

        BEGIN TRANSACTION;
        BEGIN TRY
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
    END
    ELSE IF @Operacion = 'MODIFICAR'
    BEGIN
        IF @ID IS NULL OR NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID)
            THROW 50011, 'El árbitro a modificar no existe.', 1;

        IF @ID_Pais IS NOT NULL AND NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE ID = @ID_Pais)
            THROW 50016, 'El país indicado para el árbitro no existe en el sistema.', 1;

        BEGIN TRANSACTION;
        BEGIN TRY
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
    END
    ELSE IF @Operacion = 'BAJA'
    BEGIN
        IF @ID IS NULL OR NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID)
            THROW 50012, 'El árbitro a eliminar no existe.', 1;

        -- Verificar si ya dirigió partidos
        IF EXISTS (SELECT 1 FROM arbitraje.Designacion_Arbitral WHERE ID_Arbitro = @ID)
            THROW 50013, 'No se puede eliminar el árbitro porque posee designaciones arbitrales registradas.', 1;

        BEGIN TRANSACTION;
        BEGIN TRY
            DELETE FROM arbitraje.Idioma WHERE ID_Arbitro = @ID;
            DELETE FROM arbitraje.Arbitro WHERE ID = @ID;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END
    ELSE
        THROW 50014, 'Operación no válida para la gestión de árbitros.', 1;
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.sp_GestionarIdiomaArbitro
    @ID_Arbitro INT,
    @Lengua VARCHAR(50),
    @Accion VARCHAR(10), -- 'INSERTAR', 'MODIFICAR', 'ELIMINAR'
    @NuevaLengua VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID_Arbitro)
        THROW 50015, 'El árbitro especificado no existe.', 1;

    IF @Lengua IS NULL OR LTRIM(RTRIM(@Lengua)) = '' OR @Accion NOT IN ('INSERTAR', 'MODIFICAR', 'ELIMINAR')
        THROW 50017, 'La lengua es obligatoria y la acción debe ser INSERTAR, MODIFICAR o ELIMINAR.', 1;

    IF @Accion = 'MODIFICAR' AND (@NuevaLengua IS NULL OR LTRIM(RTRIM(@NuevaLengua)) = '')
        THROW 50017, 'Para modificar un idioma debe especificar la nueva lengua.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        IF @Accion = 'INSERTAR'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM arbitraje.Idioma WHERE ID_Arbitro = @ID_Arbitro AND lengua = @Lengua)
            BEGIN
                INSERT INTO arbitraje.Idioma (lengua, ID_Arbitro) VALUES (@Lengua, @ID_Arbitro);
            END
        END
        ELSE IF @Accion = 'MODIFICAR'
        BEGIN
            UPDATE arbitraje.Idioma
            SET lengua = @NuevaLengua
            WHERE ID_Arbitro = @ID_Arbitro AND lengua = @Lengua;
        END
        ELSE IF @Accion = 'ELIMINAR'
        BEGIN
            DELETE FROM arbitraje.Idioma WHERE ID_Arbitro = @ID_Arbitro AND lengua = @Lengua;
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
-- 2. ABM DE DESIGNACIÓN ARBITRAL (arbitraje.Designacion_Arbitral)
-- =========================================================================================

CREATE OR ALTER PROCEDURE arbitraje.sp_DesignarArbitro
    @ID_Partido INT,
    @ID_Arbitro INT,
    @Rol VARCHAR(30),
    @Informe VARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID_Arbitro)
       OR NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
        THROW 50001, 'El árbitro o el partido especificado no existen.', 1;

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
        THROW 50002, 'Conflicto de nacionalidad estricto: Un árbitro no puede dirigir un partido de su propio país.', 1;

    -- Validar que el árbitro no esté ya designado en ese partido
    IF EXISTS (
        SELECT 1 FROM arbitraje.Designacion_Arbitral 
        WHERE ID_Partido = @ID_Partido AND ID_Arbitro = @ID_Arbitro
    )
        THROW 50003, 'El árbitro ya se encuentra designado para este partido.', 1;

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

CREATE OR ALTER PROCEDURE arbitraje.sp_ModificarDesignacionArbitro
    @ID_Partido INT,
    @ID_Arbitro INT,
    @Rol VARCHAR(30) = NULL,
    @Informe VARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM arbitraje.Designacion_Arbitral 
        WHERE ID_Partido = @ID_Partido AND ID_Arbitro = @ID_Arbitro
    )
        THROW 50008, 'No existe la designación arbitral especificada para modificar.', 1;

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

CREATE OR ALTER PROCEDURE arbitraje.sp_EliminarDesignacionArbitro
    @ID_Partido INT,
    @ID_Arbitro INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM arbitraje.Designacion_Arbitral 
        WHERE ID_Partido = @ID_Partido AND ID_Arbitro = @ID_Arbitro
    )
        THROW 50009, 'No existe la designación arbitral especificada para eliminar.', 1;

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

    -- Validar destinatario único
    IF (@ID_Jugador IS NOT NULL AND @ID_Cuerpo_Tecnico IS NOT NULL) OR (@ID_Jugador IS NULL AND @ID_Cuerpo_Tecnico IS NULL)
        THROW 50004, 'La tarjeta debe ser exclusivamente para un jugador o para un miembro del cuerpo técnico.', 1;

    -- Validar existencia del partido
    IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
        THROW 50005, 'El partido especificado no existe.', 1;

    -- Validar minuto reglamentario
    IF @Minuto <= 0 OR @Minuto > 140
        THROW 50018, 'El minuto de la tarjeta es inválido.', 1;

    -- Validar tipo de tarjeta
    IF @Tipo NOT IN ('AMARILLA', 'ROJA')
        THROW 50006, 'El tipo de tarjeta debe ser AMARILLA o ROJA.', 1;

    -- Validar que el destinatario pertenezca al partido antes de insertar
    IF @ID_Jugador IS NOT NULL
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM partido.Alineacion al
            JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
            WHERE fp.ID_Partido = @ID_Partido AND al.ID_Jugador = @ID_Jugador
        )
            THROW 50019, 'El jugador sancionado no está inscripto en la alineación oficial de este partido.', 1;
    END
    ELSE IF @ID_Cuerpo_Tecnico IS NOT NULL
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM administracion.Miembro_Cuerpo_Tecnico ct
            JOIN partido.Partido p ON p.ID = @ID_Partido
            WHERE ct.ID = @ID_Cuerpo_Tecnico
              AND (ct.ID_Seleccion = p.ID_Seleccion_Local OR ct.ID_Seleccion = p.ID_Seleccion_Visitante)
        )
            THROW 50007, 'El miembro del cuerpo técnico no existe o no pertenece a los equipos de este partido.', 1;
    END

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

CREATE OR ALTER PROCEDURE partido.sp_ModificarTarjeta
    @ID_Tarjeta INT,
    @Minuto SMALLINT = NULL,
    @Motivo VARCHAR(100) = NULL,
    @Tipo VARCHAR(10) = NULL,
    @Es_Doble_Amarilla BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM partido.Tarjeta WHERE ID = @ID_Tarjeta)
        THROW 50028, 'La tarjeta especificada no existe en el sistema.', 1;

    IF @Minuto IS NOT NULL AND (@Minuto <= 0 OR @Minuto > 140)
        THROW 50018, 'El minuto de la tarjeta es inválido.', 1;

    IF @Tipo IS NOT NULL AND @Tipo NOT IN ('AMARILLA', 'ROJA')
        THROW 50006, 'El tipo de tarjeta debe ser AMARILLA o ROJA.', 1;

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

CREATE OR ALTER PROCEDURE partido.sp_EliminarTarjeta
    @ID_Tarjeta INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM partido.Tarjeta WHERE ID = @ID_Tarjeta)
        THROW 50029, 'La tarjeta especificada no existe en el sistema.', 1;

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

CREATE OR ALTER PROCEDURE partido.sp_RegistrarCumplimientoSuspension
    @ID_Suspension INT,
    @ID_Partido_Perdido INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ID_Jugador INT, @ID_Partido_Origen INT, @Totales TINYINT, @Descontados TINYINT;
    SELECT 
        @ID_Jugador = ID_Jugador,
        @ID_Partido_Origen = ID_Partido,
        @Totales = partidos_totales,
        @Descontados = partidos_descontados
    FROM partido.Suspension
    WHERE ID = @ID_Suspension;

    IF @ID_Jugador IS NULL
        THROW 50030, 'La suspensión especificada no existe.', 1;

    IF @Descontados >= @Totales
        THROW 50031, 'La suspensión ya fue cumplida en su totalidad.', 1;

    IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido_Perdido)
        THROW 50032, 'El partido indicado para descontar la suspensión no existe.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM partido.Partido p
        JOIN administracion.Convocatoria c ON c.ID_Jugador = @ID_Jugador
        WHERE p.ID = @ID_Partido_Perdido
          AND (p.ID_Seleccion_Local = c.ID_Seleccion OR p.ID_Seleccion_Visitante = c.ID_Seleccion)
    )
        THROW 50032, 'La selección del jugador suspendido no participa en el partido indicado.', 1;

    IF @ID_Partido_Perdido <= @ID_Partido_Origen
        THROW 50032, 'El partido donde se cumple la sanción debe ser posterior al partido donde se originó.', 1;

    IF EXISTS (
        SELECT 1 FROM partido.Alineacion al
        JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
        WHERE fp.ID_Partido = @ID_Partido_Perdido AND al.ID_Jugador = @ID_Jugador
    )
        THROW 50033, 'El jugador figura alineado en ese partido, por lo que no puede computarse como fecha cumplida.', 1;

    IF EXISTS (
        SELECT 1 FROM partido.Partido_Perdido_Suspension
        WHERE ID_Suspension = @ID_Suspension AND ID_Partido = @ID_Partido_Perdido
    )
        THROW 50033, 'Este partido ya fue descontado previamente para esta suspensión.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
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

CREATE OR ALTER PROCEDURE partido.sp_ModificarSuspension
    @ID_Suspension INT,
    @Partidos_Totales TINYINT = NULL,
    @Motivo VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Descontados TINYINT;
    SELECT @Descontados = partidos_descontados FROM partido.Suspension WHERE ID = @ID_Suspension;

    IF @Descontados IS NULL
        THROW 50034, 'La suspensión especificada no existe.', 1;

    IF @Partidos_Totales IS NOT NULL AND @Partidos_Totales < @Descontados
        THROW 50035, 'La cantidad total de partidos de suspensión no puede ser menor a las fechas ya cumplidas.', 1;

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

CREATE OR ALTER PROCEDURE partido.sp_EliminarSuspension
    @ID_Suspension INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM partido.Suspension WHERE ID = @ID_Suspension)
        THROW 50036, 'La suspensión especificada no existe en el sistema.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
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

    -- Validar existencia de partido
    IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
        THROW 50020, 'El partido especificado no existe.', 1;

    -- Validar que la selección indicada participe en el partido
    IF NOT EXISTS (
        SELECT 1 FROM partido.Partido 
        WHERE ID = @ID_Partido AND (ID_Seleccion_Local = @ID_Seleccion OR ID_Seleccion_Visitante = @ID_Seleccion)
    )
        THROW 50024, 'La selección indicada no participa en este partido.', 1;

    -- Validar que el autor del gol esté inscripto en la alineación del partido
    IF NOT EXISTS (
        SELECT 1 
        FROM partido.Alineacion al
        JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
        WHERE fp.ID_Partido = @ID_Partido AND al.ID_Jugador = @ID_Jugador_autor
    )
        THROW 50021, 'El jugador autor del gol no está inscripto en la planilla/alineación de este partido.', 1;

    -- Validar minuto
    IF @Minuto <= 0 OR @Minuto > 140
        THROW 50025, 'El minuto del gol es inválido.', 1;

    -- Validar tipo y período del gol
    IF @Tipo NOT IN ('Jugada', 'Penal', 'Tiro Libre', 'En contra', 'Cabezazo')
        THROW 50037, 'El tipo de gol no es válido. Valores permitidos: Jugada, Penal, Tiro Libre, En contra, Cabezazo.', 1;

    IF @Periodo NOT IN ('Primer Tiempo', 'Segundo Tiempo', 'Adicionales', 'Alargue', 'Tiempo Extra', 'Definición por penales')
        THROW 50038, 'El período del gol no es válido.', 1;

    -- Validar jugadas sin asistencia
    IF @Tipo IN ('Penal', 'Tiro Libre', 'En contra') AND @ID_Jugador_asistencia IS NOT NULL
        THROW 50040, 'Los goles de penal, tiro libre o en contra no admiten jugador asistente.', 1;

    -- En Fase de Grupos no existen Alargue/Tiempo Extra ni Definición por penales
    IF @Periodo IN ('Alargue', 'Tiempo Extra', 'Definición por penales')
    BEGIN
        IF EXISTS (
            SELECT 1 FROM partido.Partido p
            JOIN administracion.Fase_Torneo ft ON ft.ID = p.ID_Fase
            WHERE p.ID = @ID_Partido AND (ft.orden = 1 OR ft.nombre LIKE '%Grupo%')
        )
            THROW 50042, 'No se admiten alargues ni definiciones por penales en partidos de Fase de Grupos.', 1;
    END

    -- Validar reglas específicas de Definición por penales
    IF @Periodo = 'Definición por penales'
    BEGIN
        IF @Tipo <> 'Penal'
            THROW 50041, 'En la definición por penales el tipo de gol debe ser exclusivamente Penal.', 1;

        IF EXISTS (
            SELECT 1 FROM partido.Partido
            WHERE ID = @ID_Partido AND ISNULL(goles_local, 0) <> ISNULL(goles_visitante, 0)
        )
            THROW 50043, 'Solo se puede registrar una definición por penales si el partido se encuentra empatado.', 1;
    END

    -- Validar asistencia si fue enviada
    IF @ID_Jugador_asistencia IS NOT NULL
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM partido.Alineacion al
            JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
            WHERE fp.ID_Partido = @ID_Partido AND al.ID_Jugador = @ID_Jugador_asistencia
        )
            THROW 50022, 'El jugador que asiste no está inscripto en la planilla/alineación de este partido.', 1;

        IF @ID_Jugador_asistencia = @ID_Jugador_autor
            THROW 50023, 'El autor del gol y el asistente no pueden ser el mismo jugador.', 1;
    END

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

    DECLARE @ID_Partido INT, @AutorActual INT;
    SELECT @ID_Partido = ID_Partido, @AutorActual = ID_Jugador_autor
    FROM partido.Gol WHERE ID = @ID_Gol;

    IF @ID_Partido IS NULL
        THROW 50026, 'El gol especificado no existe en el sistema.', 1;

    IF @Minuto IS NOT NULL AND (@Minuto <= 0 OR @Minuto > 140)
        THROW 50025, 'El minuto del gol es inválido.', 1;

    IF @Tipo IS NOT NULL AND @Tipo NOT IN ('Jugada', 'Penal', 'Tiro Libre', 'En contra', 'Cabezazo')
        THROW 50037, 'El tipo de gol no es válido. Valores permitidos: Jugada, Penal, Tiro Libre, En contra, Cabezazo.', 1;

    IF @Periodo IS NOT NULL AND @Periodo NOT IN ('Primer Tiempo', 'Segundo Tiempo', 'Adicionales', 'Alargue', 'Tiempo Extra', 'Definición por penales')
        THROW 50038, 'El período del gol no es válido.', 1;

    IF @ID_Jugador_autor IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM partido.Alineacion al
        JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
        WHERE fp.ID_Partido = @ID_Partido AND al.ID_Jugador = @ID_Jugador_autor
    )
        THROW 50021, 'El nuevo jugador autor del gol no está inscripto en la alineación de este partido.', 1;

    IF @ID_Jugador_asistencia IS NOT NULL
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM partido.Alineacion al
            JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
            WHERE fp.ID_Partido = @ID_Partido AND al.ID_Jugador = @ID_Jugador_asistencia
        )
            THROW 50022, 'El jugador asistente no está inscripto en la alineación de este partido.', 1;

        IF @ID_Jugador_asistencia = ISNULL(@ID_Jugador_autor, @AutorActual)
            THROW 50023, 'El autor del gol y el asistente no pueden ser el mismo jugador.', 1;
    END

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

CREATE OR ALTER PROCEDURE partido.sp_EliminarGol
    @ID_Gol INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ID_Partido INT;
    SELECT @ID_Partido = ID_Partido FROM partido.Gol WHERE ID = @ID_Gol;

    IF @ID_Partido IS NULL
        THROW 50027, 'El gol especificado no existe en el sistema.', 1;

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
