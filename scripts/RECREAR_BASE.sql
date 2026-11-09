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
     
   Script: RECREAR_BASE.sql
   Descripción: Script maestro para recrear por completo la base de datos Mundial2026
                desde cero en un solo clic:
                - Base de datos y Esquemas funcionales.
                - 25 Tablas relacionales con restricciones e índices.
                - Stored Procedures de Negocio (Módulos 1 a 4).
                - Infraestructura DDL de Importación.
                - Stored Procedures de Importación Masiva.
                
   MODO DE USO EN SSMS:
   1. Configuración: Asegurarse de que la variable RepoDir apunte a la carpeta raíz del repositorio clonado.
   2. Activar 'Modo SQLCMD': En el menú superior de SSMS ir a:
      Consulta (Query) -> Modo SQLCMD (SQLCMD Mode).
   3. Presionar F5 (Ejecutar).
*/

-- 0. RUTA RAÍZ DEL REPOSITORIO (ÚNICA VARIABLE QUE CADA INTEGRANTE DEBE CONFIGURAR)
:setvar RepoDir "G:\UNLaM\Cursando\bases de datos aplicadas\TP_GRUPAL\Gestion-del-mundial-tp"

PRINT '======================================================================';
PRINT 'INICIANDO RECREACIÓN TOTAL DE LA ESTRUCTURA Y SPs - MUNDIAL 2026';
PRINT '======================================================================';

-- 1. BORRADO PREVIO DE LA BASE DE DATOS
PRINT '>> [0/12] Eliminando Base de Datos [Mundial2026] si existe...';
:r $(RepoDir)\scripts\00_borrado_base_de_datos.sql

-- 2. BASE DE DATOS
PRINT '>> [1/12] Creando Base de Datos [Mundial2026]...';
:r $(RepoDir)\scripts\01_creacion_base_de_datos.sql

-- 3. ESQUEMAS
PRINT '>> [2/12] Creando Esquemas funcionales...';
:r $(RepoDir)\scripts\02_creacion_esquemas.sql

-- 4. TABLAS Y RESTRICCIONES (25 tablas en 3FN)
PRINT '>> [3/12] Creando Tablas y Restricciones de Integridad...';
:r $(RepoDir)\scripts\03_creacion_tablas.sql

-- 5. PROCEDIMIENTOS ALMACENADOS - MÓDULO 1: ADMINISTRACIÓN
PRINT '>> [4/12] Compilando Stored Procedures del Módulo 1 (Administración)...';
:r $(RepoDir)\scripts\04_sp_administracion.sql

-- 6. PROCEDIMIENTOS ALMACENADOS - MÓDULO 2: PARTIDOS Y CAMBIOS
PRINT '>> [5/12] Compilando Stored Procedures del Módulo 2 (Partidos y Cambios)...';
:r $(RepoDir)\scripts\05_sp_partidos_y_cambios.sql

-- 7. PROCEDIMIENTOS ALMACENADOS - MÓDULO 3: GOLES, TARJETAS Y ÁRBITROS
PRINT '>> [6/12] Compilando Stored Procedures del Módulo 3 (Goles, Tarjetas y Árbitros)...';
:r $(RepoDir)\scripts\06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql

-- 8. PROCEDIMIENTOS ALMACENADOS - MÓDULO 4: PUBLICIDAD
PRINT '>> [7/12] Compilando Stored Procedures del Módulo 4 (Publicidad)...';
:r $(RepoDir)\scripts\07_sp_publicidad.sql

-- 9. INFRAESTRUCTURA DE IMPORTACIÓN (LOG CENTRALIZADO)
PRINT '>> [8/12] Creando Tablas de Auditoría de Importación (Log)...';
:r $(RepoDir)\scripts\08_tablas_importacion.sql

-- 10. PROCEDIMIENTOS ALMACENADOS - IMPORTACIÓN DE PAÍSES (JSON)
PRINT '>> [9/12] Compilando Stored Procedures de Importación Masiva (Países JSON)...';
:r $(RepoDir)\scripts\09_sp_importacion_paises.sql

-- 11. PROCEDIMIENTOS ALMACENADOS - CONSUMO E INTEGRACIÓN CON APIs 
PRINT '>> [10/12] Compilando Stored Procedures de APIs REST (Banco Mundial y Geolocalización)...';
:r $(RepoDir)\scripts\09_b_sp_importacion_APIs.sql

-- 12. PROCEDIMIENTOS ALMACENADOS - IMPORTACIÓN DE JUGADORES Y CLUBES (CSV)
PRINT '>> [11/12] Compilando Stored Procedures de Importación Masiva (Jugadores y Clubes CSV)...';
:r $(RepoDir)\scripts\11_sp_importar_jugadores_clubes.sql

-- 13. PROCEDIMIENTOS ALMACENADOS - IMPORTACIÓN DE ÁRBITROS (CSV SCRAPING)
PRINT '>> [12/12] Compilando Stored Procedures de Importación Masiva (Árbitros CSV)...';
:r $(RepoDir)\scripts\12_sp_importar_arbitros.sql

-- 14. FUNCIÓN AUXILIAR DE CONFIGURACIÓN GLOBAL: RUTA DE DATASETS
-- Memoriza en la base de datos la ubicación de la carpeta 'datasets' en esta máquina
-- para que ningún otro script o integrante deba configurar rutas manualmente.
PRINT '>> Registrando función auxiliar global administracion.fn_RutaDatasets()...';
GO
CREATE OR ALTER FUNCTION administracion.fn_RutaRepositorio()
RETURNS VARCHAR(500)
AS
BEGIN
    RETURN '$(RepoDir)';
END;
GO

CREATE OR ALTER FUNCTION administracion.fn_RutaDatasets()
RETURNS VARCHAR(500)
AS
BEGIN
    RETURN '$(RepoDir)\datasets';
END;
GO

PRINT '======================================================================';
PRINT '¡RECREACIÓN DE BASE DE DATOS EXITOSA!';
PRINT 'Base de datos limpia, esquemas, tablas y SPs compilados.';
PRINT '======================================================================';
GO
