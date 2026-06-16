# Feature Specification: Sistema de Progresión entre Runs (Historia + Roguelike)

**Created**: 2026-06-12
**Updated**: 2026-06-12 (Roguelike se accede desde la historia, no es un modo separado)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Modo Historia: Narrativa Lineal (Priority: P1)

El jugador avanza por una historia lineal con capítulos. Cada capítulo tiene cutscenes, diálogos, exploración de zonas específicas y combates predeterminados (fijos). El progreso se guarda en slots de guardado independientes. Desde ciertos puntos de la historia, el jugador puede acceder al modo Roguelike.

**Why this priority**: El modo Historia es la experiencia principal. Sin él no hay contexto narrativo para el mundo ni los personajes.

**Independent Test**: Se puede testear creando un capítulo de prueba con una escena de diálogo, una zona explorable y un combate fijo, y verificando que el flujo del capítulo se completa correctamente.

**Acceptance Scenarios**:

1. **Scenario**: Inicio de nuevo capítulo
   - **Given** el jugador completa el capítulo anterior o inicia nueva partida
   - **When** comienza un nuevo capítulo
   - **Then** se muestra la cinemática/escena de apertura y se carga la zona inicial del capítulo

2. **Scenario**: Progresión bloqueada por combate obligatorio
   - **Given** el jugador llega a un punto de la historia que requiere un combate
   - **When** está en la zona del combate
   - **Then** el combate se inicia automáticamente y no puede evitarse; la salida está bloqueada hasta vencer

3. **Scenario**: Guardado y carga de historia
   - **Given** el jugador está en el capítulo 2, zona "Bosque"
   - **When** guarda la partida y carga desde el menú principal
   - **Then** reaparece en la misma zona, con mismo equipo, criaturas, afinidades y flags de historia

---

### User Story 2 - Acceso al Modo Roguelike desde la Historia (Priority: P1)

El modo Roguelike NO es un modo de juego separado accesible desde el menú principal. El jugador accede a él desde dentro del modo Historia, en locaciones específicas (ej. una Arena, Torre de Batalla, o evento de historia). Una vez dentro, se genera una run procedural: selección de personaje protagonista (versión con criatura), mapa de nodos por actos (3 actos), y se juega bajo las reglas del deckbuilder roguelike (ver spec-gameplay-deckbuilder.md). Cada X nodos aparecen nodos de salida para regresar a la historia. Al morir o completar la run, se regresa al punto de la historia donde se accedió.

**Why this priority**: Es el modo donde ocurre el deckbuilding. Sin acceso desde la historia, el sistema de cartas no tiene contexto.

**Independent Test**: Se puede testear colocando un punto de acceso en una escena de historia, entrando a roguelike, completando un acto, y verificando que se regresa correctamente al punto de origen.

**Acceptance Scenarios**:

1. **Scenario**: Acceso a Roguelike desde locación en historia
   - **Given** el jugador llega a una "Arena de Combate" en el overworld de la historia
   - **When** interactúa con el punto de acceso
   - **Then** se transiciona a la selección de personaje y se inicia una nueva run roguelike

2. **Scenario**: Muerte en modo roguelike
   - **Given** el HP del equipo llega a 0 en combate dentro de Roguelike
   - **When** se resuelve la muerte
   - **Then** se muestra pantalla de resumen de run y se regresa al punto de la historia donde se accedió

3. **Scenario**: Victoria en modo roguelike (derrotar jefe final)
   - **Given** el jugador vence al jefe del Acto 3
   - **When** se resuelve el combate final
   - **Then** se muestra pantalla de victoria con resumen de run, se desbloquean recompensas de meta-progresión, y se regresa al punto de origen en la historia

4. **Scenario**: Salida voluntaria durante la run
   - **Given** el jugador está en una run roguelike y encuentra un nodo de salida
   - **When** elige salir
   - **Then** se guarda el estado de la run y se regresa a la historia; puede retomar la run después desde el mismo punto de acceso

---

### User Story 3 - Meta-Progresión: Desbloqueos entre Runs (Priority: P2)

