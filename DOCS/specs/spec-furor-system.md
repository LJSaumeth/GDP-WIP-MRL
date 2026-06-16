# Feature Specification: Sistema de Furor y Mecánicas Especiales

**Created**: 2026-06-14

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Demonstrated to users independently
-->

### User Story 1 - Acumulación y Gestión de Furor (Priority: P1)

El sistema mantiene una **Barra de Furor** con un máximo de 10 puntos. El furor se acumula durante el combate al realizar acciones (usar movimientos de ataque, recibir daño, curarse, debilitar enemigos). El jugador puede ver el nivel actual de furor en el HUD de combate. El furor se resetea a 0 al finalizar cada combate.

**Why this priority**: Es el recurso base que alimenta todas las mecánicas especiales. Sin la barra de furor, ninguna mecánica puede activarse.

**Independent Test**: Se puede testear iniciando un combate de prueba, realizando acciones que generan furor y verificando que la barra se incrementa y se muestra correctamente en el HUD.

**Acceptance Scenarios**:

1. **Scenario**: Acumulación de furor al jugar movimientos
   - **Given** el jugador inicia un combate con 0 de furor
   - **When** usa un movimiento de ataque
   - **Then** la barra de furor aumenta en +1 (o la cantidad configurada según la acción)

2. **Scenario**: Acumulación de furor al recibir daño
   - **Given** el jugador tiene 3 puntos de furor
   - **When** un Pokémon aliado recibe daño de un ataque enemigo
   - **Then** la barra de furor aumenta en +2

3. **Scenario**: Furor máximo alcanzado
   - **Given** el jugador tiene 9 puntos de furor
   - **When** realiza una acción que generaría +2 de furor
   - **Then** la barra sube a 10 y el exceso se pierde (no se acumula más allá del máximo)

4. **Scenario**: Furor se resetea al final del combate
   - **Given** el jugador termina un combate con 7 puntos de furor
   - **When** inicia el siguiente combate
   - **Then** la barra de furor vuelve a 0

---

### User Story 2 - Activación de Mecánicas Especiales (Priority: P1)

El jugador puede gastar puntos de furor para activar mecánicas especiales de combate: Mega Evolución, Movimiento Z, Gigantamax/Dynamax y Teracrestalización. Cada mecánica tiene un coste fijo de furor y un efecto específico. El jugador puede usar múltiples mecánicas en un mismo combate —no hay límite de usos por combate— mientras tenga suficiente furor.

**Why this priority**: Las mecánicas especiales son la razón de ser del sistema de furor. Sin activación, la barra de furor no tiene propósito.

**Independent Test**: Se puede testear habilitando manualmente las mecánicas, generando furor durante un combate de prueba y verificando que cada mecánica se activa correctamente al tener el furor necesario.

**Acceptance Scenarios**:

1. **Scenario**: Activar Mega Evolución gastando furor
   - **Given** el jugador tiene 5 puntos de furor y la Mega Evolución cuesta 4
   - **When** activa Mega Evolución en un Pokémon compatible
   - **Then** se consumen 4 puntos de furor, el sprite del Pokémon cambia, sus stats aumentan, y su mazo se reemplaza por la versión mega-evolucionada por el resto del combate

2. **Scenario**: Activar Movimiento Z
   - **Given** el jugador tiene 3 puntos de furor y el Movimiento Z cuesta 2
   - **When** selecciona un movimiento compatible y activa Movimiento Z antes de resolverlo
   - **Then** se consumen 2 puntos de furor y el daño del movimiento se multiplica ×2.5

3. **Scenario**: Activar Gigantamax/Dynamax
   - **Given** el jugador tiene 6 puntos de furor y Gigantamax cuesta 5
   - **When** activa Gigantamax en un Pokémon compatible
   - **Then** se consumen 5 puntos de furor, el Pokémon gana +50% HP máximo, +stats, efecto visual y el estado dura 3 turnos

4. **Scenario**: Activar Teracrestalización
   - **Given** el jugador tiene 4 puntos de furor y Teracrestalización cuesta 3
   - **When** activa Teracrestalización en un Pokémon
   - **Then** se consumen 3 puntos de furor, el tipo del Pokémon cambia al tipo Tera elegido, obtiene bonus STAB ×1.5 adicional (acumulativo con STAB normal), y el efecto dura todo el combate

