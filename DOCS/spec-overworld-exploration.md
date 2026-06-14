# Feature Specification: Exploración / Overworld 2D-HD

**Created**: 2026-06-12

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Movimiento del Personaje en el Overworld (Priority: P1)

El jugador controla al protagonista en un entorno 3D con perspectiva de cámara fija/semi-fija (estilo 2D-HD). El personaje es un sprite 2D que se mueve en 8 direcciones sobre el escenario 3D. Puede caminar y correr.

**Why this priority**: Sin capacidad de moverse por el mundo no hay exploración. Es el prerequisito fundamental.

**Independent Test**: Se puede testear creando una escena simple con un terreno 3D, un sprite 2D del protagonista, y verificando el movimiento en 8 direcciones con input de teclado/control.

**Acceptance Scenarios**:

1. **Scenario**: Movimiento básico en 8 direcciones
   - **Given** el jugador está en una zona explorable
   - **When** presiona las teclas direccionales (WASD / joystick)
   - **Then** el personaje sprite se mueve en la dirección correspondiente con animación de caminata

2. **Scenario**: Correr
   - **Given** el jugador está caminando en una dirección
   - **When** mantiene presionado el botón de correr (Shift / B)
   - **Then** el personaje se mueve a mayor velocidad con animación de carrera

3. **Scenario**: Colisiones con el entorno
   - **Given** el jugador camina hacia una pared, roca u obstáculo sólido
   - **When** el sprite colisiona con el collider del obstáculo
   - **Then** el personaje se detiene y no puede atravesar el obstáculo

---

### User Story 2 - Interacción con Objetos y NPCs (Priority: P1)

El jugador puede interactuar con objetos del entorno (cofres, puertas, señales, items en el suelo) y hablar con NPCs presionando un botón de interacción cuando está cerca.

**Why this priority**: La interacción es lo que convierte el movimiento en exploración significativa. Sin esto, el overworld es solo un pasillo vacío.

**Independent Test**: Se puede testear colocando un NPC y un objeto interactuable en la escena de prueba, acercando al jugador y presionando el botón de interacción.

**Acceptance Scenarios**:

1. **Scenario**: Interactuar con un NPC
   - **Given** el jugador está a ≤2 unidades de distancia de un NPC
   - **When** presiona el botón de interacción (E / A)
   - **Then** se inicia un diálogo y el movimiento del jugador se pausa hasta terminar

2. **Scenario**: Interactuar con un objeto del entorno
   - **Given** el jugador está junto a un cofre cerrado
   - **When** presiona el botón de interacción
   - **Then** se reproduce animación de apertura y se obtienen los items contenidos

3. **Scenario**: Indicador visual de interacción disponible
   - **Given** el jugador se acerca a un objeto o NPC interactuable
   - **When** entra en el rango de interacción
   - **Then** aparece un indicador visual (ícono flotante, resplandor) sobre el objeto/NPC

---

### User Story 3 - Zonas y Transiciones entre Áreas (Priority: P2)

El mundo está dividido en zonas/áreas. Al llegar a un punto de transición (entrada de cueva, puerta de edificio, camino entre zonas), la pantalla hace fade y se carga la nueva zona. El sistema recuerda la posición del jugador en cada zona.

**Why this priority**: Define la estructura del overworld y permite dividir el mundo en escenas manejables para Godot.

**Independent Test**: Se puede testear creando dos zonas de prueba con un trigger de transición entre ellas y verificando que el jugador aparece en la posición correcta de la zona destino.

**Acceptance Scenarios**:

1. **Scenario**: Transición entre zonas
   - **Given** el jugador pisa un trigger de transición (entrada a un edificio)
   - **When** se activa el trigger
   - **Then** ocurre un fade out/in, se carga la nueva escena, y el jugador aparece en el punto de entrada correspondiente

2. **Scenario**: Salida de zona reversible
   - **Given** el jugador entró a un edificio desde el overworld
   - **When** sale del edificio por la puerta
   - **Then** reaparece en la posición exacta frente a la entrada del edificio en el overworld