Al completar o morir en runs del modo roguelike, el jugador gana puntos de meta-progresión ("Legacy Points") según su desempeño. Estos puntos se usan para desbloquear permanentemente: nuevas cartas para los pools, nuevas reliquias, versiones alternativas del protagonista (con diferentes criaturas), y niveles de dificultad (Ascensión). Los desbloqueos se comparten entre todos los perfiles de guardado.

**Why this priority**: La meta-progresión da propósito a runs fallidas y motiva a seguir jugando. Sin embargo, el loop básico de run funciona sin esto.

**Independent Test**: Se puede testear completando una run de prueba, otorgando puntos manualmente, y verificando que los desbloqueos se aplican en runs subsiguientes.

**Acceptance Scenarios**:

1. **Scenario**: Obtención de puntos tras run
   - **Given** el jugador muere en el Acto 1, piso 5
   - **When** se muestra la pantalla de resumen
   - **Then** se calculan puntos basados en acto alcanzado, enemigos derrotados y cartas en mazo, y se suman al total acumulado

2. **Scenario**: Desbloqueo de nueva criatura para el protagonista
   - **Given** el jugador acumula suficientes Legacy Points
   - **When** gasta los puntos en el menú de meta-progresión
   - **Then** se desbloquea una nueva versión del protagonista con una criatura diferente, seleccionable en futuras runs

3. **Scenario**: Nueva carta añadida al pool
   - **Given** el jugador desbloquea un pack de cartas para un personaje
   - **When** inicia una nueva run con ese personaje
   - **Then** las cartas desbloqueadas pueden aparecer como recompensa post-combate y en la tienda

---

### User Story 4 - Interacción Historia ↔ Roguelike (Priority: P2)

El progreso en modo Historia desbloquea contenido para Roguelike: al conocer personajes en la historia, se desbloquean como personajes jugables en Roguelike. Al alcanzar ciertos puntos de la historia, se desbloquean nuevas criaturas, pools de cartas y puntos de acceso a Roguelike en el overworld. Las relaciones de dating sim no se ven afectadas por las runs de Roguelike (permanecen intactas). El estado de la historia (posición, flags, afinidades) se conserva al entrar y salir de Roguelike.

**Why this priority**: Crea sinergia entre ambas experiencias y da incentivo para avanzar en la historia.

**Independent Test**: Se puede testear completando un capítulo que presente un personaje, y verificando que ese personaje aparece como seleccionable al iniciar una run de Roguelike desde la historia.

**Acceptance Scenarios**:

1. **Scenario**: Personaje de historia desbloqueado en Roguelike
   - **Given** el jugador conoce a "Personaje X" en el capítulo 2 de la historia
   - **When** accede a Roguelike desde cualquier punto posterior de la historia
   - **Then** "Personaje X" aparece como personaje seleccionable con su criatura y mazo inicial

2. **Scenario**: Las relaciones no se ven afectadas por Roguelike
   - **Given** el jugador tiene afinidad "Enamorado" con un personaje
   - **When** completa varias runs en Roguelike
   - **Then** al regresar a la historia, todas las afinidades y relaciones permanecen intactas

3. **Scenario**: Desbloqueo exclusivo por historia
   - **Given** cierta criatura o carta solo se obtiene al completar un evento de historia
   - **When** el jugador intenta obtenerla solo jugando Roguelike
   - **Then** no está disponible hasta que se cumpla el requisito de historia

4. **Scenario**: Regreso al punto exacto de la historia tras Roguelike
   - **Given** el jugador accede a Roguelike desde la zona "Ciudad Central"
   - **When** termina o abandona la run
   - **Then** reaparece en "Ciudad Central" con el mismo estado de historia, equipo y afinidades

---

### User Story 5 - Nueva Partida+ (Priority: P3)

Al completar la historia principal, el jugador puede iniciar Nueva Partida+ (NG+). En NG+, la historia se reinicia pero se conservan todos los desbloqueos de meta-progresión (cartas, reliquias, personajes, niveles de dificultad). Las relaciones de dating sim se reinician. Las criaturas obtenidas en la run anterior NO se conservan (solo los desbloqueos de meta-progresión).

