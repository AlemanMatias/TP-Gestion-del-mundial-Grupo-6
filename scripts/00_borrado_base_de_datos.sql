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
     
   Script: 00_borrado_base_de_datos.sql
   Descripción: Eliminación total de la base de datos Mundial2026.
*/

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Mundial2026')
BEGIN
    ALTER DATABASE Mundial2026 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Mundial2026;
    PRINT 'OK: Base de datos [Mundial2026] eliminada exitosamente.';
END
ELSE
BEGIN
    PRINT 'INFO: La base de datos [Mundial2026] no existe.';
END
GO