3. **Scenario**: Zonas bloqueadas por progresión
   - **Given** el jugador llega a una zona que requiere un flag de historia o item
   - **When** intenta entrar sin el requisito
   - **Then** se muestra un mensaje indicando qué se necesita y la transición no ocurre

---

### User Story 4 - Encuentros en el Overworld (Priority: P2)

En ciertas zonas (hierba alta, cuevas, rutas), el jugador puede iniciar encuentros que transicionan al sistema de combate. En modo Historia los encuentros pueden ser fijos o aleatorios. En modo Roguelike, el jugador ve los nodos de encuentro y los elige directamente (integración con el mapa de nodos).

**Why this priority**: Conecta la exploración con el sistema de combate. Es el puente entre ambos sistemas.

**Independent Test**: Se puede testear creando una zona con un trigger de encuentro y verificando que al activarse se transiciona correctamente a la escena de combate.

**Acceptance Scenarios**:

1. **Scenario**: Encuentro aleatorio en zona hostil
   - **Given** el jugador camina por hierba alta (zona hostil)
   - **When** el contador de pasos alcanza el umbral aleatorio
   - **Then** se inicia transición a combate contra un enemigo del pool de la zona

2. **Scenario**: Encuentro fijo de historia
   - **Given** el jugador llega a un punto específico del mapa
   - **When** pisa el trigger de encuentro fijo
   - **Then** se inicia un combate con enemigos predefinidos y diálogo de apertura

3. **Scenario**: Evasión de encuentros con repulsor
   - **Given** el jugador tiene un item de repulsión activo
   - **When** camina por hierba alta
   - **Then** los encuentros aleatorios no se activan mientras el repulsor esté activo

---

### User Story 5 - Cámara y Perspectiva 2D-HD (Priority: P3)

La cámara mantiene una perspectiva fija o semi-fija que emula el estilo 2D-HD: ángulo inclinado, profundidad de campo, sprites 2D orientados hacia la cámara (billboarding) dentro de entornos 3D con iluminación dinámica.

**Why this priority**: Define la identidad visual, pero el juego es funcional con una cámara simple durante desarrollo temprano.

**Independent Test**: Se puede testear en una escena con assets 3D placeholder y sprites 2D, verificando que los sprites siempre enfrentan a la cámara y que la profundidad se lee correctamente.

**Acceptance Scenarios**:

1. **Scenario**: Sprites 2D siempre visibles
   - **Given** la cámara está en ángulo fijo (ej. 45°)
   - **When** el personaje sprite se mueve por el escenario 3D
   - **Then** el sprite siempre rota para enfrentar a la cámara (billboarding) y no se ve de perfil ni distorsionado

2. **Scenario**: Profundidad de campo y sorting por Y
   - **Given** hay dos sprites en diferentes posiciones del eje Y (profundidad)
   - **When** un sprite está detrás de un objeto 3D
   - **Then** los sprites más cercanos a la cámara (Y menor en perspectiva) se renderizan encima de los más lejanos

3. **Scenario**: Iluminación afecta a sprites
   - **Given** un sprite está en una zona con luz tenue (sombra de un árbol 3D)
   - **When** el sprite entra en el área de sombra
   - **Then** el sprite se modula/oscurece acorde a la iluminación de la zona 3D

---

### Edge Cases

