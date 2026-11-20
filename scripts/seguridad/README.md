# Seguridad, Cifrado y Matriz de Roles (`Mundial2026`)

Esta carpeta contiene los scripts de implementación de seguridad correspondientes a la **Entrega 8** del Trabajo Práctico.

## Orden de ejecución

1. `scripts/seguridad/01_cifrado_datos_sensibles.sql` — Crea la infraestructura criptográfica (`MASTER KEY`, certificado `Cert_Mundial2026_Seguridad` y llave simétrica `Key_Mundial2026_AES256`), cifra los campos sensibles y actualiza/crea los Stored Procedures asociados.
2. `tests/seguridad/test_01_cifrado_datos_sensibles.sql` — Valida el cifrado en disco, el fallo de descifrado con llave cerrada y el funcionamiento de los SPs visores.
3. `scripts/seguridad/02_roles_y_permisos.sql` — Ejecuta `administracion.sp_ConfigurarRolesYPermisos` para crear los **5 roles**, **5 logins**, **5 usuarios vinculados (`FOR LOGIN`)** y aplicar los permisos.
4. Tests individuales por rol (en `tests/seguridad/`):
   - `test_rol_administrador.sql`
   - `test_rol_operador_partido.sql`
   - `test_rol_gestor_publicidad.sql`
   - `test_rol_comite_arbitral.sql`
   - `test_rol_medico.sql`

---

## Resumen de Roles, Logins y Usuarios

| Rol | Login / Usuario | Perfil Funcional |
| :--- | :--- | :--- |
| `rol_administrador` | `usr_administrador` |  Acceso total y consulta de todos los datos sensibles descifrados. |
| `rol_operador_partido` | `usr_operador_partido` | Oficial de mesa en cancha. Carga eventos del partido y designa árbitros (sin leer informes descifrados). |
| `rol_gestor_publicidad` | `usr_gestor_publicidad` | Área comercial. Gestiona anunciantes, campañas, piezas y pautas publicitarias. |
| `rol_comite_arbitral` | `usr_comite_arbitral` | Comité arbitral y disciplinario. Administra árbitros, designaciones, informes descifrados y suspensiones. |
| `rol_medico` | `usr_medico` | Cuerpo Médico FIFA. Registra bajas médicas, reemplazos por lesión y consulta fichas/bajas descifradas. |

---

## Matriz Detallada: Qué Permite y Qué Niega Cada Rol

> **Regla general para todos los roles no administradores:** ningún rol operativo ni de consulta tiene acceso directo a tablas físicas (`DENY SELECT, INSERT, UPDATE, DELETE` sobre los esquemas `administracion`, `partido`, `arbitraje` y `publicidad`). Toda operación se canaliza mediante Stored Procedures.

### 1. `rol_administrador`
* **Permisos otorgados (`GRANT`):**
  * `EXECUTE, SELECT, INSERT, UPDATE, DELETE` sobre los 4 esquemas: `administracion`, `partido`, `arbitraje`, `publicidad`.
  * Acceso completo a los 3 SPs visores de datos sensibles descifrados:
    * `administracion.sp_ConsultarJugadorSensible`
    * `administracion.sp_ConsultarBajasMedicasSensibles`
    * `arbitraje.sp_ConsultarInformesArbitrales`
  * Criptografía: `CONTROL` sobre `CERTIFICATE::[Cert_Mundial2026_Seguridad]` y `REFERENCES` sobre `SYMMETRIC KEY::[Key_Mundial2026_AES256]`.
* **Permisos denegados (`DENY`):**
  * Ninguno dentro de la base `Mundial2026`.

---

### 2. `rol_operador_partido`
* **Permisos otorgados (`GRANT`):**
  * `EXECUTE` sobre todo el esquema `partido` (creación/gestión de partidos, goles, tarjetas, sustituciones, asistencia y reportes del esquema).
  * `EXECUTE` sobre los SPs puntuales de designación arbitral:
    * `arbitraje.sp_DesignarArbitro` (puede guardar el informe cifrado)
    * `arbitraje.sp_ModificarDesignacionArbitro`
    * `arbitraje.sp_EliminarDesignacionArbitro`
    * `arbitraje.sp_ReporteDesignacionesArbitrales`
  * Criptografía (mínima para cifrar al designar): `CONTROL` sobre `Cert_Mundial2026_Seguridad` y `REFERENCES` sobre `Key_Mundial2026_AES256`.
