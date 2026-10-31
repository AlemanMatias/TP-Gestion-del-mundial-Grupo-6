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
     
   Script: 08_tablas_importacion.sql
   Descripción: Infraestructura DDL de soporte para los procesos de importación masiva (Entrega 6).
                Crea la tabla centralizada dbo.LogImportacion para auditoría histórica,
                trazabilidad de ejecuciones y reporte de fallos parciales de todos los módulos.
*/

USE Mundial2026;
GO

PRINT '======================================================================';
PRINT 'CREANDO INFRAESTRUCTURA DE IMPORTACIÓN MASIVA (ENTREGA 6)';
PRINT '======================================================================';

IF OBJECT_ID('dbo.LogImportacion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.LogImportacion (
        id_log         INT IDENTITY(1,1) NOT NULL,
        archivo        VARCHAR(500)      NOT NULL,
        fecha_proceso  DATETIME          NOT NULL DEFAULT GETDATE(),
        fila_origen    VARCHAR(200)      NULL,
        tipo_evento    VARCHAR(20)       NOT NULL, -- 'INFO', 'ADVERTENCIA', 'ERROR'
        mensaje        VARCHAR(1000)     NOT NULL,

        CONSTRAINT PK_LogImportacion PRIMARY KEY (id_log)
    );

    PRINT 'OK: Tabla centralizada [dbo.LogImportacion] creada exitosamente.';
END
ELSE
BEGIN
    PRINT 'INFO: La tabla [dbo.LogImportacion] ya existe.';
END
GO
