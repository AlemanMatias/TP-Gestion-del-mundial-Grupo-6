# Juego de Datos

##  Descripción General
El directorio `scripts/semilla/` contiene el conjunto completo de scripts para la carga de datos obligatorios de la seccion 4 del tp

La carga de datos se realizara con el script `JUEGO_DE_DATOS.sql` de la carpeta `scripts`
1. `01_administracion_y_planteles.sql`: Importación de países, sedes, selecciones, cuerpos técnicos y planteles.
2. `02_catalogo_publicidad.sql`: Carga de anunciantes, campañas, piezas publicitarias, y paises de interes.
3. `03_partidos_fase_grupos.sql`: Fixture de Fase de Grupos (Partidos 1 al 16).
4. `04_partidos_fase_final.sql`: Fase de eliminación directa (Partidos 17 al 26: 16vos, Octavos, Cuartos, Semifinales, Tercer Puesto y Gran Final).

---

## 1. Tabla de Partidos Jugados, Resultados y Árbitros Designados
A continuación se detalla la totalidad de los 26 partidos disputados en la simulación oficial, su instancia, fecha, sede, marcador y el Árbitro Principal designado:

| N° | Instancia | Fecha | Sede / Estadio | Enfrentamiento | Resultado | Árbitro Principal (Nac) |
|:--:|:---|:--:|:---|:---:|:---:|:---|
| **01** | Fase de Grupos | 11/06/2026 | Estadio Azteca (Ciudad de México, MEX) | **México vs Sudáfrica** | `2 - 1` | Szymon Marciniak (Polonia 🇵🇱) |
| **02** | Fase de Grupos | 12/06/2026 | BMO Field (Toronto, CAN) | **Argentina vs Canadá** | `2 - 0` | Pierluigi Collina (Italia 🇮🇹) |
| **03** | Fase de Grupos | 13/06/2026 | BMO Field (Toronto, CAN) | **Austria vs Nueva Zelanda** | `1 - 0` | Howard Webb (Inglaterra eng 󠁧󠁢󠁥󠁮 󠁧󠁢󠁥󠁮) |
| **04** | Fase de Grupos | 14/06/2026 | Hard Rock Stadium (Miami, USA) | **Estados Unidos vs Francia** | `1 - 2` | Nicola Rizzoli (Italia 🇮🇹) |
| **05** | Fase de Grupos | 15/06/2026 | MetLife Stadium (East Rutherford, USA) | **Brasil vs España** | `2 - 1` | Slavko Vinčić (Eslovenia 🇸🇮) |
| **06** | Fase de Grupos | 16/06/2026 | AT&T Stadium (Dallas, USA) | **Alemania vs Colombia** | `2 - 0` | John Langenus (Bélgica 🇧🇪) |
| **07** | Fase de Grupos | 17/06/2026 | SoFi Stadium (Los Ángeles, USA) | **Inglaterra vs Uruguay** | `1 - 1` | Sergio Gonella (Italia 🇮🇹) |
| **08** | Fase de Grupos | 18/06/2026 | BC Place (Vancouver, CAN) | **Portugal vs Paraguay** | `2 - 0` | Jack Taylor (Inglaterra 󠁧󠁢󠁥 󠁧󠁢󠁥e󠁧󠁢󠁥n󠁧󠁢󠁥g󠁧󠁢󠁥) |
| **09** | Fase de Grupos | 19/06/2026 | Hard Rock Stadium (Miami, USA) | **Países Bajos vs Ecuador** | `2 - 1` | Sándor Puhl (Hungría 🇭🇺) |
| **10** | Fase de Grupos | 20/06/2026 | AT&T Stadium (Dallas, USA) | **Bélgica vs Croacia** | `1 - 1` | Said Belqola (Marruecos 🇲🇦) |
| **11** | Fase de Grupos | 21/06/2026 | Estadio Akron (Guadalajara, MEX) | **Escocia vs Suiza** | `0 - 1` | Ivan Eklind (Suecia 🇸🇪) |
| **12** | Fase de Grupos | 22/06/2026 | Estadio Azteca (Ciudad de México, MEX) | **Turquía vs Panamá** | `2 - 0` | Georges Capdeville (Francia 🇫🇷) |
| **13** | Fase de Grupos | 23/06/2026 | SoFi Stadium (Los Ángeles, USA) | **Suecia vs Noruega** | `1 - 0` | Gottfried Dienst (Suiza 🇨🇭) |
| **14** | Fase de Grupos | 24/06/2026 | MetLife Stadium (East Rutherford, USA) | **Argentina vs Nueva Zelanda** | `3 - 0` | William Ling (Inglaterra eng) |
| **15** | Fase de Grupos | 25/06/2026 | Hard Rock Stadium (Miami, USA) | **Brasil vs Japón** | `2 - 1` | Nicola Rizzoli (Italia 🇮🇹) |
| **16** | Fase de Grupos | 29/06/2026 | AT&T Stadium (Dallas, USA) | **Argentina vs Austria** | `2 - 0` | Pierluigi Collina (Italia 🇮🇹) |
| **17** | Dieciseisavos | 03/07/2026 | Estadio Azteca (Ciudad de México, MEX) | **Argentina vs México** | `2 - 1` | Howard Webb (Inglaterra eng) |
| **18** | Dieciseisavos | 03/07/2026 | Hard Rock Stadium (Miami, USA) | **Brasil vs Uruguay** | `2 - 0` | Szymon Marciniak (Polonia 🇵🇱) |
| **19** | Octavos | 07/07/2026 | MetLife Stadium (East Rutherford, USA) | **Argentina vs Inglaterra** | `2 - 1` | Pierluigi Collina (Italia 🇮🇹) |
| **20** | Octavos | 07/07/2026 | AT&T Stadium (Dallas, USA) | **Brasil vs Alemania** | `2 - 1` | Slavko Vinčić (Eslovenia 🇸🇮) |
| **21** | Cuartos | 11/07/2026 | SoFi Stadium (Los Ángeles, USA) | **Argentina vs Países Bajos** | `2 - 2 (4 - 3 pen.)` | Howard Webb (Inglaterra eng) |
| **22** | Cuartos | 11/07/2026 | Hard Rock Stadium (Miami, USA) | **Brasil vs España** | `2 - 1` | Nicola Rizzoli (Italia 🇮🇹) |
| **23** | Semifinal | 14/07/2026 | MetLife Stadium (East Rutherford, USA) | **Argentina vs Francia** | `2 - 1` | Szymon Marciniak (Polonia 🇵🇱) |
| **24** | Semifinal | 15/07/2026 | AT&T Stadium (Dallas, USA) | **Brasil vs Portugal** | `1 - 0` | Pierluigi Collina (Italia 🇮🇹) |
| **25** | Tercer Puesto | 18/07/2026 | Hard Rock Stadium (Miami, USA) | **Francia vs Portugal** | `2 - 1` | Slavko Vinčić (Eslovenia 🇸🇮) |
| **26** | **Gran Final** | 19/07/2026 | MetLife Stadium (East Rutherford, USA) | **Argentina vs Brasil** | `3 - 2` | Szymon Marciniak (Polonia 🇵🇱) |