5. **Scenario**: Furor insuficiente bloquea la mecánica
   - **Given** el jugador tiene 2 puntos de furor y la mecánica cuesta 5
   - **When** intenta activarla
   - **Then** la mecánica no se activa y se muestra feedback de "Furor insuficiente"

6. **Scenario**: Misma mecánica usada múltiples veces en un combate
   - **Given** el jugador ya usó Movimiento Z una vez en el combate y vuelve a acumular 2 de furor
   - **When** activa Movimiento Z nuevamente en otro movimiento
   - **Then** se consume furor normalmente y el efecto se aplica (no hay límite de usos por combate)

---

### User Story 3 - Combinación de Mecánicas en un Mismo Ataque (Priority: P2)

El jugador puede combinar múltiples mecánicas especiales en un mismo ataque. Ejemplo: un Rayquaza puede estar Mega-Evolucionado, activar Teracrestalización a tipo Volador y potenciar su ataque con Movimiento Z —todo en el mismo turno— gastando el furor acumulado de todas las mecánicas.

**Why this priority**: La combinación es el techo de habilidad del sistema. Eleva la profundidad táctica, pero el sistema es funcional sin ella (mecánicas individuales primero).

**Independent Test**: Se puede testear activando manualmente 2+ mecánicas en secuencia sobre un mismo movimiento y verificando que todos los efectos se aplican correctamente y el furor total gastado es la suma de los costes.

**Acceptance Scenarios**:

1. **Scenario**: Combinar Mega Evolución + Movimiento Z
   - **Given** el jugador tiene 8 puntos de furor, Mega Evolución activa previamente, y desea usar Movimiento Z (coste 2)
   - **When** selecciona un movimiento y activa Movimiento Z
   - **Then** se consumen 2 puntos de furor adicionales y el movimiento se potencia como Z-Move desde el estado Mega

2. **Scenario**: Combinar Teracrestalización + Movimiento Z en un mismo ataque
   - **Given** el jugador tiene 8 puntos de furor y desea usar Teracrestalización (coste 3) + Movimiento Z (coste 2)
   - **When** selecciona un movimiento de tipo Volador y aplica ambas mecánicas
   - **Then** se consumen 5 puntos de furor (3+2), el Pokémon se teracrestaliza a tipo Volador, y el movimiento se potencia como Z-Move —todo en el mismo ataque

3. **Scenario**: Orden de aplicación de mecánicas
   - **Given** el jugador activa múltiples mecánicas en un mismo ataque
   - **When** se resuelve el ataque
   - **Then** las mecánicas se aplican en el orden de activación; si dos afectan el mismo stat, sus efectos se suman multiplicativamente

4. **Scenario**: Furor total insuficiente para la combinación deseada
   - **Given** el jugador tiene 4 puntos de furor y quiere usar Mega Evolución (4) + Movimiento Z (2)
   - **When** intenta activar ambas
   - **Then** solo se permite activar hasta agotar el furor disponible; la UI muestra qué mecánicas son accesibles

---

### User Story 4 - Desbloqueo Progresivo por Historia (Priority: P2)

Las mecánicas especiales no están disponibles desde el inicio del juego. Se desbloquean progresivamente conforme el jugador avanza en la historia principal. El orden de desbloqueo es fijo: Mega Evolución → Movimientos Z → Gigantamax/Dynamax → Teracrestalización. En modo Roguelike, si el jugador ya desbloqueó una mecánica en la historia, estará disponible en la run; si no, aparecerá bloqueada.

**Why this priority**: El desbloqueo progresivo da pacing a la curva de aprendizaje y recompensa el avance en la historia. Pero el sistema de furor funciona sin esto (se puede testear con todas las mecánicas ya desbloqueadas).

**Independent Test**: Se puede testear creando una partida nueva, verificando que las mecánicas aparecen bloqueadas, y desbloqueándolas manualmente vía flags para confirmar que se habilitan en el orden correcto.

**Acceptance Scenarios**:

1. **Scenario**: Mecánica bloqueada al inicio del juego
   - **Given** el jugador está en el Capítulo 1
   - **When** abre el panel de mecánicas especiales durante un combate
   - **Then** todas las mecánicas aparecen en gris con un icono de candado y el mensaje "No disponible aún"

