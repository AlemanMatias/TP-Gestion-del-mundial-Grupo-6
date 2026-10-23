# Sistema de Gestión del Mundial de Fútbol ⚽

> Trabajo práctico correspondiente a la materia **Bases de Datos Aplicadas (3641)**  
> **Comisión:** 02-5600 (Viernes Tarde) — **Ingeniería en Informática**  
> Universidad Nacional de La Matanza (UNLaM)

---

## 📋 Descripción General

Este proyecto implementa un sistema integral de base de datos relacional en **Tercera Forma Normal (3FN)** para la gestión operativa, disciplinaria, arbitral y comercial de la Copa Mundial de la FIFA 2026 en Microsoft SQL Server.

Todas las operaciones de **Alta, Baja y Modificación (ABM)** y las **Reglas de Negocio** de las 25 tablas del modelo se encuentran 100% encapsuladas en Procedimientos Almacenados (*Stored Procedures*), sin requerir ni permitir operaciones DML directas sobre las tablas:

* **Módulo 1 — Administración (`04_sp_administracion.sql`):** Gestión completa de países, fases del torneo, clubes, sedes con huso horario, selecciones participantes (con cupo máximo de 48 en el torneo y 4 por grupo), cuerpos técnicos (con validación de único Director Técnico por selección) y planteles oficiales (entre 23 y 26 jugadores convocados con dorsales únicos y reemplazos por lesión/baja heredando dorsal).
* **Módulo 2 — Partidos y Cambios (`05_sp_partidos_y_cambios.sql`):** Programación de partidos con cálculo automático de fecha/hora UTC a partir del huso horario de la sede, generación automática de los 4 espacios publicitarios del estadio, registro de resultados y asistencia (validando capacidad máxima de la sede), formaciones tácticas, alineaciones (control de 11 titulares y bloqueo estricto de jugadores suspendidos) y sustituciones bajo reglamento FIFA/IFAB (máximo 5 cambios en 3 ventanas en tiempo regular, y 6° cambio / 4° ventana adicional en tiempo suplementario).
* **Módulo 3 — Goles, Tarjetas, Árbitros y Suspensiones (`06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`):** ABM de árbitros e idiomas, designación arbitral con bloqueo estricto por conflicto de nacionalidad y advertencia preventiva de cruces desde dieciseisavos de final, registro/modificación/baja de goles con actualización y recálculo automático del marcador del partido (incluyendo inversión en goles en contra), registro de tarjetas amarillas y rojas con conversión automática por doble amonestación, generación parametrizable de suspensiones por acumulación de amarillas en partidos distintos, y trazabilidad de partidos perdidos por suspensión (`Partido_Perdido_Suspension`) con rehabilitación automática al cumplir la sanción.
* **Módulo 4 — Publicidad y Exhibición Comercial (`07_sp_publicidad.sql`):** ABM de espacios publicitarios (4 paneles LED por partido), anunciantes, campañas, piezas de contenido por idioma/tarifa y países de interés comercial, junto con el motor automático de asignación publicitaria por partido basado en conversión de husos horarios UTC a hora local del mercado destino (Prime Time 19:00 a 23:59 hs), PBI per cápita, países participantes en el encuentro y tarifa de la pieza.

---

## 🛠️ Tecnologías y Entorno
* **Motor:** Microsoft SQL Server 2022 o superior (`.\SQLEXPRESS` / instancia local)
* **Herramienta de Gestión:** SQL Server Management Studio (SSMS)
* **Collation Oficial:** `Modern_Spanish_CI_AS`
* **Estándar:** T-SQL puro, tipado estricto, manejo de transacciones (`TRY...CATCH` + `ROLLBACK`) y validaciones de negocio vía `THROW`.

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

Existen **dos formas** de crear y compilar toda la base de datos desde cero en **SQL Server Management Studio (SSMS)**:

### Opción A: Recreación Automática en 1 Clic (`RECREAR_BASE.sql`)
1. Abrir el archivo **`scripts/RECREAR_BASE.sql`** en SSMS.
2. Actualizar en la línea `:setvar ScriptsDir "..."` la ruta local de la carpeta `scripts`.
3. En el menú superior de SSMS, activar **Consulta (Query) $\rightarrow$ Modo SQLCMD (SQLCMD Mode)**.
4. Presionar **F5 (Ejecutar)**. El script recreará en orden la base de datos, los esquemas, las 25 tablas y los 4 módulos de Stored Procedures.

### Opción B: Ejecución Manual Paso a Paso
Ejecutar los scripts ubicados en `scripts/` respetando el siguiente **orden secuencial de dependencias**:

1. **`01_creacion_base_de_datos.sql`**: Crea desde cero la base de datos `Mundial2026` con el collation `Modern_Spanish_CI_AS`.
2. **`02_creacion_esquemas.sql`**: Crea los 4 esquemas funcionales (`administracion`, `partido`, `arbitraje`, `publicidad`).
3. **`03_creacion_tablas.sql`**: Crea las 25 tablas relacionales en 3FN con sus restricciones `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE` y `CHECK`.
4. **`04_sp_administracion.sql`**: Compila los Stored Procedures del Módulo 1 (Administración y Convocatorias).
5. **`05_sp_partidos_y_cambios.sql`**: Compila los Stored Procedures del Módulo 2 (Partidos, Formaciones, Alineaciones y Sustituciones).
6. **`06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`**: Compila los Stored Procedures del Módulo 3 (Árbitros, Designaciones, Goles, Tarjetas y Suspensiones).
7. **`07_sp_publicidad.sql`**: Compila los Stored Procedures del Módulo 4 (Anunciantes, Campañas, Piezas, Mercados Objetivo y Motor de Asignación Publicitaria).

---

## 🧪 Guía de Testing y Validación (Relación 1:1)

Cada uno de los 4 archivos de Stored Procedures cuenta con su correspondiente script de pruebas unitarias e integrales en relación **1:1** (`176 casos de prueba` automatizados en total).

> [!IMPORTANT]
> **Pruebas 100% Autónomas, Transaccionales y Sin Datos Semilla Previos:**
> * **No requieren ejecutar ningún script semilla previo:** Cada script de prueba construye su propio contexto de datos invocando exclusivamente los Stored Procedures del sistema (cero `INSERT`, `UPDATE` o `DELETE` directos sobre tablas).
> * **Aislamiento con `BEGIN TRANSACTION ... ROLLBACK TRANSACTION`:** Todas las pruebas se ejecutan dentro de bloques transaccionales que revierten sus cambios al finalizar, dejando la base de datos completamente limpia y permitiendo re-ejecutar cualquier test infinitas veces de forma idempotente.
> * **Reporte Visual en Grilla (`@Reporte`):** Al ejecutar cualquiera de los scripts de prueba con **F5**, SSMS muestra en la pestaña **Resultados** una tabla consolidada con el detalle paso a paso (`Procedimiento`, `Escenario`, `Tipo_Prueba`, `Resultado: OK / FALLÓ`, `Detalle`) y un resumen final de pruebas aprobadas.

| Script de Prueba | Módulo Evaluado | Pruebas | Alcance de Casos de Éxito y Validaciones (`THROW`) |
| :--- | :--- | :---: | :--- |
| **`test_04_administracion.sql`** | Módulo 1 (`04_sp_administracion.sql`) | **38** | • ABM completo de País, Fase_Torneo, Club, Sede, Selección, Cuerpo Técnico, Jugador y Convocatoria.<br>• Tope de 4 selecciones por grupo y único Director Técnico por selección.<br>• Control de lista de buena fe (máx. 26 convocados), dorsal único y reemplazo por lesión heredando dorsal. |
| **`test_05_partidos_y_cambios.sql`** | Módulo 2 (`05_sp_partidos_y_cambios.sql`) | **42** | • ABM de Partido con conversión horaria a UTC y generación automática de los 4 paneles LED.<br>• Bloqueo de solapamiento de sede/hora, rivales duplicados en misma fase y exceso de capacidad del estadio.<br>• ABM de Formaciones y Alineaciones: límite de 11 titulares y **bloqueo de jugador con suspensión activa**.<br>• Sustituciones FIFA: cambio por lesión antes del min. 20, tope de 5 cambios / 3 ventanas en tiempo regular, exención de entretiempo (min. 45) y 6° cambio / 4° ventana en alargue (> min. 90). |
| **`test_06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`** | Módulo 3 (`06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`) | **54** | • ABM de Árbitros, Idiomas y Designaciones con **bloqueo por conflicto de nacionalidad** y alerta preventiva en eliminatorias.<br>• ABM de Goles: actualización y recálculo automático del marcador en `Partido` e inversión en goles `'En contra'`.<br>• ABM de Tarjetas y Suspensiones: roja directa, conversión de 2° amarilla en el mismo partido a roja (`es_doble_amarilla = 1`), suspensión parametrizable por acumulación en partidos distintos, trazabilidad de partidos perdidos (`Partido_Perdido_Suspension`) y rehabilitación automática. |
| **`test_07_publicidad.sql`** | Módulo 4 (`07_sp_publicidad.sql`) | **42** | • ABM completo de Anunciante, Campaña, Pieza de Contenido, Países de Interés (`Pieza_Pais_Interes`), Espacios y Exhibiciones.<br>• **Caso Obligatorio Prime Time:** Simulación con más de 4 mercados candidatos simultáneamente en Prime Time compitiendo por los 4 paneles del partido, verificando la priorización por país participante, PBI per cápita, Prime Time y tarifa. |

---

## 👥 Integrantes del Grupo

* **Aleman Flores, Matias Osvaldo**
* **Gamarra Bravo, Sidney Maribel**
* **Pereira, Carlos Manuel**
* **Villa, Brenda**
