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
     
   Fecha: 19/11/2026
   Script: 02_roles_y_permisos.sql
   Ubicación: scripts/seguridad/02_roles_y_permisos.sql
   Entrega: 8 (Seguridad y Respaldo)
   
   Descripción:
     Implementa el modelo de control de acceso basado en roles (RBAC) aplicando el
     principio de menor privilegio (Least Privilege) dentro de Mundial2026, todo
     encapsulado en el Stored Procedure administracion.sp_ConfigurarRolesYPermisos:
     
     1. Creación de 5 Roles de Seguridad en Mundial2026:
        - rol_administrador      : Dirección General / DBA FIFA (Acceso total y desencriptado).
        - rol_operador_partido   : Oficial de mesa y eventos en cancha (partido y designaciones).
        - rol_gestor_publicidad  : Gestión comercial, pautas y sponsors (publicidad).
        - rol_comite_arbitral    : Comité arbitral y disciplinario (árbitros, informes y suspensiones).
        - rol_medico             : Cuerpo Médico  (bajas médicas, reemplazos por lesión y fichas sensibles).
     2. Creación de 5 Logins a nivel servidor y sus 5 Usuarios
        de Base de Datos vinculados (CREATE USER ... FOR LOGIN).
     3. Bloqueo estricto (DENY SELECT, INSERT, UPDATE, DELETE) sobre las tablas físicas
        para los roles operativos, exigiendo que toda operación pase por Stored Procedures.
     4. Asignación granular de permisos (GRANT EXECUTE / DENY EXECUTE) y protección de
        los 3 procedimientos visores de datos sensibles.
*/

USE [Mundial2026];
GO

SET NOCOUNT ON;
GO

PRINT '======================================================================';
PRINT 'INICIANDO CONFIGURACIÓN DE ROLES, USUARIOS Y PERMISOS';
PRINT '======================================================================';
GO