---

## 2.  Publicidades Cargadas
 Abarca 10 anunciantes, 12 campañas y 16 piezas de contenido:

| N° | Anunciante / Marca | Campaña Asociada | Nombre de la Pieza | Tipo | Idioma | Costo Base (USD) | Países de Interés Estratégico |
|:--:|:---|:---|:---|:--:|:--:|:--:|:---|
| **01** | **Adidas** | Adidas World Cup 2026 | Spot Adidas Selección Argentina | Spot | Español | $95,000.00 | ARG, URY, PRY, COL, ECU |
| **02** | **Mercado Libre** | Mercado Libre Envíos 2026 | Banner Mercado Libre Sudamérica | Banner | Español | $82,000.00 | ARG, BRA, MEX, COL, URY |
| **03** | **Banco Itaú** | Banco Itaú Brasil 2026 | Spot Banco Itaú Selección Brasil | Spot | Portugués | $91,000.00 | BRA, PRT |
| **04** | **The Coca-Cola Company** | Coca-Cola Tour 2026 | Spot Coca-Cola Latinoamérica | Spot | Español | $78,000.00 | MEX, PAN, ESP, ARG |
| **05** | **Visa Inc.** | Visa North America 2026 | Spot Visa Pagos sin Contacto | Spot | Inglés | $125,000.00 | USA, CAN, NZL |
| **06** | **Rolex SA** | Rolex Fase Eliminatoria | Spot Rolex Cronómetro Oficial | Spot | Inglés | $145,000.00 | CHE, USA, GBR, NOR |
| **07** | **Rolex SA** | Rolex Fase Eliminatoria | Spot Rolex Edición Suiza y Francia | Spot | Francés | $138,000.00 | CHE, FRA, BEL |
| **08** | **Adidas** | Adidas World Cup 2026 | Banner Adidas Selecciones Europeas | Banner | Alemán | $110,000.00 | DEU, AUT, NLD, SWE |
| **09** | **The Coca-Cola Company** | Coca-Cola Tour 2026 | Spot Coca-Cola Zero Europa | Spot | Inglés | $105,000.00 | GBR, NLD, HRV, TUR |
| **10** | **Sony Corporation** | PlayStation 5 Stadium 2026 | Spot PS5 EA Sports FC 26 | Spot | Japonés | $115,000.00 | JPN, USA, GBR |
| **11** | **Sony Corporation** | PlayStation 5 Stadium 2026 | Spot PS5 Torneo Europeo | Spot | Francés | $112,000.00 | FRA, ESP, PRT, DEU |
| **12** | **Qatar Airways** | Qatar Airways FIFA 2026 | Spot Qatar Airways Vuelos al Mundial | Spot | Árabe | $118,000.00 | QAT, USA, FRA, GBR |
| **13** | **Hyundai Motor Company** | Hyundai Movilidad 2026 | Spot Hyundai Autos Eléctricos | Spot | Coreano | $98,000.00 | KOR, NOR, DEU, ZAF |
| **14** | **Budweiser (AB InBev)** | Budweiser Fase de Grupos | Banner Budweiser Fase de Grupos | Banner | Inglés | $89,000.00 | USA, MEX, CAN, GBR, BRA |
| **15** | **Adidas** | Adidas Apertura Grupos | Banner Adidas Botines Fase de Grupos | Banner | Español | $84,000.00 | ESP, ARG, COL, MEX |
| **16** | **Adidas** | Adidas Fase Final | Spot Adidas Fase Final | Spot | Español | $135,000.00 | ARG, BRA, FRA, ESP |