* **Permisos denegados (`DENY`):**
  * `SELECT, INSERT, UPDATE, DELETE` directo sobre tablas físicas en los 4 esquemas (`administracion`, `partido`, `arbitraje`, `publicidad`).
  * `EXECUTE` sobre los esquemas `administracion` y `publicidad`.
  * `EXECUTE` implícito sobre el resto de SPs de `arbitraje` (alta/baja/modificación de árbitros e idiomas).
  * `EXECUTE` explícito sobre los 3 SPs visores de datos sensibles (`sp_ConsultarJugadorSensible`, `sp_ConsultarBajasMedicasSensibles`, `sp_ConsultarInformesArbitrales`).
  * `ALTER, TAKE OWNERSHIP` sobre `Cert_Mundial2026_Seguridad` (no puede alterar el certificado ni apropiarse de su clave privada).

---

### 3. `rol_gestor_publicidad`
* **Permisos otorgados (`GRANT`):**
  * `EXECUTE` sobre todo el esquema `publicidad` (anunciantes, campañas, piezas, espacios, asignaciones y reporte de ocupación publicitaria).
* **Permisos denegados (`DENY`):**
  * `SELECT, INSERT, UPDATE, DELETE` directo sobre tablas físicas en los 4 esquemas.
  * `EXECUTE` sobre los esquemas `administracion`, `partido` y `arbitraje`.
  * `EXECUTE` explícito sobre los 3 SPs visores de datos sensibles.
  * `REFERENCES` sobre `SYMMETRIC KEY::[Key_Mundial2026_AES256]`.

---

### 4. `rol_comite_arbitral`
* **Permisos otorgados (`GRANT`):**
  * `EXECUTE` sobre todo el esquema `arbitraje` (alta/modificación/baja de árbitros e idiomas, designaciones, reporte de designaciones y lectura descifrada vía `arbitraje.sp_ConsultarInformesArbitrales`).
  * `EXECUTE` puntual en `partido` para gestión disciplinaria:
    * `partido.sp_ModificarSuspension`
    * `partido.sp_EliminarSuspension`
    * `partido.sp_RegistrarCumplimientoSuspension`
    * `partido.sp_ReporteTarjetasYSuspensiones`
  * Criptografía (para cifrar y descifrar informes arbitrales): `CONTROL` sobre `Cert_Mundial2026_Seguridad` y `REFERENCES` sobre `Key_Mundial2026_AES256`.
* **Permisos denegados (`DENY`):**
  * `SELECT, INSERT, UPDATE, DELETE` directo sobre tablas físicas en los 4 esquemas.
  * `EXECUTE` sobre los esquemas `administracion` y `publicidad`.
  * `EXECUTE` implícito sobre el resto de SPs operativos de `partido` (goles, sustituciones, asistencia, creación de partidos).
  * `EXECUTE` explícito sobre los visores sensibles de jugadores y bajas médicas (`administracion.sp_ConsultarJugadorSensible`, `administracion.sp_ConsultarBajasMedicasSensibles`).
  * `ALTER, TAKE OWNERSHIP` sobre `Cert_Mundial2026_Seguridad`.

---

### 5. `rol_medico`
* **Permisos otorgados (`GRANT`):**
  * `EXECUTE` puntual en `administracion` para gestión y consulta médica:
    * `administracion.sp_RegistrarBajaConvocatoria` (registra el motivo cifrado)
    * `administracion.sp_ReemplazarConvocadoUltimoMomento` (registra motivo de lesión cifrado)
    * `administracion.sp_ConsultarBajasMedicasSensibles` (consulta motivos médicos descifrados)
    * `administracion.sp_ConsultarJugadorSensible` (consulta ficha y fecha de nacimiento descifrada)
    * `administracion.sp_ReporteSeleccionesPlantillas`
  * Criptografía (para cifrar y descifrar bajas médicas y fichas de jugadores): `CONTROL` sobre `Cert_Mundial2026_Seguridad` y `REFERENCES` sobre `Key_Mundial2026_AES256`.
* **Permisos denegados (`DENY`):**
  * `SELECT, INSERT, UPDATE, DELETE` directo sobre tablas físicas en los 4 esquemas.
  * `EXECUTE` sobre los esquemas `partido`, `arbitraje` y `publicidad`.
  * `EXECUTE` explícito sobre `arbitraje.sp_ConsultarInformesArbitrales`.
  * `EXECUTE` implícito sobre el resto de SPs de `administracion` (países, sedes, fases, clubes, selecciones, altas/bajas de jugadores).
  * `ALTER, TAKE OWNERSHIP` sobre `Cert_Mundial2026_Seguridad`.
