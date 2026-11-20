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
     
   Script: 01_cifrado_datos_sensibles.sql
   Ubicación: scripts/seguridad/01_cifrado_datos_sensibles.sql
   
   Descripción:
     
     1. Database Master Key (DMK) protegida por Service Master Key y contraseña.
     2. Certificado de Seguridad de Base de Datos (Cert_Mundial2026_Seguridad).
     3. Clave Simétrica AES-256 (Key_Mundial2026_AES256).
     4. Modificación de tablas sensibles y migración de datos existentes:
        - administracion.Jugador.fecha_nacimiento -> fecha_nacimiento_cifrada
        - administracion.Convocatoria.motivo -> motivo_cifrado
        - arbitraje.Designacion_Arbitral.informe -> informe_cifrado
     5. Actualización de todos los Stored Procedures afectados para encapsular
        el cifrado automático sin romper compatibilidad ni acumulación de errores.
     6. Procedimientos almacenados de consulta segura para datos sensibles descifrados.
     
   Aclaración sobre tests de entregas anteriores:
     - test_04_administracion.sql, test_05_partidos_y_cambios.sql y
       test_07_publicidad.sql pasan sin modificaciones luego de aplicar el cifrado.
     - test_06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql: si se ejecuta después de
       este script, falla únicamente el caso 17 (línea 287, sp_ModificarDesignacionArbitro),
       ya que valida en texto plano `informe = 'Informe final aprobado por comité.'`
       y dicha columna queda intencionalmente en NULL al guardarse cifrada en
       `informe_cifrado`.
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

PRINT '======================================================';
PRINT 'INICIANDO CONFIGURACIÓN DE CIFRADO DE DATOS SENSIBLES';
PRINT '======================================================';

-- ============================================================================
-- 1. CREACIÓN DE LA DATABASE MASTER KEY (DMK)
-- ============================================================================
PRINT '>> [1/5] Verificando Database Master Key (DMK)...';

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Mundial2026.Pass';
    PRINT '   OK: Database Master Key creada exitosamente.';
END
ELSE
BEGIN
    PRINT '   INFO: Database Master Key ya existe en la base de datos.';
END;
GO

-- ============================================================================
-- 2. CREACIÓN DEL CERTIFICADO DE SEGURIDAD
-- ============================================================================
PRINT '>> [2/5] Verificando Certificado de Seguridad...';

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'Cert_Mundial2026_Seguridad')
BEGIN
    CREATE CERTIFICATE Cert_Mundial2026_Seguridad
    WITH SUBJECT = 'Certificado de Cifrado para Datos Personales Sensibles - Mundial 2026',
         EXPIRY_DATE = '2035-12-31';
    PRINT '   OK: Certificado [Cert_Mundial2026_Seguridad] creado exitosamente.';
END
ELSE
BEGIN
    PRINT '   INFO: El Certificado [Cert_Mundial2026_Seguridad] ya existe.';
END;
GO

-- ============================================================================
-- 3. CREACIÓN DE LA CLAVE SIMÉTRICA (AES-256)
-- ============================================================================
PRINT '>> [3/5] Verificando Clave Simétrica AES-256...';

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'Key_Mundial2026_AES256')
BEGIN
    CREATE SYMMETRIC KEY Key_Mundial2026_AES256
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;
    PRINT '   OK: Clave Simétrica [Key_Mundial2026_AES256] (AES-256) creada exitosamente.';
END
ELSE
BEGIN
    PRINT '   INFO: La Clave Simétrica [Key_Mundial2026_AES256] ya existe.';
END;
GO

-- ============================================================================
-- 4. MODIFICACIÓN DE ESTRUCTURA DDL Y MIGRACIÓN DE DATOS EXISTENTES
-- ============================================================================
PRINT '>> [4/5] Modificando estructuras DDL (Jugador, Convocatoria, Designacion_Arbitral) y cifrando registros...';