---

## 3.  Tabla de Goleadores (Top 10)


| Pos. | Jugador | Selección | Puesto / Club | Goles | Detalle de Anotaciones |
|:--:|:---|:---|:---|:--:|:---|
| **01** | **ÁLVAREZ, Julián** | 🇦🇷 Argentina | FW · Atlético de Madrid (ESP) | **8** | 7 de jugada, 1 de cabeza |
| **02** | **MESSI, Lionel** | 🇦🇷 Argentina | FW · Inter Miami CF (USA) | **7** | 3 penales, 2 tiros libres, 2 de jugada |
| **03** | **MATHEUS CUNHA** | 🇧🇷 Brasil | FW · Manchester United FC (ENG) | **6** | 5 de jugada, 1 de penal |
| **04** | **NEYMAR JR** | 🇧🇷 Brasil | FW · Santos FC (BRA) | **5** | 3 de jugada, 1 tiro libre, 1 de penal |
| **05** | **JIMÉNEZ, Raúl** | 🇲🇽 México | FW · Fulham FC (ENG) | **3** | 2 de jugada, 1 de cabeza |
| **06** | **MBAPPÉ, Kylian** | 🇫🇷 Francia | FW · Real Madrid C. F. (ESP) | **3** | 2 de jugada, 1 de penal |
| **07** | **WEGHORST, Wout** | 🇳🇱 Países Bajos | FW · AFC Ajax (NED) | **3** | 2 de jugada, 1 de cabeza |
| **08** | **THURAM, Marcus** | 🇫🇷 Francia | FW · FC Internazionale Milano (ITA) | **2** | 2 de jugada |
| **09** | **LEWELING, Jamie** | 🇩🇪 Alemania | MF · VfB Stuttgart (GER) | **2** | 2 de jugada |
| **10** | **KANE, Harry** | eng Inglaterra | FW · FC Bayern München (GER) | **2** | 2 de jugada |