**Why this priority**: Añade rejugabilidad a la historia, pero el loop principal funciona sin NG+.

**Independent Test**: Se puede testear completando la historia con ciertos desbloqueos, iniciando NG+, y verificando que los desbloqueos persisten pero la historia y relaciones comienzan de cero.

**Acceptance Scenarios**:

1. **Scenario**: Inicio de NG+
   - **Given** el jugador completó la historia y desbloqueó 5 reliquias y 2 personajes
   - **When** inicia Nueva Partida+ desde el menú principal
   - **Then** la historia comienza desde el capítulo 1, las relaciones están a 0, pero las 5 reliquias y 2 personajes siguen desbloqueados para Roguelike

2. **Scenario**: NG+ no conserva criaturas del protagonista
   - **Given** en la run anterior el protagonista tenía "Prota & Raichu"
   - **When** inicia NG+
   - **Then** el protagonista regresa a su criatura inicial (ej. "Prota & Pikachu")

---

### User Story 6 - Gestión de Guardado (Priority: P3)

El sistema maneja múltiples perfiles de guardado. Cada perfil contiene: el progreso de historia (1 partida por perfil), el estado de una run activa de Roguelike (si existe), y las configuraciones de la partida (Harem, Netori). Los desbloqueos de meta-progresión se comparten entre todos los perfiles.

**Why this priority**: Necesario para el producto final pero no crítico para desarrollo temprano.

**Independent Test**: Se puede testear creando 2 perfiles, avanzando historia en uno y desbloqueando cosas en Roguelike en otro, y verificando que ambos ven los mismos desbloqueos.

**Acceptance Scenarios**:

1. **Scenario**: Múltiples perfiles con meta-progresión compartida
   - **Given** existen 2 perfiles de guardado
   - **When** en Perfil A se desbloquean 3 reliquias vía Roguelike
   - **Then** Perfil B también ve esas 3 reliquias desbloqueadas (meta-progresión compartida)

2. **Scenario**: Historia independiente por perfil
   - **Given** Perfil A está en capítulo 3 y Perfil B en capítulo 1
   - **When** se carga cada perfil
   - **Then** cada uno continúa desde su propio progreso de historia

3. **Scenario**: Wipe de save borra Legacy Points
   - **Given** el jugador borra su perfil de guardado
   - **When** confirma el borrado
   - **Then** los Legacy Points acumulados en ese perfil se pierden (los desbloqueos ya comprados persisten, compartidos)

---

### Edge Cases

- **Iniciar Roguelike sin haber jugado historia**: No es posible. El Modo Roguelike se accede desde la historia. No hay personajes disponibles por defecto sin desbloqueo previo (ver FR-015).
- **Cerrar app durante combate en Roguelike**: No se guarda el estado del combate. Al reabrir, el jugador continúa desde su último save point de historia.
- **Pausar run Roguelike para jugar historia**: Sí. Cada X nodos en el mapa de Roguelike aparecen nodos de salida que permiten regresar a la historia y retomar la run después.
- **Sistema de combate**: Los encuentros del modo Historia y del modo Roguelike usan exactamente el mismo sistema de combate.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE tener un único modo de juego principal: Modo Historia. El Modo Roguelike es una actividad accesible DESDE dentro del Modo Historia, no un modo separado en el menú principal.
- **FR-002**: En Modo Historia, el progreso DEBE ser lineal por capítulos con combates fijos, diálogos y cutscenes predeterminadas.
- **FR-003**: En Modo Roguelike, el sistema DEBE generar un mapa procedural de 3 actos con nodos de encuentro (combate, élite, evento, tienda, descanso, jefe) y nodos de salida cada X nodos para regresar a la historia.
- **FR-004**: El sistema DEBE permitir al jugador seleccionar un personaje (versión con criatura) entre los desbloqueados al iniciar una nueva run roguelike desde la historia.
- **FR-005**: El sistema DEBE calcular y otorgar puntos de meta-progresión (Legacy Points) al finalizar cada run (muerte o victoria) basados en desempeño.
- **FR-006**: El sistema DEBE proveer un menú de meta-progresión donde gastar Legacy Points para desbloquear: nuevas cartas, reliquias, personajes/criaturas, y niveles de dificultad.
- **FR-007**: Los desbloqueos comprados con Legacy Points DEBEN ser permanentes y compartidos entre todos los perfiles de guardado.
- **FR-008**: El progreso en Modo Historia DEBE desbloquear personajes y criaturas seleccionables en Roguelike.
- **FR-009**: Al entrar y salir del Modo Roguelike, el estado de la historia (posición, equipo, afinidades, relaciones, flags) DEBE conservarse intacto.
- **FR-010**: El sistema DEBE persistir el estado de la run de Roguelike entre nodos (no durante combate activo) para permitir continuar tras cerrar la aplicación.
- **FR-011**: El sistema DEBE soportar al menos 3 perfiles de guardado, cada uno con su propio progreso de historia independiente. La meta-progresión (Legacy Points, desbloqueos) se comparte entre perfiles.
- **FR-012**: El sistema DEBE permitir al jugador tener una run de Roguelike pausada y retomable dentro de un perfil de historia.

