# Sistema de Gestión del Mundial de Fútbol ⚽

> Trabajo práctico correspondiente a la materia **Bases de Datos Aplicadas (3641)**  
> **Comisión:** 02-5600 (Viernes Tarde) — **Ingeniería en Informática**  
> Universidad Nacional de La Matanza (UNLaM)

---

## 📋 Descripción General

Este proyecto implementa un sistema integral de base de datos relacional para la gestión operativa, disciplinaria, arbitral y comercial de la Copa Mundial de la FIFA 2026 en Microsoft SQL Server.

* **Módulo 1 — Administración (`04_sp_administracion.sql`):** Gestión completa de países, fases del torneo, clubes, sedes con huso horario, selecciones participantes, cuerpos técnicos y planteles oficiales.
* **Módulo 2 — Partidos y Cambios (`05_sp_partidos_y_cambios.sql`):** Programación de partidos con cálculo automático de fecha/hora UTC a partir del huso horario de la sede, generación automática de los 4 espacios publicitarios del estadio, registro de resultados, formaciones tácticas, alineaciones y sustituciones reglamentarias.
* **Módulo 3 — Goles, Tarjetas, Árbitros y Suspensiones (`06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`):** Designación arbitral, registro de tarjetas amarillas y rojas, y control automático de suspensiones por acumulación de tarjetas en partidos distintos.
* **Módulo 4 — Publicidad y Exhibición Comercial (`07_sp_publicidad.sql`):** Gestión de espacios publicitarios, anunciantes, campañas, piezas de contenido.

---


## 🛠️ Tecnologías y Entorno
* **Motor:** Microsoft SQL Server 2022 o superior (`.\SQLEXPRESS` / instancia local)
* **Herramienta de Gestión:** SQL Server Management Studio (SSMS)
* **Collation:** `Modern_Spanish_CI_AS`

---

## 📁 Estructura del Proyecto

```text
├── datasets/
│   ├── SquadLists.csv                      # Plantillas oficiales (1.248 jugadores de 48 selecciones)
│   ├── SquadLists_errores.csv              # Dataset de prueba con errores controlados (9 filas)
│   ├── arbitros.csv                        # Nómina scrapeada de árbitros principales y asistentes
│   ├── companies.csv                       # Empresas y anunciantes comerciales
│   └── countries.json                      # Catálogo global de países, husos horarios y capitales
├── docs/
│   ├── der/                          
│   │   ├── README.md                       # Especificación del modelo relacional
│   │   ├── der_v1.2.jpg                    # Diagrama Entidad-Relación actualizado (v1.2)
│   │   └── der_v1.2_dbdiagram.txt          # Código fuente DBML para dbdiagram.io
│   ├── Informe integracion APIs Externas.pdf # Documentación de consumo de APIs REST
│   ├── Informe Web Scraping.pdf            # Documentación técnica de extracción en Python
│   └── Instalación_y_Configuración.pdf     # Parámetros del motor e infraestructura
├── python/
│   └── importacionarbitros.py              # Script de Web Scraping
├── scripts/
│   ├── 00_borrado_base_de_datos.sql
│   ├── 01_creacion_base_de_datos.sql
│   ├── 02_creacion_esquemas.sql
│   ├── 03_creacion_tablas.sql
│   ├── 04_sp_administracion.sql
│   ├── 05_sp_partidos_y_cambios.sql
│   ├── 06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql
│   ├── 07_sp_publicidad.sql
│   ├── 08_tablas_importacion.sql           # Infraestructura DDL: tabla dbo.LogImportacion
│   ├── 09_sp_importacion_paises.sql        # Importación JSON
│   ├── 09_b_sp_importacion_APIs.sql        # Consumo de APIs(Banco Mundial y Geolocalización)
│   ├── 11_sp_importar_jugadores_clubes.sql # Importación CSV
│   ├── 12_sp_importar_arbitros.sql         # Importación CSV
│   └── RECREAR_BASE.sql                    # Script para recrear la base de datos
├── tests/
│   ├── test_04_administracion.sql
│   ├── test_05_partidos_y_cambios.sql
│   ├── test_06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql
│   ├── test_07_publicidad.sql
│   ├── test_09_importacion_paises.sql
│   ├── test_09_b_importacion_APIs.sql
│   ├── test_11_importacion_jugadores_clubes.sql
│   └── test_12_importacion_arbitros.sql
├── .gitignore
└── README.md
```

---

## 🚀 Guía de Instalación y Recreación desde Cero

Se establecen **dos formas** de crear y compilar toda la base de datos desde cero:

### Opción A (RECOMENDADO): Recreación Automática en 1 Clic `RECREAR_BASE.sql`
1. Abrir el archivo **`scripts/RECREAR_BASE.sql`** en SSMS.
2. Actualizar en la línea `:setvar ScriptsDir "..."` la ruta de la carpeta `scripts` en su equipo.
3. En el menú superior de SSMS, activar **Consulta (Query) $\rightarrow$ Modo SQLCMD (SQLCMD Mode)**.
4. Presionar **F5 (Ejecutar)**. El script ejecutará automáticamente en orden:
   * El borrado previo de cualquier versión anterior (`00`).
   * La creación de la base de datos `Mundial2026` (`01`).
   * Los 4 esquemas funcionales (`02`).
   * Las 25 tablas  (`03`).
   * Los 4 módulos de Stored Procedures (`04`, `05`, `06`, `07`).
   * Los scripts de importacion de datos externos

