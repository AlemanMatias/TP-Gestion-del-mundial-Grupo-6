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
│   ├── SquadLists_errores.csv              # Dataset de prueba con errores controlados
│   ├── arbitros.csv                        # Catálogo de árbitros 
│   └── countries.json                      # Catálogo de países
├── docs/
│   ├── der/                          
│   │   ├── README.md                       # Especificación del modelo relacional
│   │   ├── der_v1.2.jpg                    # Diagrama Entidad-Relación actualizado (v1.2)
│   │   └── der_v1.2_dbdiagram.txt          # Código fuente DBML para dbdiagram.io
│   ├── Com5600_Grupo06_Politica_Respaldo.pdf # Política de respaldo (RPO, RTO, FULL, 3-2-1)
│   ├── Informe Cifrado de Datos Sensibles.pdf # Documentación de cifrado AES-256
│   ├── Informe integracion APIs Externas.pdf # Documentación de consumo de APIs
│   ├── Informe Web Scraping.pdf            # Documentación técnica de extracción en Python
│   └── Instalación_y_Configuración.pdf     # Parámetros del motor e infraestructura
├── python/
│   └── importacionarbitros.py              # Script de Web Scraping
├── scripts/
│   ├── 00..03: Creación de base de datos, esquemas y tablas relacionales (DDL)
│   ├── 04..07: Stored Procedures de negocio y lógica operativa (ABMs)
│   ├── 08..12: Stored Procedures de importación masiva (JSON, CSV, APIs REST)
│   ├── reportes/                           # Stored Procedures para reportes analíticos
│   ├── seguridad/                          # Cifrado AES-256, roles, logins, permisos y README.md
│   ├── semilla/                            # Scripts de carga y simulación del torneo
│   ├── RECREAR_BASE.sql                    # Script para recrear la base y compilar todos los SPs
│   ├── JUEGO_DE_DATOS.sql                  # Script para poblar la base y disputar los partidos
│   └── REPORTES.sql                        # Script para ejecución individual de reportes analíticos
├── tests/
│   ├── seguridad/                          # Tests de cifrado y validación por cada rol (EXECUTE AS LOGIN)
│   └── Scripts de testing para cada módulo
├── .gitignore
└── README.md
```

---

## 🚀 Guía de Instalación y Población de Datos

### Paso 1: Recreación de la Base de Datos (`RECREAR_BASE.sql`)
1. Abrir el archivo **`scripts/RECREAR_BASE.sql`** en SSMS.
2. Actualizar en la línea `:setvar RepoDir "..."` la ruta absoluta a la raíz del repositorio en su equipo.
3. En el menú superior de SSMS, activar **Consulta (Query) $\rightarrow$ Modo SQLCMD (SQLCMD Mode)**.
4. Presionar **F5 (Ejecutar)**. El script ejecutará automáticamente en orden:
   * El borrado previo de cualquier versión anterior (`00`).
   * La creación de la base de datos `Mundial2026` (`01`).
   * Los 4 esquemas funcionales (`02`).
   * Las 25 tablas relacionales con restricciones e índices (`03`).
   * Los Stored Procedures de negocio (`04`, `05`, `06`, `07`).
   * La infraestructura y procedimientos de importación masiva (`08`, `09`, `09_b`, `11`, `12`).
   * Los procedimientos de reportes analíticos (`reportes/`).

### Paso 2: Semilla   (`JUEGO_DE_DATOS.sql`)
1. Abrir el archivo **`scripts/JUEGO_DE_DATOS.sql`** en SSMS.
2. Actualizar en la línea `:setvar RepoDir "..."` la ruta absoluta a la raíz del repositorio en su equipo.
3. En el menú superior de SSMS, activar **Consulta (Query) $\rightarrow$ Modo SQLCMD (SQLCMD Mode)**.
4. Presionar **F5 (Ejecutar)**. El script ejecutará automáticamente en orden:
   * Delegaciones oficiales, cuerpos técnicos, sedes y convocatorias (`01_administracion_y_planteles.sql`).
   * Catálogo comercial, tarifas, contratos y anunciantes (`02_catalogo_publicidad.sql`).
   * Disputa de la Fase de Grupos - Partidos 1 al 16 (`03_partidos_fase_grupos.sql`).
   * Fases Eliminatorias, definiciones por penales y Gran Final - Partidos 17 al 26 (`04_partidos_fase_final.sql`).


### Paso 3: Seguridad, Cifrado y Respaldo (`scripts/seguridad/`)
Luego de crear y poblar la base, ejecutar manualmente en orden en SSMS (con una sesión `sysadmin` / Autenticación de Windows):
1. **`scripts/seguridad/01_cifrado_datos_sensibles.sql`**: crea la *Database Master Key*, el certificado `Cert_Mundial2026_Seguridad` y la clave simétrica `Key_Mundial2026_AES256` (`AES_256`). Cifra en columnas `VARBINARY` las fechas de nacimiento (`Jugador.fecha_nacimiento_cifrada`), motivos de baja médica (`Convocatoria.motivo_cifrado`) e informes arbitrales (`Designacion_Arbitral.informe_cifrado`), dejando los campos planos en `NULL`, reescribe los SPs de escritura y agrega 3 SPs visores para lectura descifrada.
2. **`scripts/seguridad/02_roles_y_permisos.sql`**: ejecuta `administracion.sp_ConfigurarRolesYPermisos` para crear 5 roles (`rol_administrador`, `rol_operador_partido`, `rol_gestor_publicidad`, `rol_comite_arbitral` y `rol_medico`), sus 5 logins y usuarios vinculados. El detalle completo de permisos y denegaciones está en [`scripts/seguridad/README.md`](scripts/seguridad/README.md).
---
## 📥 Importación de datos

El sistema integra fuentes de datos heterogéneas para alimentar el catálogo inicial, asegurar la trazabilidad y enriquecer los datos del torneo:

* **Auditoría Centralizada (`08_tablas_importacion.sql`):** Implementa la tabla `dbo.LogImportacion` como repositorio único para registrar eventos, trazabilidad de filas y fallos controlados en todos los procesos de carga.
* **Catálogo Global de Países (`09_sp_importacion_paises.sql`):** importacion de paises mediante el archivo `countries.json`.
* **Integración con APIs (`09_b_sp_importacion_APIs.sql`):** 
  * *Banco Mundial:* Importacion de PBI per cápita.
  * *Open-Meteo Geocoding:* Obtención de coordenadas (latitud y longitud) para cada sede según su ciudad.
* **Nóminas Oficiales y Clubes (`11_sp_importar_jugadores_clubes.sql`):** Importacion masiva de 1.248 futbolistas y 450 clubes desde `SquadLists.csv`.
* **Scraping Arbitros (`12_sp_importar_arbitros.sql`):** Extracción del historial de árbitros desde Wikipedia con Python (`importacionarbitros.py`), exportación a `arbitros.csv`.

---

## 🧪 Testing

Cada uno de los 4 archivos de Stored Procedures cuenta con su correspondiente script de pruebas, y el módulo de seguridad incorpora en `tests/seguridad/` el test de cifrado (`test_01_cifrado_datos_sensibles.sql`) y un script de prueba por cada rol (`test_rol_administrador.sql`, `test_rol_operador_partido.sql`, `test_rol_gestor_publicidad.sql`, `test_rol_comite_arbitral.sql`, `test_rol_medico.sql`).


> * Cada script de prueba construye su propio contexto de datos invocando exclusivamente los Stored Procedures del sistema.
> * Todas las pruebas se ejecutan dentro de bloques transaccionales que revierten sus cambios al finalizar, dejando la base de datos completamente limpia y permitiendo re-ejecutar cualquier test en cualquier momento.
> 

---

## 👥 Integrantes del Grupo

* **Aleman Flores, Matias Osvaldo** — GitHub: [@AlemanMatias](https://github.com/AlemanMatias)
* **Gamarra Bravo, Sidney Maribel** — GitHub: [@Sidney-Gamarra](https://github.com/Sidney-Gamarra)
* **Pereira, Carlos Manuel** — GitHub: [@Manueelpereira02](https://github.com/Manueelpereira02)
* **Villa, Brenda** — GitHub: [@BrendaDelVilla](https://github.com/BrendaDelVilla)
