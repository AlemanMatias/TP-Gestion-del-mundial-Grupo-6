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
     
   Script: JUEGO_DE_DATOS.sql
   Descripción: Script para poblar por completo la base de datos Mundial2026
                - Delegaciones, planteles, cuerpos técnicos y sedes (01_administracion_y_planteles.sql)
                - Catálogo comercial y contratos publicitarios (02_catalogo_publicidad.sql)
                - Fase de Grupos - Partidos 1 al 16 (03_partidos_fase_grupos.sql)
                - Fases Finales y Gran Final - Partidos 17 al 26 (04_partidos_fase_final.sql)
                
   REQUISITO PREVIO:
   La base de datos y sus Stored Procedures deben haber sido creados previamente
   (ejecutando RECREAR_BASE.sql).
                
   MODO DE USO EN SSMS:
   1. Configuración: Asegurarse de que la variable RepoDir apunte a la carpeta raíz del repositorio clonado.
   2. Activar 'Modo SQLCMD': En el menú superior de SSMS ir a:
      Consulta (Query) -> Modo SQLCMD (SQLCMD Mode).
   3. Presionar F5 (Ejecutar).
*/

USE Mundial2026;
GO

SET NOCOUNT ON;
GO

-- 0. RUTA RAÍZ DEL REPOSITORIO (ÚNICA VARIABLE A CONFIGURAR EN ESTE ARCHIVO)
:setvar RepoDir "G:\UNLaM\Cursando\bases de datos aplicadas\TP_GRUPAL\Gestion-del-mundial-tp"

PRINT '======================================================================';
PRINT 'INICIANDO CARGA TOTAL DE JUEGO DE DATOS (SEED DATA) - MUNDIAL 2026';
PRINT '======================================================================';

-- 1. ADMINISTRACIÓN, PLANTELES Y SEDES
PRINT '>> [Paso 1/4] Cargando Delegaciones, Cuerpos Técnicos, Sedes y Convocatorias...';
:r $(RepoDir)\scripts\semilla\01_administracion_y_planteles.sql

-- 2. CATÁLOGO COMERCIAL Y PUBLICIDAD
PRINT '>> [Paso 2/4] Cargando Catálogo Publicitario, Tarifas, Contratos y Piezas...';
:r $(RepoDir)\scripts\semilla\02_catalogo_publicidad.sql

-- 3. FASE DE GRUPOS (PARTIDOS 1 AL 16)
PRINT '>> [Paso 3/4] Disputando Partidos de Fase de Grupos (Partidos 1 al 16)...';
:r $(RepoDir)\scripts\semilla\03_partidos_fase_grupos.sql

-- 4. FASES ELIMINATORIAS Y FINAL (PARTIDOS 17 AL 26)
PRINT '>> [Paso 4/4] Disputando Fases Eliminatorias, Tanda de Penales y Gran Final (Partidos 17 al 26)...';
:r $(RepoDir)\scripts\semilla\04_partidos_fase_final.sql

PRINT '======================================================================';
PRINT '¡CARGA DE JUEGO DE DATOS FINALIZADA CON ÉXITO!';
PRINT 'El Mundial 2026 se encuentra completamente poblado y disputado.';
PRINT '======================================================================';
GO