### Opción B: Ejecución Manual Paso a Paso
Ejecutar los scripts ubicados en `scripts/` respetando el siguiente **orden secuencial de dependencias**:

1. **`01_creacion_base_de_datos.sql`**: Crea desde cero la base de datos `Mundial2026`.
2. **`02_creacion_esquemas.sql`**: Crea los 4 esquemas funcionales (`administracion`, `partido`, `arbitraje`, `publicidad`).
3. **`03_creacion_tablas.sql`**: Crea las 25 tablas relacionales con sus restricciones e índices.
4. **`04_sp_administracion.sql`**: Compila los Stored Procedures del Módulo 1 (Administración y Convocatorias).
5. **`05_sp_partidos_y_cambios.sql`**: Compila los Stored Procedures del Módulo 2 (Partidos, Formaciones, Alineaciones y Sustituciones).
6. **`06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`**: Compila los Stored Procedures del Módulo 3 (Árbitros, Designaciones, Goles, Tarjetas y Suspensiones).
7. **`07_sp_publicidad.sql`**: Compila los Stored Procedures del Módulo 4 (Anunciantes, Campañas, Piezas, Mercados Objetivo y asignación de publicidad).
8. **`08_tablas_importacion.sql`**: Crea la tabla centralizada de auditoría y trazabilidad `dbo.LogImportacion`.
9. **`09_sp_importacion_paises.sql`**: Compila los Stored Procedures para ingesta masiva de países desde JSON (`OPENJSON`).
10. **`09_b_sp_importacion_APIs.sql`**: Habilita OLE Automation y compila los procedimientos para consumo de APIs REST en vivo (Banco Mundial y Open-Meteo).
11. **`11_sp_importar_jugadores_clubes.sql`**: Compila el Stored Procedure de ingesta masiva de jugadores y clubes desde CSV (`BULK INSERT`).
12. **`12_sp_importar_arbitros.sql`**: Compila el Stored Procedure de ingesta masiva de árbitros y asistentes desde CSV.


---
## 📥 Importación de datos

El sistema integra fuentes de datos heterogéneas para alimentar el catálogo inicial, asegurar la trazabilidad y enriquecer los datos del torneo:

* **Auditoría Centralizada (`08_tablas_importacion.sql`):** Implementa la tabla `dbo.LogImportacion` como repositorio único para registrar eventos, trazabilidad de filas y fallos controlados en todos los procesos de carga.
* **Catálogo Global de Países (`09_sp_importacion_paises.sql`):** importacion de paises mediante el archivo `countries.json`.
* **Integración con APIs (`09_b_sp_importacion_APIs.sql`):** 
  * *Banco Mundial:* Importacion de PBI per cápita.
  * *Open-Meteo Geocoding:* Obtención de coordenadas (latitud y longitud) para cada sede según su ciudad.
* **Nóminas Oficiales y Clubes (`11_sp_importar_jugadores_clubes.sql`):** Ingesta masiva de 1.248 futbolistas y normalización de 450 clubes desde `SquadLists.csv`.
* **Web Scraping Arbitral (`12_sp_importar_arbitros.sql`):** Extracción del historial de árbitros desde Wikipedia con Python (`importacionarbitros.py`), exportación a `arbitros.csv`.

---

## 🧪 Testing

Cada uno de los 4 archivos de Stored Procedures cuenta con su correspondiente script de pruebas.


> * Cada script de prueba construye su propio contexto de datos invocando exclusivamente los Stored Procedures del sistema.
> * Todas las pruebas se ejecutan dentro de bloques transaccionales que revierten sus cambios al finalizar, dejando la base de datos completamente limpia y permitiendo re-ejecutar cualquier test en cualquier momento.
> 




---

## ⚙️ Configuración de Rutas Locales

Se debe ajustar las rutas locales en los siguientes scripts antes de ejecutarlos:

| Archivo a Modificar | Línea(s) | Parámetro / Clave | Archivo o Carpeta a Indicar |
| :--- | :---: | :--- | :--- |
| **`scripts/RECREAR_BASE.sql`** | **32** | `:setvar ScriptsDir` | Ruta absoluta a la carpeta local **`scripts\`** |
| **`tests/test_09_importacion_paises.sql`** | **37** | `@ruta_dataset` | Ruta al archivo **`datasets\countries.json`** |
| **`tests/test_11_importacion_jugadores_clubes.sql`** | **32** | `'csv_ok'` | Ruta al archivo **`datasets\SquadLists.csv`** |
| **`tests/test_11_importacion_jugadores_clubes.sql`** | **33** | `'csv_errores'` | Ruta al archivo **`datasets\SquadLists_errores.csv`** |
| **`tests/test_12_importacion_arbitros.sql`** | **25** | `@ruta_dataset` | Ruta al archivo **`datasets\countries.json`** *(catálogo base de países)* |
| **`tests/test_12_importacion_arbitros.sql`** | **49** | `@RutaCSVPrueba` | Ruta al archivo **`datasets\arbitros.csv`** *(nómina de árbitros)* |

> 💡 **Nota:** El script de pruebas de integración con APIs (`tests/test_09_b_importacion_APIs.sql`) consulta directamente los servicios web en vivo mediante HTTP/HTTPS, por lo que **no requiere configurar rutas de archivos locales**.

---

## 👥 Integrantes del Grupo

* **Aleman Flores, Matias Osvaldo**
* **Gamarra Bravo, Sidney Maribel**
* **Pereira, Carlos Manuel**
* **Villa, Brenda**