-- 4.1. Agregar columnas cifradas si no existen
IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID('administracion.Jugador') AND name = 'fecha_nacimiento_cifrada'
)
BEGIN
    ALTER TABLE administracion.Jugador
    ADD fecha_nacimiento_cifrada VARBINARY(256) NULL;
    PRINT '   OK: Columna [fecha_nacimiento_cifrada] agregada a administracion.Jugador.';
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID('administracion.Convocatoria') AND name = 'motivo_cifrado'
)
BEGIN
    ALTER TABLE administracion.Convocatoria
    ADD motivo_cifrado VARBINARY(512) NULL;
    PRINT '   OK: Columna [motivo_cifrado] agregada a administracion.Convocatoria.';
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID('arbitraje.Designacion_Arbitral') AND name = 'informe_cifrado'
)
BEGIN
    ALTER TABLE arbitraje.Designacion_Arbitral
    ADD informe_cifrado VARBINARY(1200) NULL;
    PRINT '   OK: Columna [informe_cifrado] agregada a arbitraje.Designacion_Arbitral.';
END;
GO

-- 4.2. Permitir nulos en la columna original de Jugador para poder limpiarla en reposo
IF EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('administracion.Jugador') 
      AND name = 'fecha_nacimiento' 
      AND is_nullable = 0
)
BEGIN
    ALTER TABLE administracion.Jugador
    ALTER COLUMN fecha_nacimiento DATE NULL;
    PRINT '   OK: Columna [fecha_nacimiento] modificada para permitir NULL tras migración.';
END;
GO

-- 4.3. Migrar y cifrar todos los registros existentes que aún tengan texto plano
OPEN SYMMETRIC KEY Key_Mundial2026_AES256
DECRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;

UPDATE administracion.Jugador
SET fecha_nacimiento_cifrada = EncryptByKey(Key_GUID('Key_Mundial2026_AES256'), CONVERT(VARCHAR(10), fecha_nacimiento, 120)),
    fecha_nacimiento = NULL
WHERE fecha_nacimiento IS NOT NULL;

UPDATE administracion.Convocatoria
SET motivo_cifrado = EncryptByKey(Key_GUID('Key_Mundial2026_AES256'), motivo),
    motivo = NULL
WHERE motivo IS NOT NULL;

UPDATE arbitraje.Designacion_Arbitral
SET informe_cifrado = EncryptByKey(Key_GUID('Key_Mundial2026_AES256'), informe),
    informe = NULL
WHERE informe IS NOT NULL;

CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;

PRINT '   OK: Datos sensibles existentes cifrados en almacenamiento físico (disco).';
GO

-- ============================================================================
-- 5. ACTUALIZACIÓN DE STORED PROCEDURES (ALTA, MODIFICACIÓN Y CONSULTA SEGURA)
-- ============================================================================
PRINT '>> [5/5] Actualizando Stored Procedures de Jugador con soporte de cifrado...';
GO