---

## 4.  Registro Disciplinario Completo (Tarjetas y Sanciones)
Detalle cronológico de la totalidad de las 10 tarjetas (8 amarillas, 1 doble amarilla y 1 roja directa) registradas en el sistema mediante el procedimiento `partido.sp_RegistrarTarjetaYSuspension`:

| N° | Partido | Minuto | Jugador Sancionado | Selección | Tarjeta | Motivo de la Infracción | Consecuencia Reglamentaria |
|:--:|:---|:--:|:---|:---|:--:|:---|:---|
| **01** | Partido 01: México vs Sudáfrica | 74' | **ÁLVAREZ, Edson** (#4) | 🇲🇽 México |  Amarilla | Sujeción de camiseta | Amonestación acumulativa |
| **02** | Partido 02: Argentina vs Canadá | 27' | **ROMERO, Cristian** (#13) | 🇦🇷 Argentina |  Amarilla | Falta táctica en mitad de cancha | 1ra amonestación acumulativa |
| **03** | Partido 02: Argentina vs Canadá | 35' | **OTAMENDI, Nicolás** (#19) | 🇦🇷 Argentina |  Amarilla | Discusión con rival | 1ra amonestación acumulativa |
| **04** | Partido 02: Argentina vs Canadá | 70' | **OTAMENDI, Nicolás** (#19) | 🇦🇷 Argentina |  Doble Amarilla | Infracción reiterada | Expulsión. Cumplió 1 fecha vs Nueva Zelanda (P14) |
| **05** | Partido 14: Argentina vs Nueva Zelanda | 64' | **ROMERO, Cristian** (#13) | 🇦🇷 Argentina |  Amarilla | Falta táctica | 2da amarilla acumulada. Suspensión 1 fecha cumplida vs Austria (P16) |
| **06** | Partido 17: Argentina vs México | 80' | **ROMERO, Cristian** (#13) | 🇦🇷 Argentina |  Roja Directa | Falta de último recurso | Expulsión directa. Suspensión 1 fecha cumplida vs Inglaterra (P19) |
| **07** | Partido 19: Argentina vs Inglaterra | 60' | **DE PAUL, Rodrigo** (#7) | 🇦🇷 Argentina |  Amarilla | Falta táctica | 1ra amonestación acumulativa |
| **08** | Partido 21: Argentina vs Países Bajos | 43' | **PAREDES, Leandro** (#5) | 🇦🇷 Argentina |  Amarilla | Discusión con rival | Amonestación acumulativa |
| **09** | Partido 26: Argentina vs Brasil | 55' | **VINÍCIUS JÚNIOR** (#7) | 🇧🇷 Brasil |  Amarilla | Reclamo al árbitro | Amonestación acumulativa |
| **10** | Partido 26: Argentina vs Brasil | 85' | **DE PAUL, Rodrigo** (#7) | 🇦🇷 Argentina |  Amarilla | Cortar avance rival | 2da amarilla acumulada en Final. Suspensión de 1 fecha pendiente post-torneo |

---

## 5. Casos obligatorios


