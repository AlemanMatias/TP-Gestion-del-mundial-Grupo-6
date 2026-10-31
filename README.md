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
* **Módulo 4 — Publicidad y Exhibición Comercial (`07_sp_publicidad.sql`):** Gestión de espacios publicitarios, anunciantes, campañas, piezas de contenido por idioma/tarifa, mercados de interés comercial y motor inteligente de asignación publicitaria por partido.

---


## 🛠️ Tecnologías y Entorno
* **Motor:** Microsoft SQL Server 2022 o superior (`.\SQLEXPRESS` / instancia local)
* **Herramienta de Gestión:** SQL Server Management Studio (SSMS)
* **Collation:** `Modern_Spanish_CI_AS`

---

## 📁 Estructura del Proyecto



```text
├── docs/
│   ├── der/                          
│   │   ├── der_v1.1.jpg              
│   │   └── der_v1.1_dbdiagram.txt    
│   └── Instalación-y-Configuración.pdf
├── scripts/
│   ├── 00_borrado_base_de_datos.sql
│   ├── 01_creacion_base_de_datos.sql
│   ├── 02_creacion_esquemas.sql
│   ├── 03_creacion_tablas.sql
│   ├── 04_sp_administracion.sql
│   ├── 05_sp_partidos_y_cambios.sql
│   ├── 06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql
│   ├── 07_sp_publicidad.sql
│   └── RECREAR_BASE.sql
├── tests/
│   ├── test_04_administracion.sql
│   ├── test_05_partidos_y_cambios.sql
│   ├── test_06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql
│   └── test_07_publicidad.sql
├── .gitignore
└── README.md
```

---

## 🚀 Guía de Instalación y Recreación desde Cero

Se establecen **dos formas** de crear y compilar toda la base de datos desde cero:

### Opción A: Recreación Automática en 1 Clic (`RECREAR_BASE.sql`)
1. Abrir el archivo **`scripts/RECREAR_BASE.sql`** en SSMS.
2. Actualizar en la línea `:setvar ScriptsDir "..."` la ruta de la carpeta `scripts` en su equipo.
3. En el menú superior de SSMS, activar **Consulta (Query) $\rightarrow$ Modo SQLCMD (SQLCMD Mode)**.
4. Presionar **F5 (Ejecutar)**. El script ejecutará automáticamente en orden:
   * El borrado previo de cualquier versión anterior (`00`).
   * La creación de la base de datos `Mundial2026` (`01`).
   * Los 4 esquemas funcionales (`02`).
   * Las 25 tablas  (`03`).
   * Los 4 módulos de Stored Procedures (`04`, `05`, `06`, `07`).

### Opción B: Ejecución Manual Paso a Paso
Ejecutar los scripts ubicados en `scripts/` respetando el siguiente **orden secuencial de dependencias**:

1. **`00_borrado_base_de_datos.sql`**: Elimina conexiones activas y borra la base de datos si existiera.
2. **`01_creacion_base_de_datos.sql`**: Crea desde cero la base de datos `Mundial2026`.
3. **`02_creacion_esquemas.sql`**: Crea los 4 esquemas funcionales (`administracion`, `partido`, `arbitraje`, `publicidad`).
4. **`03_creacion_tablas.sql`**: Crea las 25 tablas con sus restricciones.
5. **`04_sp_administracion.sql`**: Compila los Stored Procedures del Módulo 1 (Administración y Convocatorias).
6. **`05_sp_partidos_y_cambios.sql`**: Compila los Stored Procedures del Módulo 2 (Partidos, Formaciones, Alineaciones y Sustituciones).
7. **`06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`**: Compila los Stored Procedures del Módulo 3 (Árbitros, Designaciones, Goles, Tarjetas y Suspensiones).
8. **`07_sp_publicidad.sql`**: Compila los Stored Procedures del Módulo 4 (Publicidad y Motor de Asignación).

---

## 🧪 Testing

Cada uno de los módulos cuenta con su correspondiente script de pruebas en la carpeta `tests/`.

* **`test_04_administracion.sql`**: Valida ABM de países, sedes, selecciones, clubes, técnicos y convocatorias.
* **`test_05_partidos_y_cambios.sql`**: Valida programación de partidos, conversión automática de husos a UTC, alineaciones titulares de 11 jugadores, capitanes únicos y límite de ventanas de sustitución reglamentarias.
* **`test_06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`**: Valida designaciones arbitrales con neutralidad estricta, registro de goles, tarjetas y suspensiones.
* **`test_07_publicidad.sql`**: Valida el ciclo comercial completo y el motor de asignación publicitaria priorizando patrocinadores e idioma del país local.


 Todas las pruebas corren dentro de transacciones que finalizan con `ROLLBACK TRANSACTION`, dejando la base de datos limpia tras cada ejecución.


---

## 👥 Integrantes del Grupo

* **Aleman Flores, Matias Osvaldo**
* **Gamarra Bravo, Sidney Maribel**
* **Pereira, Carlos Manuel**
* **Villa, Brenda**