CREATE OR ALTER PROCEDURE administracion.sp_ConfigurarRolesYPermisos
AS
BEGIN
    SET NOCOUNT ON;

    -- ------------------------------------------------------------------------
    -- 1. CREACIÓN DE ROLES
    -- ------------------------------------------------------------------------
    IF DATABASE_PRINCIPAL_ID(N'rol_administrador') IS NULL
        CREATE ROLE [rol_administrador] AUTHORIZATION [dbo];

    IF DATABASE_PRINCIPAL_ID(N'rol_operador_partido') IS NULL
        CREATE ROLE [rol_operador_partido] AUTHORIZATION [dbo];

    IF DATABASE_PRINCIPAL_ID(N'rol_gestor_publicidad') IS NULL
        CREATE ROLE [rol_gestor_publicidad] AUTHORIZATION [dbo];

    IF DATABASE_PRINCIPAL_ID(N'rol_comite_arbitral') IS NULL
        CREATE ROLE [rol_comite_arbitral] AUTHORIZATION [dbo];

    IF DATABASE_PRINCIPAL_ID(N'rol_medico') IS NULL
        CREATE ROLE [rol_medico] AUTHORIZATION [dbo];

    -- ------------------------------------------------------------------------
    -- 2. CREACIÓN DE LOGINS Y USUARIOS DE BASE DE DATOS
    -- ------------------------------------------------------------------------
    IF SUSER_ID(N'usr_administrador') IS NULL
        CREATE LOGIN [usr_administrador] WITH PASSWORD = N'Mundial2026!Admin';

    IF SUSER_ID(N'usr_operador_partido') IS NULL
        CREATE LOGIN [usr_operador_partido] WITH PASSWORD = N'Mundial2026!Operador';

    IF SUSER_ID(N'usr_gestor_publicidad') IS NULL
        CREATE LOGIN [usr_gestor_publicidad] WITH PASSWORD = N'Mundial2026!Publi';

    IF SUSER_ID(N'usr_comite_arbitral') IS NULL
        CREATE LOGIN [usr_comite_arbitral] WITH PASSWORD = N'Mundial2026!Comite';

    IF SUSER_ID(N'usr_medico') IS NULL
        CREATE LOGIN [usr_medico] WITH PASSWORD = N'Mundial2026!Medico';

    -- Si existían previamente como WITHOUT LOGIN o con otro SID, se recrean vinculados al LOGIN
    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'usr_administrador' AND sid <> SUSER_SID(N'usr_administrador'))
        DROP USER [usr_administrador];
    IF DATABASE_PRINCIPAL_ID(N'usr_administrador') IS NULL
        CREATE USER [usr_administrador] FOR LOGIN [usr_administrador];

    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'usr_operador_partido' AND sid <> SUSER_SID(N'usr_operador_partido'))
        DROP USER [usr_operador_partido];
    IF DATABASE_PRINCIPAL_ID(N'usr_operador_partido') IS NULL
        CREATE USER [usr_operador_partido] FOR LOGIN [usr_operador_partido];

    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'usr_gestor_publicidad' AND sid <> SUSER_SID(N'usr_gestor_publicidad'))
        DROP USER [usr_gestor_publicidad];
    IF DATABASE_PRINCIPAL_ID(N'usr_gestor_publicidad') IS NULL
        CREATE USER [usr_gestor_publicidad] FOR LOGIN [usr_gestor_publicidad];

    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'usr_comite_arbitral' AND sid <> SUSER_SID(N'usr_comite_arbitral'))
        DROP USER [usr_comite_arbitral];
    IF DATABASE_PRINCIPAL_ID(N'usr_comite_arbitral') IS NULL
        CREATE USER [usr_comite_arbitral] FOR LOGIN [usr_comite_arbitral];

    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'usr_medico' AND sid <> SUSER_SID(N'usr_medico'))
        DROP USER [usr_medico];
    IF DATABASE_PRINCIPAL_ID(N'usr_medico') IS NULL
        CREATE USER [usr_medico] FOR LOGIN [usr_medico];

    -- ------------------------------------------------------------------------
    -- 3. VINCULACIÓN DE USUARIOS A SUS RESPECTIVOS ROLES
    -- ------------------------------------------------------------------------
    IF IS_ROLEMEMBER(N'rol_administrador', N'usr_administrador') = 0
        ALTER ROLE [rol_administrador] ADD MEMBER [usr_administrador];

    IF IS_ROLEMEMBER(N'rol_operador_partido', N'usr_operador_partido') = 0
        ALTER ROLE [rol_operador_partido] ADD MEMBER [usr_operador_partido];

    IF IS_ROLEMEMBER(N'rol_gestor_publicidad', N'usr_gestor_publicidad') = 0
        ALTER ROLE [rol_gestor_publicidad] ADD MEMBER [usr_gestor_publicidad];

    IF IS_ROLEMEMBER(N'rol_comite_arbitral', N'usr_comite_arbitral') = 0
        ALTER ROLE [rol_comite_arbitral] ADD MEMBER [usr_comite_arbitral];

    IF IS_ROLEMEMBER(N'rol_medico', N'usr_medico') = 0
        ALTER ROLE [rol_medico] ADD MEMBER [usr_medico];

    -- ------------------------------------------------------------------------
    -- 4. BLOQUEO ESTRICTO DE ACCESO DIRECTO A TABLAS FÍSICAS 
    -- Ningún rol no administrador puede ejecutar SELECT, INSERT, UPDATE o DELETE
    -- directamente sobre las tablas. Toda operación se canaliza por SPs
    -- ------------------------------------------------------------------------
    DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[administracion] TO [rol_operador_partido], [rol_gestor_publicidad], [rol_comite_arbitral], [rol_medico];
    DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[partido]        TO [rol_operador_partido], [rol_gestor_publicidad], [rol_comite_arbitral], [rol_medico];
    DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[arbitraje]      TO [rol_operador_partido], [rol_gestor_publicidad], [rol_comite_arbitral], [rol_medico];
    DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[publicidad]     TO [rol_operador_partido], [rol_gestor_publicidad], [rol_comite_arbitral], [rol_medico];

    -- ------------------------------------------------------------------------
    -- 5. PERMISOS DEL ROL 1: rol_administrador
    -- ------------------------------------------------------------------------
    GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[administracion] TO [rol_administrador];
    GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[partido]        TO [rol_administrador];
    GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[arbitraje]      TO [rol_administrador];
    GRANT EXECUTE, SELECT, INSERT, UPDATE, DELETE ON SCHEMA::[publicidad]     TO [rol_administrador];

    -- ------------------------------------------------------------------------
    -- 6. PERMISOS DEL ROL 2: rol_operador_partido (Operación en Cancha)
    -- Puede ejecutar los SPs operativos de partido y designar árbitros
    -- (cifrando el informe al guardar), pero tiene denegados los 3 SPs visores
    -- de datos sensibles desencriptados y los esquemas administracion/publicidad.
    -- ------------------------------------------------------------------------
    GRANT EXECUTE ON SCHEMA::[partido] TO [rol_operador_partido];

    IF OBJECT_ID('arbitraje.sp_DesignarArbitro', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[arbitraje].[sp_DesignarArbitro] TO [rol_operador_partido];

    IF OBJECT_ID('arbitraje.sp_ModificarDesignacionArbitro', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[arbitraje].[sp_ModificarDesignacionArbitro] TO [rol_operador_partido];

    IF OBJECT_ID('arbitraje.sp_EliminarDesignacionArbitro', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[arbitraje].[sp_EliminarDesignacionArbitro] TO [rol_operador_partido];

    IF OBJECT_ID('arbitraje.sp_ReporteDesignacionesArbitrales', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[arbitraje].[sp_ReporteDesignacionesArbitrales] TO [rol_operador_partido];

    DENY EXECUTE ON SCHEMA::[administracion] TO [rol_operador_partido];
    DENY EXECUTE ON SCHEMA::[publicidad]     TO [rol_operador_partido];

    IF OBJECT_ID('arbitraje.sp_ConsultarInformesArbitrales', 'P') IS NOT NULL
        DENY EXECUTE ON OBJECT::[arbitraje].[sp_ConsultarInformesArbitrales] TO [rol_operador_partido];

    IF OBJECT_ID('administracion.sp_ConsultarJugadorSensible', 'P') IS NOT NULL
        DENY EXECUTE ON OBJECT::[administracion].[sp_ConsultarJugadorSensible] TO [rol_operador_partido];

    IF OBJECT_ID('administracion.sp_ConsultarBajasMedicasSensibles', 'P') IS NOT NULL
        DENY EXECUTE ON OBJECT::[administracion].[sp_ConsultarBajasMedicasSensibles] TO [rol_operador_partido];

    -- ------------------------------------------------------------------------
    -- 7. PERMISOS DEL ROL 3: rol_gestor_publicidad (Gestión Comercial)
    -- ------------------------------------------------------------------------
    GRANT EXECUTE ON SCHEMA::[publicidad] TO [rol_gestor_publicidad];

    DENY EXECUTE ON SCHEMA::[administracion] TO [rol_gestor_publicidad];
    DENY EXECUTE ON SCHEMA::[partido]        TO [rol_gestor_publicidad];
    DENY EXECUTE ON SCHEMA::[arbitraje]      TO [rol_gestor_publicidad];

    IF OBJECT_ID('arbitraje.sp_ConsultarInformesArbitrales', 'P') IS NOT NULL
        DENY EXECUTE ON OBJECT::[arbitraje].[sp_ConsultarInformesArbitrales] TO [rol_gestor_publicidad];

    IF OBJECT_ID('administracion.sp_ConsultarJugadorSensible', 'P') IS NOT NULL
        DENY EXECUTE ON OBJECT::[administracion].[sp_ConsultarJugadorSensible] TO [rol_gestor_publicidad];

    IF OBJECT_ID('administracion.sp_ConsultarBajasMedicasSensibles', 'P') IS NOT NULL
        DENY EXECUTE ON OBJECT::[administracion].[sp_ConsultarBajasMedicasSensibles] TO [rol_gestor_publicidad];

    -- ------------------------------------------------------------------------
    -- 8. PERMISOS DEL ROL 4: rol_comite_arbitral (Comité Arbitral y Disciplinario)
    -- Administra árbitros, idiomas, designaciones e informes arbitrales (incluido
    -- el SP visor de informes descifrados) y gestiona suspensiones en partido.
    -- Tiene denegados administracion, publicidad y datos sensibles de jugadores.
    -- ------------------------------------------------------------------------
    GRANT EXECUTE ON SCHEMA::[arbitraje] TO [rol_comite_arbitral];

    IF OBJECT_ID('partido.sp_ModificarSuspension', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[partido].[sp_ModificarSuspension] TO [rol_comite_arbitral];

    IF OBJECT_ID('partido.sp_EliminarSuspension', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[partido].[sp_EliminarSuspension] TO [rol_comite_arbitral];

    IF OBJECT_ID('partido.sp_RegistrarCumplimientoSuspension', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[partido].[sp_RegistrarCumplimientoSuspension] TO [rol_comite_arbitral];

    IF OBJECT_ID('partido.sp_ReporteTarjetasYSuspensiones', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[partido].[sp_ReporteTarjetasYSuspensiones] TO [rol_comite_arbitral];

    DENY EXECUTE ON SCHEMA::[administracion] TO [rol_comite_arbitral];
    DENY EXECUTE ON SCHEMA::[publicidad]     TO [rol_comite_arbitral];

    IF OBJECT_ID('administracion.sp_ConsultarJugadorSensible', 'P') IS NOT NULL
        DENY EXECUTE ON OBJECT::[administracion].[sp_ConsultarJugadorSensible] TO [rol_comite_arbitral];

    IF OBJECT_ID('administracion.sp_ConsultarBajasMedicasSensibles', 'P') IS NOT NULL
        DENY EXECUTE ON OBJECT::[administracion].[sp_ConsultarBajasMedicasSensibles] TO [rol_comite_arbitral];

    -- ------------------------------------------------------------------------
    -- 9. PERMISOS DEL ROL 5: rol_medico (Cuerpo Médico FIFA)
    -- Registra bajas médicas y reemplazos por lesión (cifrando el motivo) y
    -- consulta fichas de jugadores y bajas médicas descifradas.
    -- Tiene denegados partido, arbitraje, publicidad y el resto de administracion.
    -- ------------------------------------------------------------------------
    IF OBJECT_ID('administracion.sp_RegistrarBajaConvocatoria', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[administracion].[sp_RegistrarBajaConvocatoria] TO [rol_medico];

    IF OBJECT_ID('administracion.sp_ReemplazarConvocadoUltimoMomento', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[administracion].[sp_ReemplazarConvocadoUltimoMomento] TO [rol_medico];

    IF OBJECT_ID('administracion.sp_ConsultarBajasMedicasSensibles', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[administracion].[sp_ConsultarBajasMedicasSensibles] TO [rol_medico];

    IF OBJECT_ID('administracion.sp_ConsultarJugadorSensible', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[administracion].[sp_ConsultarJugadorSensible] TO [rol_medico];

    IF OBJECT_ID('administracion.sp_ReporteSeleccionesPlantillas', 'P') IS NOT NULL
        GRANT EXECUTE ON OBJECT::[administracion].[sp_ReporteSeleccionesPlantillas] TO [rol_medico];

    DENY EXECUTE ON SCHEMA::[partido]    TO [rol_medico];
    DENY EXECUTE ON SCHEMA::[arbitraje]  TO [rol_medico];
    DENY EXECUTE ON SCHEMA::[publicidad] TO [rol_medico];

    IF OBJECT_ID('arbitraje.sp_ConsultarInformesArbitrales', 'P') IS NOT NULL
        DENY EXECUTE ON OBJECT::[arbitraje].[sp_ConsultarInformesArbitrales] TO [rol_medico];

    -- ------------------------------------------------------------------------
    -- 10. PERMISOS CRIPTOGRÁFICOS SOBRE CERTIFICADO Y CLAVE SIMÉTRICA AES-256
    -- rol_administrador recibe CONTROL completo para cifrar y descifrar.
    -- rol_operador_partido, rol_comite_arbitral y rol_medico reciben solo lo
    -- necesario para cifrar/descifrar en sus SPs autorizados, denegando ALTER y
    -- TAKE OWNERSHIP sobre el certificado.
    -- rol_gestor_publicidad tiene denegado REFERENCES.
    -- ------------------------------------------------------------------------
    IF KEY_ID(N'Key_Mundial2026_AES256') IS NOT NULL AND CERT_ID(N'Cert_Mundial2026_Seguridad') IS NOT NULL
    BEGIN
        GRANT CONTROL    ON CERTIFICATE::[Cert_Mundial2026_Seguridad] TO [rol_administrador], [rol_operador_partido], [rol_comite_arbitral], [rol_medico];
        DENY  ALTER, TAKE OWNERSHIP ON CERTIFICATE::[Cert_Mundial2026_Seguridad] TO [rol_operador_partido], [rol_comite_arbitral], [rol_medico];
        GRANT REFERENCES ON SYMMETRIC KEY::[Key_Mundial2026_AES256]   TO [rol_administrador], [rol_operador_partido], [rol_comite_arbitral], [rol_medico];
        DENY  REFERENCES ON SYMMETRIC KEY::[Key_Mundial2026_AES256]   TO [rol_gestor_publicidad];
    END;
END;
GO

-- Ejecutar la configuración inmediatamente
EXEC administracion.sp_ConfigurarRolesYPermisos;
GO

-- ============================================================================
-- 9. VERIFICACIÓN EN CATÁLOGO DE ROLES, MIEMBROS Y PERMISOS OTORGADOS
-- ============================================================================

-- 9.1. Ver roles de la DB y usuarios asignados
SELECT
    roles.name                                 AS [Rol],
    roles.principal_id                         AS [ID_Rol],
    members.name                               AS [Usuario_Miembro],
    database_role_members.member_principal_id  AS [ID_Usuario]
FROM sys.database_role_members AS database_role_members
JOIN sys.database_principals AS roles
    ON database_role_members.role_principal_id = roles.principal_id
JOIN sys.database_principals AS members
    ON database_role_members.member_principal_id = members.principal_id
WHERE roles.name IN ('rol_administrador', 'rol_operador_partido', 'rol_gestor_publicidad', 'rol_comite_arbitral', 'rol_medico')
ORDER BY roles.name, members.name;
GO

-- 9.2. Ver permisos otorgados y denegados explícitamente a los roles del sistema
SELECT
    dp.name                AS [Rol],
    perms.state_desc       AS [Estado],
    perms.permission_name  AS [Permiso],
    perms.class_desc       AS [Alcance],
    COALESCE(
        obj.name,
        sch.name,
        cert.name,
        sk.name
    )                      AS [Sobre_Objeto_o_Esquema]
FROM sys.database_permissions AS perms
JOIN sys.database_principals AS dp
    ON perms.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects AS obj
    ON perms.class_desc = 'OBJECT_OR_COLUMN' AND perms.major_id = obj.object_id
LEFT JOIN sys.schemas AS sch
    ON perms.class_desc = 'SCHEMA' AND perms.major_id = sch.schema_id
LEFT JOIN sys.certificates AS cert
    ON perms.class_desc = 'CERTIFICATE' AND perms.major_id = cert.certificate_id
LEFT JOIN sys.symmetric_keys AS sk
    ON perms.class_desc = 'SYMMETRIC_KEYS' AND perms.major_id = sk.symmetric_key_id
WHERE dp.name IN ('rol_administrador', 'rol_operador_partido', 'rol_gestor_publicidad', 'rol_comite_arbitral', 'rol_medico')
ORDER BY dp.name, perms.state_desc, perms.class_desc, [Sobre_Objeto_o_Esquema];
GO

PRINT '======================================================================';
PRINT '¡CONFIGURACIÓN DE ROLES Y PERMISOS COMPLETADA CON ÉXITO EN Mundial2026!';
PRINT 'Roles activos: rol_administrador, rol_operador_partido, rol_gestor_publicidad, rol_comite_arbitral, rol_medico.';
PRINT '======================================================================';
GO