-- 5.1. Procedimiento de Alta de Jugador con Cifrado Automático
CREATE OR ALTER PROCEDURE administracion.sp_InsertarJugador
    @nombre VARCHAR(100),
    @apellido VARCHAR(100),
    @fecha_nacimiento DATE,
    @id_club INT,
    @posicion_habitual VARCHAR(30),
    @id_generado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validaciones de nombres
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50060) El nombre del jugador no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50060;
    END

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
    BEGIN
        SET @mensaje_error += '(50061) El apellido del jugador no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50061;
    END

    -- Validar fecha de nacimiento no futura
    IF @fecha_nacimiento IS NULL OR @fecha_nacimiento > CAST(GETDATE() AS DATE)
    BEGIN
        SET @mensaje_error += '(50062) La fecha de nacimiento no es válida o es futura. ';
        IF @codigo_error = 0 SET @codigo_error = 50062;
    END

    -- Validar edad mínima reglamentaria (al menos 15 años)
    IF @fecha_nacimiento IS NOT NULL AND @fecha_nacimiento <= CAST(GETDATE() AS DATE)
       AND DATEDIFF(YEAR, @fecha_nacimiento, GETDATE()) < 15
    BEGIN
        SET @mensaje_error += '(50063) El jugador debe tener al menos 15 años de edad. ';
        IF @codigo_error = 0 SET @codigo_error = 50063;
    END

    -- Validar club de procedencia
    IF @id_club IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Club WHERE ID = @id_club)
    BEGIN
        SET @mensaje_error += '(50064) El club asignado al jugador no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50064;
    END

    -- Validar posición habitual válida
    IF @posicion_habitual IS NULL OR UPPER(LTRIM(RTRIM(@posicion_habitual))) NOT IN ('ARQUERO', 'DEFENSOR', 'MEDIOCAMPISTA', 'DELANTERO')
    BEGIN
        SET @mensaje_error += '(50065) La posición habitual debe ser: Arquero, Defensor, Mediocampista o Delantero. ';
        IF @codigo_error = 0 SET @codigo_error = 50065;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    -- Abrir clave simétrica para cifrar el dato sensible antes de persistir
    OPEN SYMMETRIC KEY Key_Mundial2026_AES256
    DECRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;

    DECLARE @fecha_cifrada VARBINARY(256);
    SET @fecha_cifrada = EncryptByKey(Key_GUID('Key_Mundial2026_AES256'), CONVERT(VARCHAR(10), @fecha_nacimiento, 120));

    INSERT INTO administracion.Jugador (nombre, apellido, fecha_nacimiento, fecha_nacimiento_cifrada, ID_Club, posicion_habitual)
    VALUES (LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@apellido)), NULL, @fecha_cifrada, @id_club, LTRIM(RTRIM(@posicion_habitual)));

    SET @id_generado = SCOPE_IDENTITY();

    CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
END;
GO

-- 5.2. Procedimiento de Modificación de Jugador con Cifrado Automático
CREATE OR ALTER PROCEDURE administracion.sp_ModificarJugador
    @id INT,
    @nombre VARCHAR(100),
    @apellido VARCHAR(100),
    @fecha_nacimiento DATE,
    @id_club INT,
    @posicion_habitual VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    -- Validar existencia
    IF @id IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id)
    BEGIN
        SET @mensaje_error += '(50066) El ID de jugador especificado no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50066;
    END

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SET @mensaje_error += '(50060) El nombre del jugador no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50060;
    END

    IF @apellido IS NULL OR LTRIM(RTRIM(@apellido)) = ''
    BEGIN
        SET @mensaje_error += '(50061) El apellido del jugador no puede estar vacío. ';
        IF @codigo_error = 0 SET @codigo_error = 50061;
    END

    IF @fecha_nacimiento IS NULL OR @fecha_nacimiento > CAST(GETDATE() AS DATE)
    BEGIN
        SET @mensaje_error += '(50062) La fecha de nacimiento no es válida o es futura. ';
        IF @codigo_error = 0 SET @codigo_error = 50062;
    END

    IF @fecha_nacimiento IS NOT NULL AND @fecha_nacimiento <= CAST(GETDATE() AS DATE)
       AND DATEDIFF(YEAR, @fecha_nacimiento, GETDATE()) < 15
    BEGIN
        SET @mensaje_error += '(50063) El jugador debe tener al menos 15 años de edad. ';
        IF @codigo_error = 0 SET @codigo_error = 50063;
    END

    IF @id_club IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Club WHERE ID = @id_club)
    BEGIN
        SET @mensaje_error += '(50064) El club asignado al jugador no existe. ';
        IF @codigo_error = 0 SET @codigo_error = 50064;
    END

    IF @posicion_habitual IS NULL OR UPPER(LTRIM(RTRIM(@posicion_habitual))) NOT IN ('ARQUERO', 'DEFENSOR', 'MEDIOCAMPISTA', 'DELANTERO')
    BEGIN
        SET @mensaje_error += '(50065) La posición habitual debe ser: Arquero, Defensor, Mediocampista o Delantero. ';
        IF @codigo_error = 0 SET @codigo_error = 50065;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    -- Abrir clave simétrica para actualizar con el nuevo valor cifrado
    OPEN SYMMETRIC KEY Key_Mundial2026_AES256
    DECRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;

    DECLARE @fecha_cifrada VARBINARY(256);
    SET @fecha_cifrada = EncryptByKey(Key_GUID('Key_Mundial2026_AES256'), CONVERT(VARCHAR(10), @fecha_nacimiento, 120));

    UPDATE administracion.Jugador
    SET nombre = LTRIM(RTRIM(@nombre)),
        apellido = LTRIM(RTRIM(@apellido)),
        fecha_nacimiento = NULL,
        fecha_nacimiento_cifrada = @fecha_cifrada,
        ID_Club = @id_club,
        posicion_habitual = LTRIM(RTRIM(@posicion_habitual))
    WHERE ID = @id;

    CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
