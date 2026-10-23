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
   Descripción: Script para recrear por completo la base de datos Mundial2026
                desde cero en el orden estricto de dependencias:
                Base de datos, Esquemas, Tablas y Stored Procedures (Módulos 1 a 4).
                
   MODO DE USO EN SSMS:
   1. Configuración: Indicar en el paso 0 la ruta local de la carpeta 'scripts'
   2. Activar 'Modo SQLCMD': En el menú superior de SSMS ir a:
      Consulta (Query) -> Modo SQLCMD (SQLCMD Mode).
   3. Presionar F5 (Ejecutar).
*/

-- 0. Poner entre comillas la ruta donde se aloja la carpeta de scripts del proyecto :setvar ScriptsDir "ruta scripts"
:setvar ScriptsDir "g:\UNLaM\Cursando\bases de datos aplicadas\TP_GRUPAL\Gestion-del-mundial-tp\scripts"

PRINT '======================================================================';
PRINT 'INICIANDO RECREACIÓN TOTAL DE LA ESTRUCTURA Y SPs - MUNDIAL 2026';
PRINT '======================================================================';

-- 1. BASE DE DATOS
PRINT '>> [1/7] Creando Base de Datos [Mundial2026]...';
:r $(ScriptsDir)\01_creacion_base_de_datos.sql

-- 2. ESQUEMAS
PRINT '>> [2/7] Creando Esquemas funcionales...';
:r $(ScriptsDir)\02_creacion_esquemas.sql

-- 3. TABLAS Y RESTRICCIONES (25 tablas en 3FN)
PRINT '>> [3/7] Creando Tablas y Restricciones de Integridad...';
:r $(ScriptsDir)\03_creacion_tablas.sql

-- 4. PROCEDIMIENTOS ALMACENADOS - MÓDULO 1: ADMINISTRACIÓN
PRINT '>> [4/7] Compilando Stored Procedures del Módulo 1 (Administración)...';
:r $(ScriptsDir)\04_sp_administracion.sql

-- 5. PROCEDIMIENTOS ALMACENADOS - MÓDULO 2: PARTIDOS Y CAMBIOS
PRINT '>> [5/7] Compilando Stored Procedures del Módulo 2 (Partidos y Cambios)...';
:r $(ScriptsDir)\05_sp_partidos_y_cambios.sql

-- 6. PROCEDIMIENTOS ALMACENADOS - MÓDULO 3: GOLES, TARJETAS Y ÁRBITROS
PRINT '>> [6/7] Compilando Stored Procedures del Módulo 3 (Goles, Tarjetas y Árbitros)...';
:r $(ScriptsDir)\06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql

-- 7. PROCEDIMIENTOS ALMACENADOS - MÓDULO 4: PUBLICIDAD
PRINT '>> [7/7] Compilando Stored Procedures del Módulo 4 (Publicidad)...';
:r $(ScriptsDir)\07_sp_publicidad.sql

PRINT '======================================================================';
PRINT '¡RECREACION DE BASE DE DATOS EXITOSA ';
PRINT 'Base de datos limpia y lista.';
PRINT '======================================================================';
GO