2. **Scenario**: Desbloqueo de Mega Evolución por evento de historia
   - **Given** el jugador completa el evento de historia que desbloquea Mega Evolución
   - **When** inicia el siguiente combate
   - **Then** Mega Evolución aparece disponible en el panel de mecánicas y puede activarse gastando furor

3. **Scenario**: Mecánica bloqueada en Roguelike si no se desbloqueó en historia
   - **Given** en la partida actual el jugador no ha desbloqueado Teracrestalización
   - **When** inicia una run Roguelike
   - **Then** Teracrestalización no aparece como opción disponible durante la run

4. **Scenario**: Mecánica desbloqueada en Roguelike se mantiene disponible
   - **Given** el jugador desbloqueó Mega Evolución y Movimientos Z en la historia
   - **When** inicia una run Roguelike
   - **Then** ambas mecánicas están disponibles desde el inicio de la run

---

### Edge Cases

- **Furor máximo alcanzado**: La barra de furor no puede exceder 10 puntos. El exceso de furor generado se pierde.
- **Furor entre combates**: El furor siempre se resetea a 0 al finalizar un combate, sin excepciones (incluyendo combates consecutivos en el mapa de la Liga).
- **Mecánicas especiales combinadas**: Las mecánicas se aplican en el orden de activación. Si dos mecánicas afectan el mismo stat, sus efectos se suman multiplicativamente.
- **Pokémon no compatible con una mecánica**: Si un Pokémon no tiene forma Mega/G-Max/Tera disponible, la mecánica correspondiente no se puede activar sobre él. La UI lo refleja deshabilitando el botón.
- **Mecánica activa al debilitarse el Pokémon**: Si un Pokémon con una mecánica activa (Mega, G-Max, Tera) es debilitado, la mecánica se pierde y no se transfiere a otro Pokémon.
- **G-Max expira durante el turno enemigo**: Al expirar el contador de 3 turnos de Gigantamax, el Pokémon revierte a su forma normal inmediatamente, perdiendo el bonus de HP (el HP actual se ajusta proporcionalmente).
- **Cambio de Pokémon con mecánicas activas**: El jugador puede alternar entre Pokémon del equipo. Si un Pokémon con una mecánica activa es cambiado, la mecánica permanece al volver a ese Pokémon (excepto G-Max cuyo contador sigue corriendo aunque no esté activo).
- **Desbloqueo en NG+**: En Nueva Partida+, todas las mecánicas especiales se reinician a bloqueadas. El jugador debe desbloquearlas nuevamente en la historia.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mantener una barra de Furor con máximo 10 puntos compartida por todo el equipo en combate.
- **FR-002**: El sistema DEBE acumular furor al realizar acciones en combate: +1 al usar movimiento de ataque, +2 al recibir daño (por golpe), +1 al curarse, +3 al debilitar un Pokémon enemigo. Los valores DEBEN ser configurables por tipo de acción.
- **FR-003**: El sistema DEBE gastar furor al activar mecánicas especiales según el coste configurado de cada una: Mega Evolución (4), Movimiento Z (2), Gigantamax/Dynamax (5), Teracrestalización (3).
- **FR-004**: El sistema DEBE resetear el furor a 0 al finalizar cada combate, sin excepciones.
- **FR-005**: El sistema DEBE impedir la activación de una mecánica si el furor actual es insuficiente, mostrando feedback visual de "Furor insuficiente".
- **FR-006**: El sistema DEBE soportar cuatro mecánicas especiales con efectos específicos:
  - **Mega Evolución**: Cambia el sprite, stats y mazo del Pokémon por una versión mega-evolucionada durante el resto del combate.
  - **Movimiento Z**: Multiplica el daño del siguiente movimiento usado por ×2.5.
  - **Gigantamax/Dynamax**: Otorga +50% HP máximo, bonus de stats, y dura 3 turnos.
  - **Teracrestalización**: Cambia el tipo elemental del Pokémon al tipo Tera elegido, otorga bonus STAB ×1.5 adicional, y dura todo el combate.
