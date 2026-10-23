# Sistema de Gestión del Mundial de Fútbol ⚽

> Trabajo práctico correspondiente a la materia **Bases de Datos Aplicadas (3641)**  
> **Comisión:** 02-5600 (Viernes Tarde) — **Ingeniería en Informática**  
> Universidad Nacional de La Matanza (UNLaM)

---

## 📋 Descripción General

Este proyecto implementa un sistema integral de base de datos relacional para la gestión operativa, disciplinaria, arbitral y comercial de la Copa Mundial de la FIFA 2026 en Microsoft SQL Server.

* **Módulo 1 — Administración (`04_sp_administracion.sql`):** Gestión completa de países, fases del torneo, clubes, sedes con huso horario, selecciones participantes, cuerpos técnicos y planteles oficiales.
* **Módulo 2 — Partidos y Cambios (`05_sp_partidos_y_cambios.sql`):** Programación de partidos con cálculo automático de fecha/hora UTC a partir del huso horario de la sede, generación automática de los 4 espacios publicitarios del estadio, registro de resultados y asistencia , formaciones tácticas, alineaciones  y sustituciones.
* **Módulo 3 — Goles, Tarjetas, Árbitros y Suspensiones (`06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`):** Designación arbitral, registro de tarjetas amarillas y rojas, suspensiones por acumulación de amarillas en partidos distintos.
* **Módulo 4 — Publicidad y Exhibición Comercial (`07_sp_publicidad.sql`):** Gestion de espacios publicitarios, anunciantes, campañas, piezas de contenido por idioma/tarifa y países de interés comercial y asignación publicitaria por partido.

---

## 🛠️ Tecnologías y Entorno
* **Motor:** Microsoft SQL Server 2022 o superior (`.\SQLEXPRESS` / instancia local)
* **Herramienta de Gestión:** SQL Server Management Studio (SSMS)
* **Collation Oficial:** `Modern_Spanish_CI_AS`

---

## 📁 Estructura del Proyecto

```text
├── docs/
│   ├── der/                          
│   │   ├── der_v1.1.jpg              
│   │   └── der_v1.1_dbdiagram.txt    
│   └── Instalación-y-Configuración.pdf
├── scripts/
│   ├── RECREAR_BASE.sql
│   ├── 01_creacion_base_de_datos.sql
│   ├── 02_creacion_esquemas.sql
│   ├── 03_creacion_tablas.sql
│   ├── 04_sp_administracion.sql
│   ├── 05_sp_partidos_y_cambios.sql
│   ├── 06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql
│   ├── 07_sp_publicidad.sql
│   ├── test_04_administracion.sql
│   ├── test_05_partidos_y_cambios.sql
│   ├── test_06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql
│   └── test_07_publicidad.sql
├── .gitignore
└── README.md
```

---

## 🚀 Guía de Instalación y Creación desde Cero

Se establecen **dos formas** de crear y compilar toda la base de datos desde cero:

### Opción A: Recreación Automática en 1 Clic (`RECREAR_BASE.sql`)
1. Abrir el archivo **`scripts/RECREAR_BASE.sql`** en SSMS.
2. Actualizar en la línea `:setvar ScriptsDir "..."` la ruta local de la carpeta `scripts`.
3. En el menú superior de SSMS, activar **Consulta (Query) $\rightarrow$ Modo SQLCMD (SQLCMD Mode)**.
4. Presionar **F5 (Ejecutar)**. El script recreará en orden la base de datos, los esquemas, las 25 tablas y los 4 módulos de Stored Procedures.

### Opción B: Ejecución Manual Paso a Paso
Ejecutar los scripts ubicados en `scripts/` respetando el siguiente **orden secuencial de dependencias**:

1. **`01_creacion_base_de_datos.sql`**: Crea desde cero la base de datos `Mundial2026`.
2. **`02_creacion_esquemas.sql`**: Crea los 4 esquemas funcionales (`administracion`, `partido`, `arbitraje`, `publicidad`).
3. **`03_creacion_tablas.sql`**: Crea las 25 tablas relacionales con sus restricciones.
4. **`04_sp_administracion.sql`**: Compila los Stored Procedures del Módulo 1 (Administración y Convocatorias).
5. **`05_sp_partidos_y_cambios.sql`**: Compila los Stored Procedures del Módulo 2 (Partidos, Formaciones, Alineaciones y Sustituciones).
6. **`06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`**: Compila los Stored Procedures del Módulo 3 (Árbitros, Designaciones, Goles, Tarjetas y Suspensiones).
7. **`07_sp_publicidad.sql`**: Compila los Stored Procedures del Módulo 4 (Anunciantes, Campañas, Piezas, Mercados Objetivo y Motor de Asignación Publicitaria).

---

## 🧪 Testing

Cada uno de los 4 archivos de Stored Procedures cuenta con su correspondiente script de pruebas.


> * Cada script de prueba construye su propio contexto de datos invocando exclusivamente los Stored Procedures del sistema.
> * Todas las pruebas se ejecutan dentro de bloques transaccionales que revierten sus cambios al finalizar, dejando la base de datos completamente limpia y permitiendo re-ejecutar cualquier test en cualquier momento.
> 



---

## 👥 Integrantes del Grupo

* **Aleman Flores, Matias Osvaldo**
* **Gamarra Bravo, Sidney Maribel**
* **Pereira, Carlos Manuel**
* **Villa, Brenda**