| Caso| Script / Archivo | Líneas Exactas | Partido / Entorno | Detalle de Ejecución y Validación en la Base de Datos |
|:---|:---|:---:|:---:|:---|
| **1. Expulsión por doble amonestación** | `scripts/semilla/03_partidos_fase_grupos.sql` | **Líneas 218 y 226 - En la linea 534 se intenta poner al jugador en la alineacion del siguiente partido(14)** | Partido 02 (Argentina vs Canadá) | Nicolás Otamendi (#19 ARG) recibe 1ra amarilla al 35' y 2da amarilla al 70' mediante `partido.sp_RegistrarTarjetaYSuspension` con `@Es_Doble_Amarilla = 1`. Genera suspensión automática de 1 fecha cumplida en Partido 14. |
| **2. Expulsión por roja directa** | `scripts/semilla/04_partidos_fase_final.sql` | **Línea 180 - En la linea 229 se intenta poner al jugador en la alineacion del siguiente partido(19)** | Partido 17 (Argentina vs México - 16vos) | Cristian Romero (#13 ARG) recibe tarjeta roja directa al 80' por falta de último recurso (`@Tipo = 'ROJA'`). Genera suspensión automática de 1 fecha cumplida en Octavos vs Inglaterra (Partido 19). |
| **3. Suspensión por acumulación de amarillas y exclusión de formación titular** | `scripts/semilla/03_partidos_fase_grupos.sql` | **Línea 213(1er amarilla) - 556(segunda amarilla - En la linea 641 se intenta poner al jugador en la alineacion del siguiente partido(16))** | Partido 02, Partido 14 y Partido 16 | Romero (#13 ARG) recibe 1ra amarilla en P02 y 2da amarilla en P14. En Partido 16 vs Austria, el sistema lo excluye de la planilla oficial (firma 25 futbolistas) y entra Lisandro Martínez (#6) como titular en su lugar. |
| **4. Cambio por lesión dentro de los primeros 20 minutos** | `scripts/semilla/03_partidos_fase_grupos.sql` | **Línea 209** | Partido 02 (Argentina vs Canadá) | Al minuto 14' se ejecuta `partido.sp_RegistrarSustitucion` reemplazando al titular Nicolás Tagliafico (#3) por Facundo Medina (#25) con motivo `'Lesión'`. |
| **5. Prime Time simultáneo en >4 mercados y algoritmo de priorización** | `scripts/semilla/03_partidos_fase_grupos.sql` | **Línea 318**  | Hay varios partidos que se juegan en horario prime time en mas de 4 paises. Tomamos como ejemplo el partido 5 (BRA vs ESP)  | Se somete al SP `publicidad.sp_AsignarPublicidadPartido` a 6 países candidatos en ventana Prime Time . Se prioriza a los 2 países en cancha + los 2 mercados con mayor PBI per cápita, descartando a los restantes. |
| **6. Designación arbitral descartada por conflicto de nacionalidad** | `scripts/semilla/03_partidos_fase_grupos.sql` | **Línea 196** | Partido 02 (Argentina vs Canadá) | En la propia semilla se ejecuta una prueba de validación obligatoria: se intenta designar un árbitro argentino (`@id_arb_arg` de nacionalidad ARG) para dirigir Argentina vs Canadá. `arbitraje.sp_DesignarArbitro` aborta la asignación y dispara el **Error 50002** (*Conflicto de nacionalidad estricto*) |

---

## 6.  Historial de sustituciones
| Partido | Minuto | Selección | Sale | Entra | Motivo |
|:---:|:---:|:---|:---|:---|:---|
| **2** | 14' | Argentina | Nicolás Tagliafico (#3) | Facundo Medina (#25) | Lesión |
| **14** | 60' | Argentina | Rodrigo De Paul (#7) | Exequiel Palacios (#14) | Táctico |
| **14** | 72' | Argentina | Alexis Mac Allister (#20) | Ángel Di María (#15) | Táctico |
| **14** | 80' | Argentina | Lautaro Martínez (#22) | Thiago Almada (#16) | Cansancio |
| **21** | 75' | Argentina | Gonzalo Montiel (#4) | Lisandro Martínez (#6) | Táctico |
| **24** | 60' | Brasil | Matheus Cunha (#9) | Igor Thiago (#25) | Táctico |
| **26** | 65' | Brasil | Matheus Cunha (#9) | Igor Thiago (#25) | Táctico |
| **26** | 68' | Argentina | Julián Álvarez (#9) | Ángel Di María (#15) | Táctico |
| **26** | 82' | Argentina | Leandro Paredes (#5) | Enzo Fernández (#24) | Táctico |