- **FR-013**: El sistema DEBE permitir Nueva Partida+ en modo Historia donde se conservan los desbloqueos de meta-progresión de Roguelike. La historia y relaciones se reinician.
- **FR-014**: El sistema DEBE soportar dificultad incremental en Roguelike estilo Ascensión (STS) con 20 niveles.
- **FR-015**: El sistema DEBE requerir que el jugador haya desbloqueado un personaje al menos UNA vez (vía historia o meta-progresión) para poder usarlo en Roguelike. No hay personajes disponibles por defecto sin desbloqueo previo.

### Key Entities

- **StoryProgress**: Estado de la historia. Atributos: capítulo_actual, flags_de_historia (diccionario de bools), personajes_conocidos (IDs), zona_actual, posición, relaciones (afinidades).
- **RoguelikeRun**: Una partida de Roguelike activa o pausada. Atributos: personaje_seleccionado (versión con criatura), semilla, acto_actual, nodo_actual, mazo, HP, reliquias, oro, puntuación, punto_origen_historia (zona y posición).
- **MetaProgress**: Progreso persistente entre runs y compartido entre perfiles. Atributos: legacy_points, cartas_desbloqueadas (lista IDs), reliquias_desbloqueadas (lista IDs), personajes_desbloqueados (lista IDs), nivel_dificultad_máximo (Ascensión).
- **PlayerProfile**: Perfil de guardado. Atributos: nombre, story_progress, roguelike_run (opcional, si hay una pausada), romance_config (Harem, Netori), fecha_creación.
- **RunSummary**: Resumen de una run finalizada. Atributos: personaje, acto_alcanzado, piso_alcanzado, enemigos_derrotados, cartas_en_mazo, puntuación, recompensa_legacy_points.
- **RoguelikeAccessPoint**: Punto en el overworld de la historia desde donde se accede a Roguelike. Atributos: zona, posición, requisito_historia (flag requerido).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El jugador puede entrar a Roguelike desde la historia y regresar al mismo punto en menos de 3 segundos de carga (sin pérdida de progreso).
- **SC-002**: La generación del mapa procedural para una run de 3 actos se completa en menos de 500ms.
- **SC-003**: El 100% de los desbloqueos de meta-progresión están disponibles en la siguiente run inmediatamente tras ser comprados.
- **SC-004**: El guardado y carga de una partida de historia (con todos los estados: afinidades, criaturas, flags) es correcto en el 100% de los casos de prueba automatizados.
- **SC-005**: Un jugador que completa el Acto 1 en modo Roguelike obtiene suficientes Legacy Points para desbloquear al menos 1 cosa nueva (carta, reliquia o personaje).
- **SC-006**: El sistema soporta al menos 3 perfiles de guardado simultáneos con meta-progresión compartida sin corrupción de datos, verificado con pruebas de estrés de 50 cambios de perfil.