END;
GO

-- 5.3. Procedimiento Almacenado de Consulta Segura (Desencriptación controlada)
CREATE OR ALTER PROCEDURE administracion.sp_ConsultarJugadorSensible
    @ID_Jugador INT = NULL -- Si es NULL, lista todos los jugadores con su fecha desencriptada
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que el jugador exista si se pasó el parámetro
    IF @ID_Jugador IS NOT NULL AND NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @ID_Jugador)
        THROW 50066, '(50066) El ID de jugador especificado no existe.', 1;

    -- Abrir la clave simétrica mediante el certificado
    OPEN SYMMETRIC KEY Key_Mundial2026_AES256
    DECRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;

    SELECT 
        j.ID AS ID_Jugador,
        j.apellido + ', ' + j.nombre AS Jugador,
        c.nombre AS Club,
        j.posicion_habitual AS Posicion,
        -- Desencriptación y casteo seguro a DATE
        CONVERT(DATE, CONVERT(VARCHAR(10), DecryptByKey(j.fecha_nacimiento_cifrada))) AS Fecha_Nacimiento_Desencriptada,
        -- Muestra de cómo reside el dato en el disco (cifrado en binario)
        j.fecha_nacimiento_cifrada AS Valor_En_Disco_Cifrado
    FROM administracion.Jugador j
    INNER JOIN administracion.Club c ON c.ID = j.ID_Club
    WHERE (@ID_Jugador IS NULL OR j.ID = @ID_Jugador);

    -- Cerrar siempre la clave simétrica
    CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
END;
GO

-- ============================================================================
-- 5.4. ACTUALIZACIÓN DE SPs DE CONVOCATORIA (CIFRADO DE MOTIVOS MÉDICOS DE BAJA)
-- ============================================================================
CREATE OR ALTER PROCEDURE administracion.sp_RegistrarBajaConvocatoria
    @id_jugador INT,
    @motivo VARCHAR(255),
    @fecha DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    IF @fecha IS NULL
        SET @fecha = CAST(GETDATE() AS DATE);

    IF @motivo IS NULL OR LTRIM(RTRIM(@motivo)) = ''
    BEGIN
        SET @mensaje_error += '(50076) Debe especificar el motivo médico o justificación de la baja. ';
        IF @codigo_error = 0 SET @codigo_error = 50076;
    END

    IF @id_jugador IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jugador AND estado = 1)
    BEGIN
        SET @mensaje_error += '(50077) El jugador no posee una convocatoria activa para dar de baja. ';
        IF @codigo_error = 0 SET @codigo_error = 50077;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    OPEN SYMMETRIC KEY Key_Mundial2026_AES256
    DECRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;

    UPDATE administracion.Convocatoria
    SET estado = 0,
        motivo = NULL,
        motivo_cifrado = EncryptByKey(Key_GUID('Key_Mundial2026_AES256'), LTRIM(RTRIM(@motivo))),
        fecha = @fecha
    WHERE ID_Jugador = @id_jugador 
      AND estado = 1;

    CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
END;
GO