- **FR-007**: El sistema DEBE permitir usar cada mecánica especial múltiples veces en un mismo combate, sin límite fijo de usos, mientras haya furor suficiente.
- **FR-008**: El sistema DEBE permitir combinar múltiples mecánicas especiales en un mismo ataque, aplicándolas en el orden de activación del jugador.
- **FR-009**: Si dos o más mecánicas afectan el mismo stat, sus efectos DEBEN combinarse multiplicativamente.
- **FR-010**: El sistema DEBE tener flags de desbloqueo por historia para cada mecánica especial: `MEGA_UNLOCKED`, `Z_MOVES_UNLOCKED`, `GMAX_UNLOCKED`, `TERA_UNLOCKED`.
- **FR-011**: Las mecánicas especiales DEBEN desbloquearse progresivamente en el orden fijo: Mega Evolución → Movimientos Z → Gigantamax/Dynamax → Teracrestalización, mediante eventos específicos de la historia principal.
- **FR-012**: En modo Roguelike, solo las mecánicas ya desbloqueadas en la historia DEBEN estar disponibles. Las no desbloqueadas DEBEN aparecer bloqueadas en la UI.
- **FR-013**: El sistema DEBE verificar la compatibilidad del Pokémon con cada mecánica: si un Pokémon no tiene forma Mega/G-Max/Tera definida, la mecánica correspondiente DEBE estaría deshabilitada para ese Pokémon.
- **FR-014**: Si un Pokémon con una mecánica activa es debilitado, la mecánica DEBE perderse y NO transferirse a otro Pokémon.
- **FR-015**: El sistema DEBE mostrar en el HUD de combate: nivel actual de furor (barra visual segmentada), mecánicas disponibles (con su coste), y mecánicas bloqueadas (en gris con icono de candado).

### Key Entities

- **FurorBar (Barra de Furor)**: Recurso compartido del equipo en combate. Atributos: `current_furor` (int 0-10), `furor_sources` (dict[acción → valor] configurable). Métodos: `add_furor(amount)`, `can_afford(cost) → bool`, `spend_furor(cost)`, `reset()`. Se resetea a 0 al finalizar cada combate.
- **SpecialMechanic (Mecánica Especial)**: Habilidad desbloqueable por historia. Atributos: `id`, `name` (Mega Evolución / Movimiento Z / Gigantamax / Teracrestalización), `furor_cost` (int), `unlock_flag` (string), `unlock_story_event` (string). Efecto definido por tipo de mecánica.
- **MechanicUnlockState (Estado de Desbloqueo)**: Flags globales de la partida que determinan qué mecánicas están disponibles. Atributos: `mega_unlocked`, `z_moves_unlocked`, `gmax_unlocked`, `tera_unlocked` (bool). Se persisten en el save file.
- **ActiveMechanic (Mecánica Activa)**: Instancia de una mecánica aplicada a un Pokémon específico durante el combate. Atributos: `mechanic_id`, `pokemon_id`, `turns_remaining` (int, solo para G-Max), `tera_type` (solo para Tera), `active_effects` (dict[stat → modifier]).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% de las acciones que generan furor (atacar, recibir daño, curar, debilitar) incrementan la barra en la cantidad correcta en todos los escenarios de prueba.
- **SC-002**: Cada mecánica especial se activa correctamente con su coste de furor y produce el efecto esperado en el 100% de los casos de prueba.
- **SC-003**: La combinación de 2+ mecánicas en un mismo ataque resuelve los efectos en el orden correcto y con los multiplicadores adecuados en el 100% de los casos.
- **SC-004**: El desbloqueo progresivo por historia funciona correctamente: una mecánica bloqueada no puede activarse bajo ninguna circunstancia hasta que su flag se active.
- **SC-005**: La UI de furor (barra + panel de mecánicas) se actualiza en menos de 50ms tras cualquier cambio de estado (acumulación, gasto, desbloqueo).
- **SC-006**: En playtest, al menos el 70% de los jugadores utiliza al menos una mecánica especial por combate una vez que están disponibles (indicador de que el sistema es accesible y útil).
- **SC-007**: Jugadores avanzados logran consistentemente combinar 2+ mecánicas en un mismo ataque en al menos el 30% de los combates donde tienen furor suficiente (indicador de profundidad táctica).
