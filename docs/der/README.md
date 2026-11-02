# Diagrama Entidad-Relación (DER)

Este directorio contiene el modelo conceptual y relacional del sistema.

---

## Historial de Versiones

### Versión 1.0 - 02/10/2026
* **Alcance cubierto:**
  * Países, husos horarios y sedes/estadios.
  * Selecciones, planteles, cuerpos técnicos y convocatorias.
  * Estructura de partidos por fases, esquemas tácticos y alineaciones.
  * Registro de eventos: goles, sustituciones y tarjetas.
  * Designaciones arbitrales e idiomas 
  * Suspensiones y cumplimiento de sanciones.
  * Pauta, espacios publicitarios y exhibición de contenido.

### Versión 1.1 - 07/10/2026
  * Se reincorpora ID_Seleccion en Formacion_Partido para optimizar la trazabilidad del plantel y delegar la validación de localía/visita al Stored Procedure.

### Version 1.2 - 01/11/2026
  * Se incorporo codigo_iso en administración.Pais para estandarizar la identificación de paises y garantizar un cruce unívoco y sin discrepancias de nombres en los procesos de importación y consumo de APIs externas.
  * Se incorporo latitud y longitud a la tabla Administración.Sede para facilitar los reportes de las entregas