CREATE OR ALTER PROCEDURE administracion.sp_ReemplazarConvocadoUltimoMomento
    @id_jugador_lesionado INT,
    @id_jugador_reemplazo INT,
    @motivo_lesion VARCHAR(255),
    @dorsal_nuevo TINYINT = NULL,
    @id_convocatoria_nueva INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

    IF @motivo_lesion IS NULL OR LTRIM(RTRIM(@motivo_lesion)) = ''
    BEGIN
        SET @mensaje_error += '(50076) Debe especificar el informe médico de la lesión para autorizar el reemplazo. ';
        IF @codigo_error = 0 SET @codigo_error = 50076;
    END

    IF @id_jugador_lesionado IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jugador_lesionado AND estado = 1)
    BEGIN
        SET @mensaje_error += '(50077) El jugador a reemplazar no posee una convocatoria activa en ninguna selección. ';
        IF @codigo_error = 0 SET @codigo_error = 50077;
    END

    IF @id_jugador_reemplazo IS NULL OR NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id_jugador_reemplazo)
    BEGIN
        SET @mensaje_error += '(50070) El jugador sustituto no existe en el sistema. ';
        IF @codigo_error = 0 SET @codigo_error = 50070;
    END

    IF @id_jugador_reemplazo IS NOT NULL AND EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jugador_reemplazo)
    BEGIN
        SET @mensaje_error += '(50073) El jugador sustituto ya cuenta con una convocatoria previa registrada. ';
        IF @codigo_error = 0 SET @codigo_error = 50073;
    END

    DECLARE @id_seleccion INT, @dorsal_heredado TINYINT;
    SELECT @id_seleccion = ID_Seleccion, @dorsal_heredado = dorsal
    FROM administracion.Convocatoria
    WHERE ID_Jugador = @id_jugador_lesionado AND estado = 1;

    DECLARE @dorsal_final TINYINT = COALESCE(@dorsal_nuevo, @dorsal_heredado);

    IF @dorsal_final IS NOT NULL AND @dorsal_final NOT BETWEEN 1 AND 26
    BEGIN
        SET @mensaje_error += '(50072) El dorsal asignado debe ser un número entero entre 1 y 26. ';
        IF @codigo_error = 0 SET @codigo_error = 50072;
    END

    IF @id_seleccion IS NOT NULL AND @dorsal_final IS NOT NULL
       AND EXISTS (SELECT 1 FROM administracion.Convocatoria 
                   WHERE ID_Seleccion = @id_seleccion 
                     AND dorsal = @dorsal_final 
                     AND estado = 1 
                     AND ID_Jugador <> @id_jugador_lesionado)
    BEGIN
        SET @mensaje_error += '(50074) El dorsal solicitado ya está ocupado por otro jugador activo de la selección. ';
        IF @codigo_error = 0 SET @codigo_error = 50074;
    END

    IF @codigo_error <> 0
        THROW @codigo_error, @mensaje_error, 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        OPEN SYMMETRIC KEY Key_Mundial2026_AES256
        DECRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;

        UPDATE administracion.Convocatoria
        SET estado = 0,
            motivo = NULL,
            motivo_cifrado = EncryptByKey(Key_GUID('Key_Mundial2026_AES256'), LTRIM(RTRIM(@motivo_lesion))),
            fecha = CAST(GETDATE() AS DATE)
        WHERE ID_Jugador = @id_jugador_lesionado 
          AND estado = 1;

        CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;

        INSERT INTO administracion.Convocatoria (ID_Jugador, ID_Seleccion, estado, dorsal, fecha, motivo, motivo_cifrado)
        VALUES (@id_jugador_reemplazo, @id_seleccion, 1, @dorsal_final, NULL, NULL, NULL);

        SET @id_convocatoria_nueva = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'Key_Mundial2026_AES256')
            CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE administracion.sp_ConsultarBajasMedicasSensibles