- **Dos interactuables en rango simultáneo**: Prioridad por cercanía (el más cercano al jugador tiene prioridad).
- **Input durante fade de transición**: Se bloquea el input del jugador hasta que termine el fade.
- **Persistencia de NPCs y objetos al cambiar de zona**: Los NPCs y objetos dinámicos persisten su estado al cambiar de zona y volver.
- **Depth-sorting en superficies inclinadas o puentes**: [PENDIENTE DE DEFINIR]
- **Encuentros aleatorios en zonas seguras**: No, los encuentros aleatorios no se activan en zonas seguras (pueblos, interiores, etc.).
- **Transición de cámara entre ángulos al cambiar de zona**: Transiciones suaves entre ángulos fijos.
- **Sprite 2D "acostado" con cámara muy inclinada**: [PENDIENTE DE DEFINIR]

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE permitir el movimiento del personaje en 8 direcciones con velocidades diferenciadas para caminar y correr.
- **FR-002**: El sistema DEBE manejar colisiones entre el personaje jugador y los colliders del entorno 3D.
- **FR-003**: El sistema DEBE detectar interactuables (NPCs, objetos) en un radio de 2 unidades y mostrar un indicador visual cuando el jugador entra en rango.
- **FR-004**: El sistema DEBE soportar un botón de interacción que inicie diálogo con NPCs o active objetos según el tipo de interactuable enfocado.
- **FR-005**: El mundo DEBE dividirse en zonas/escenas independientes con triggers de transición bidireccionales configurables (posición de entrada y salida).
- **FR-006**: El sistema DEBE persistir la posición y orientación del jugador por zona y restaurarla al regresar.
- **FR-007**: El sistema DEBE soportar encuentros aleatorios en zonas designadas, con contador de pasos y umbrales configurables por zona.
- **FR-008**: El sistema DEBE soportar encuentros fijos por trigger, vinculados a la historia o posición en el mapa.
- **FR-009**: El sistema DEBE distinguir entre zonas seguras (sin encuentros) y zonas hostiles (con encuentros).
- **FR-010**: La cámara DEBE mantener un ángulo fijo por zona con opción de transición suave entre ángulos al cambiar de zona.
- **FR-011**: Los sprites 2D DEBEN aplicar billboarding (siempre enfrentar a la cámara) para mantener la estética 2D-HD.
- **FR-012**: El sistema de renderizado DEBE ordenar sprites por su posición Y (depth sorting) para correcta percepción de profundidad.

- **FR-013**: El sistema DEBE usar fade a negro como transición entre zonas (sin animaciones complejas del protagonista).
- **FR-014**: El overworld DEBE tener un ciclo día/noche dinámico que afecte visibilidad y encuentros.
- **FR-015**: El sistema DEBE soportar vehículos de viaje rápido desbloqueables progresivamente: patines → bicicleta → motocicleta, usables en zonas ya visitadas.

### Key Entities

- **OverworldArea (Zona)**: Una escena de Godot que representa un área del overworld. Atributos: ID, nombre, tipo (pueblo, ruta, mazmorra, interior), es_zona_segura (bool), pool de encuentros, ángulo de cámara, BGM.
- **TransitionTrigger**: Volumen que delimita un punto de transición entre zonas. Atributos: zona_destino, punto_entrada_destino, dirección (entrada/salida), animación de transición.
- **Interactable (Interactuable)**: Cualquier objeto o NPC con el que el jugador puede interactuar. Atributos: tipo (NPC, cofre, puerta, señal, item_suelo), rango de interacción, prompt visual.
- **NPC**: Personaje no jugable en el overworld. Atributos: ID, sprite 2D, diálogos asociados, patrulla/movimiento (opcional), horario (opcional, si hay día/noche).
- **EncounterTrigger**: Define cómo se inician combates. Tipos: aleatorio (contador de pasos + umbral + pool enemigos) o fijo (trigger de posición + enemigos predefinidos).
- **OverworldPlayer**: Estado del jugador en el overworld. Atributos: zona_actual, posición, orientación, repulsor_activo, conteo_pasos.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El movimiento del personaje responde al input en ≤50ms, sin perceptible input lag.
- **SC-002**: Las transiciones entre zonas (fade out + carga + fade in) se completan en menos de 2 segundos en hardware objetivo.
- **SC-003**: El sistema de depth sorting por Y renderiza correctamente sprites en escenarios con al menos 3 niveles de profundidad, verificado visualmente.
- **SC-004**: El 100% de los interactuables en una zona muestran su indicador visual al entrar el jugador en rango.
- **SC-005**: El sistema de encuentros aleatorios respeta la tasa configurada (±10% de margen) en una muestra de 1000 pasos en zona hostil.
- **SC-006**: El 90% de playtesters navega exitosamente entre 3 zonas distintas sin confundirse ni quedarse atascado en la primera sesión.