AS
BEGIN
    SET NOCOUNT ON;

    OPEN SYMMETRIC KEY Key_Mundial2026_AES256
    DECRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;

    SELECT
        p.nombre AS Seleccion,
        j.apellido + ', ' + j.nombre AS Jugador_Dado_De_Baja,
        co.dorsal AS Dorsal,
        co.fecha AS Fecha_Baja,
        CONVERT(VARCHAR(255), DecryptByKey(co.motivo_cifrado)) AS Motivo_Medico_Desencriptado,
        co.motivo_cifrado AS Motivo_En_Disco_Cifrado
    FROM administracion.Convocatoria co
    INNER JOIN administracion.Jugador j ON j.ID = co.ID_Jugador
    INNER JOIN administracion.Seleccion s ON s.ID = co.ID_Seleccion
    INNER JOIN administracion.Pais p ON p.ID = s.ID_Pais
    WHERE co.estado = 0;

    CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
END;
GO

-- ============================================================================
-- 5.5. ACTUALIZACIÓN DE SPs DE ARBITRAJE (CIFRADO DE INFORMES POST-PARTIDO)
-- ============================================================================
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

    IF NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID_Arbitro)
       OR NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
    BEGIN
        SET @mensaje_error += '(50001) El árbitro o el partido especificado no existen. ';
        IF @codigo_error = 0 SET @codigo_error = 50001;
    END

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

    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @inf_cifrado VARBINARY(1200) = NULL;
        IF @Informe IS NOT NULL
        BEGIN
            OPEN SYMMETRIC KEY Key_Mundial2026_AES256
            DECRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;

            SET @inf_cifrado = EncryptByKey(Key_GUID('Key_Mundial2026_AES256'), @Informe);

            CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
        END

        INSERT INTO arbitraje.Designacion_Arbitral (ID_Partido, ID_Arbitro, rol, informe, informe_cifrado)
        VALUES (@ID_Partido, @ID_Arbitro, @Rol, NULL, @inf_cifrado);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'Key_Mundial2026_AES256')
            CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
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
    DECLARE @mensaje_error VARCHAR(2000) = '';
    DECLARE @codigo_error INT = 0;

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
        DECLARE @inf_cifrado VARBINARY(1200) = NULL;
        IF @Informe IS NOT NULL
        BEGIN
            OPEN SYMMETRIC KEY Key_Mundial2026_AES256
            DECRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;

            SET @inf_cifrado = EncryptByKey(Key_GUID('Key_Mundial2026_AES256'), @Informe);

            CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
        END

        UPDATE arbitraje.Designacion_Arbitral
        SET rol = ISNULL(@Rol, rol),
            informe = NULL,
            informe_cifrado = ISNULL(@inf_cifrado, informe_cifrado)
        WHERE ID_Partido = @ID_Partido AND ID_Arbitro = @ID_Arbitro;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'Key_Mundial2026_AES256')
            CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.sp_ConsultarInformesArbitrales
    @ID_Partido INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ID_Partido IS NOT NULL AND NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
        THROW 50001, '(50001) El partido especificado no existe en el sistema.', 1;

    OPEN SYMMETRIC KEY Key_Mundial2026_AES256
    DECRYPTION BY CERTIFICATE Cert_Mundial2026_Seguridad;

    SELECT
        da.ID_Partido AS Nro_Partido,
        a.apellido + ', ' + a.nombre AS Arbitro,
        da.rol AS Rol_Designado,
        CONVERT(VARCHAR(1000), DecryptByKey(da.informe_cifrado)) AS Informe_Desencriptado,
        da.informe_cifrado AS Informe_En_Disco_Cifrado
    FROM arbitraje.Designacion_Arbitral da
    INNER JOIN arbitraje.Arbitro a ON a.ID = da.ID_Arbitro
    WHERE (@ID_Partido IS NULL OR da.ID_Partido = @ID_Partido)
      AND da.informe_cifrado IS NOT NULL;

    CLOSE SYMMETRIC KEY Key_Mundial2026_AES256;
END;
GO

PRINT '======================================================================';
PRINT '¡CONFIGURACIÓN DE CIFRADO COMPLETADA CON ÉXITO!';
PRINT 'Cifrado AES-256 activo en: Jugador (fecha_nacimiento), Convocatoria (motivo) y Designacion_Arbitral (informe).';
PRINT '======================================================================';
GO
