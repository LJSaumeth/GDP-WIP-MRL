# Feature Specification: Deckbuilder Roguelike - Combate Pokémon (estilo Slay the Spire)

**Created**: 2026-05-21
**Updated**: 2026-06-12 (adaptado a temática Pokémon)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Combate con Movimientos (Priority: P1)

El jugador (entrenador) inicia un combate Pokémon por turnos contra un entrenador rival o Pokémon salvaje. Cada Pokémon del equipo del jugador tiene su propio mazo de movimientos. Al inicio de cada turno, recibe una mano de movimientos, elige cuáles usar gastando energía, y termina su turno. El enemigo ejecuta su intención (atacar, defender, aplicar estado alterado). El ciclo se repite hasta que todos los Pokémon de un bando quedan fuera de combate (0 HP).

**Why this priority**: Es el núcleo de toda la experiencia. Sin combate funcional no existe el juego.

**Independent Test**: Se puede testear iniciando un combate con un equipo de 1 Pokémon y un mazo predefinido de 10 movimientos contra un entrenador rival con IA fija. Entrega valor completo como loop básico jugable.

**Acceptance Scenarios**:

1. **Scenario**: Entrenador usa un movimiento de ataque
   - **Given** el Pokémon activo tiene al menos 1 de energía y un movimiento de ataque en la mano
   - **When** selecciona el movimiento y lo usa
   - **Then** se descuenta la energía, el movimiento va al descarte y el Pokémon enemigo recibe el daño indicado

2. **Scenario**: Entrenador usa un movimiento defensivo
   - **Given** el Pokémon activo tiene energía suficiente y un movimiento defensivo en la mano
   - **When** usa el movimiento
   - **Then** se suma Defensa al Pokémon activo; la Defensa absorbe daño entrante antes de reducir HP

3. **Scenario**: Entrenador se queda sin energía
   - **Given** el entrenador gastó toda su energía en el turno
   - **When** intenta usar otro movimiento
   - **Then** el movimiento no se ejecuta y se muestra feedback visual de energía insuficiente

4. **Scenario**: Fin de turno
   - **Given** el entrenador presiona "Terminar Turno"
   - **When** el sistema procesa el fin de turno
   - **Then** los movimientos en mano van al descarte, la Defensa del Pokémon activo se resetea, el enemigo ejecuta su intención y pasa al siguiente turno del jugador (nueva mano, energía restaurada)

5. **Scenario**: Mazo agotado durante el robo
   - **Given** el mazo de robo de un Pokémon está vacío y se deben robar movimientos
   - **When** el sistema intenta robar
   - **Then** el descarte se baraja y se convierte en el nuevo mazo de robo; el robo continúa normalmente

6. **Scenario**: Pokémon debilitado (0 HP)
   - **Given** un Pokémon del equipo llega a 0 HP
   - **When** se resuelve el daño final
   - **Then** ese Pokémon queda fuera de combate; los demás Pokémon del equipo continúan peleando con sus mazos independientes

---

### User Story 2 - Navegación por el Mapa de la Liga (Priority: P2)

El jugador ve un mapa con nodos interconectados que representan encuentros en su camino hacia el Alto Mando (ruta de la Liga Pokémon). Los nodos incluyen: Entrenador (combate normal), Entrenador Élite, Evento (?), Tienda Pokémon ($), Centro Pokémon (descanso) y Líder de Gimnasio (jefe). Elige una ruta y progresa nodo a nodo hasta llegar al Líder de Gimnasio del acto.

**Why this priority**: Sin mapa no hay progresión ni decisiones estratégicas entre combates. Es el segundo pilar del loop.

**Independent Test**: Se puede testear generando un mapa de un acto y permitiendo al jugador navegar entre nodos (sin combate real, solo transición de pantallas).

**Acceptance Scenarios**:

1. **Scenario**: Entrenador elige el siguiente nodo
   - **Given** el jugador está en un nodo completado y hay nodos adyacentes disponibles
   - **When** selecciona uno de los nodos accesibles
   - **Then** se navega a ese encuentro y los demás nodos del mismo nivel se vuelven inaccesibles

2. **Scenario**: Nodo de Centro Pokémon
   - **Given** el jugador llega a un Centro Pokémon
   - **When** elige "Curar Pokémon"
   - **Then** todo el equipo recupera el 30% de su HP máximo

3. **Scenario**: Nodo de Líder de Gimnasio bloqueado
   - **Given** el jugador no ha completado suficientes nodos del acto
   - **When** intenta acceder al nodo del Líder de Gimnasio directamente
   - **Then** el nodo no es accesible hasta completar el camino requerido

---

### User Story 3 - Aprendizaje de Movimientos (Construcción del Mazo) (Priority: P2)

Al vencer un entrenador o entrenador élite, el jugador puede enseñar un movimiento nuevo a uno de sus Pokémon (agregar una carta al mazo de ese Pokémon). En la Tienda Pokémon puede comprar MTs/MOs (movimientos) o eliminar movimientos del mazo. Esto permite al jugador moldear la estrategia de su equipo a lo largo de la run.

**Why this priority**: El aprendizaje de movimientos es la capa estratégica que define al equipo. Sin ella, cada run se siente igual.

**Independent Test**: Se puede testear mostrando la pantalla de recompensa post-combate con 3 opciones de movimiento, y permitiendo al jugador elegir uno o saltar.

**Acceptance Scenarios**:

1. **Scenario**: Recompensa de movimiento tras combate
   - **Given** el jugador venció un combate normal
   - **When** se muestra la pantalla de recompensa
   - **Then** se presentan 3 movimientos aleatorios del pool de la criatura correspondiente; el jugador puede elegir uno para el Pokémon activo o no elegir ninguno

2. **Scenario**: Eliminar un movimiento en la Tienda Pokémon
   - **Given** el jugador está en la Tienda Pokémon y tiene Pokédólares suficientes
   - **When** elige olvidar un movimiento de un Pokémon
   - **Then** el movimiento se elimina permanentemente del mazo de ese Pokémon durante la run

3. **Scenario**: Mazo visible en todo momento
   - **Given** el jugador está en cualquier pantalla del juego
   - **When** abre la vista de equipo/mazo
   - **Then** puede ver todos los movimientos del mazo de cada Pokémon con sus descripciones completas

---

### User Story 4 - Objetos Equipados y Efectos Pasivos (Priority: P3)

El jugador obtiene objetos equipables (Held Items) a lo largo de la run que modifican pasivamente las reglas del juego (ej. "Restos" recupera HP al final del turno, "Cinta Focus" sobrevive con 1 HP, "Pañuelo Elegido" aumenta el daño del primer movimiento). Cada Pokémon del equipo puede tener 1 objeto equipado.

**Why this priority**: Los objetos equipados son la capa de build que hace cada run única. Importantes para retención, pero el juego es viable sin ellos inicialmente.

**Independent Test**: Se puede testear asignando manualmente un objeto equipado a un Pokémon al inicio de la run y verificando que su efecto se aplica correctamente en combate.

**Acceptance Scenarios**:

1. **Scenario**: Objeto equipado con efecto al inicio del combate
   - **Given** un Pokémon tiene "Hierro" equipado (+Defensa al inicio del combate)
   - **When** comienza un nuevo combate
   - **Then** el Pokémon inicia con el buff de Defensa aplicado antes del primer turno

2. **Scenario**: Objeto equipado en UI
   - **Given** el jugador posee varios objetos equipados en su inventario
   - **When** hace hover/tap sobre un objeto
   - **Then** se muestra el nombre y descripción completa del objeto

3. **Scenario**: Cambiar objeto equipado entre combates
   - **Given** el jugador tiene múltiples objetos equipados en el inventario
   - **When** abre la pantalla de equipo entre combates
   - **Then** puede asignar/reasignar 1 objeto por Pokémon

---

### User Story 5 - Derrota y Fin de Run (Priority: P3)

Cuando todo el equipo del jugador llega a 0 HP, la run termina. Se muestra un resumen (acto alcanzado, movimientos aprendidos, objetos obtenidos, puntuación). El jugador regresa al punto de la historia desde donde accedió a la Liga.

**Why this priority**: Completar el loop con derrota y reinicio es esencial para el género roguelike, pero se puede testear el juego sin esta pantalla en etapas tempranas.

**Independent Test**: Se puede testear forzando la derrota total y verificando que aparece la pantalla de resumen con los datos correctos de la run.

**Acceptance Scenarios**:

1. **Scenario**: Derrota total del equipo
   - **Given** todo el equipo del jugador llega a 0 HP
   - **When** el último Pokémon es debilitado
   - **Then** el combate termina, se muestra animación de derrota y se transiciona a la pantalla de resumen de run

2. **Scenario**: Pantalla de resumen
   - **Given** el jugador perdió o derrotó al Alto Mando (jefe final del Acto 3)
   - **When** se muestra el resumen
   - **Then** aparecen: acto/piso alcanzado, puntuación calculada, movimientos finales de cada Pokémon, objetos obtenidos, y botón para regresar

---

### Edge Cases

- **Mano y mazo vacíos al inicio del turno**: Los movimientos en la pila de descarte regresan al mazo, se barajea y se da una nueva mano.
- **Daño igual a la Defensa**: Se elimina toda la Defensa y el daño resultante es 0.
- **Efecto al robar con mazo vacío**: Primero se aplica el efecto del movimiento, luego se baraja el descarte en el mazo.
- **Movimientos con coste 0 de energía**: Los loops infinitos no son bugs, son una feature del juego. No se limita su uso.
- **Cerrar app durante combate**: No se guarda el estado del combate. Al reabrir, el jugador continúa desde su último save point.
- **Objeto equipado y movimiento con efectos contradictorios**: Se activa primero el objeto equipado, luego el movimiento.
- **Generador produce camino sin salida al Líder de Gimnasio**: El generador NO puede crear un camino sin salida. Es una restricción del algoritmo de generación.
- **Cambio de Pokémon activo durante el turno**: El jugador puede alternar entre los Pokémon de su equipo (máximo 3) en cualquier momento del turno; cada uno mantiene su mano, energía y mazo independientes.
---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE gestionar un ciclo de combate por turnos: turno del entrenador → turno del enemigo, con fin de combate al debilitar a todos los Pokémon de un bando (0 HP).
- **FR-002**: El sistema DEBE mantener un mazo de movimientos por cada Pokémon del equipo con tres pilas: robo, mano y descarte. Al agotarse el robo, el descarte se baraja automáticamente.
- **FR-003**: El entrenador DEBE disponer de un pool de energía por turno que se restaura al inicio del turno y limita los movimientos usables por turno.
- **FR-004**: El sistema DEBE resolver los movimientos en orden de uso, aplicando daño, Defensa y estados alterados (Envenenado, Quemado, Paralizado, Congelado, Dormido, Confundido) según las reglas de cada movimiento.
- **FR-005**: Los enemigos DEBEN mostrar su intención del próximo turno (ej. "Placaje → 15 de daño", "Amnesia → +Defensa", "Tóxico → Envenenar") antes de que el jugador actúe.
- **FR-006**: El sistema DEBE generar un mapa por acto con nodos de tipo: Entrenador (combate normal), Entrenador Élite, Evento (?), Tienda Pokémon ($), Centro Pokémon (descanso) y Líder de Gimnasio (jefe).
- **FR-007**: El jugador DEBE poder navegar el mapa eligiendo solo nodos adyacentes al nodo actual; los nodos del mismo nivel solo son accesibles si están conectados.
- **FR-008**: Al completar un combate, el sistema DEBE ofrecer al jugador una selección de movimientos para enseñar a un Pokémon de su equipo (o saltar).
- **FR-009**: El sistema DEBE persistir el estado completo de la run (mazos, HP de cada Pokémon, objetos equipados, posición en mapa, Pokédólares) entre sesiones.
- **FR-010**: El sistema DEBE calcular y mostrar una puntuación al finalizar la run basada en acto alcanzado, entrenadores derrotados y movimientos aprendidos.
- **FR-011**: El sistema DEBE soportar un equipo de 1 a 3 Pokémon por run, cada uno con su mazo de movimientos independiente.
- **FR-012**: El sistema DEBE soportar al menos 3 actos, cada uno con su propio pool de entrenadores enemigos, élites y Líder de Gimnasio.
- **FR-013**: El sistema DEBE ser exclusivamente single-player, sin componentes multijugador ni scores online.
- **FR-014**: El sistema DEBE escalar la dificultad incrementalmente basándose en el nivel del jugador (ej. Líderes de Gimnasio siempre 2 niveles por encima del jugador).

### Key Entities

- **Move (Movimiento)**: Representa un ataque o técnica Pokémon jugable. Atributos: nombre, descripción, coste de energía, tipo elemental, categoría (Físico / Especial / Estado), rareza (Básico / Común / Poco común / Raro), efectos al usar.
- **Deck (Mazo)**: Colección de movimientos de un Pokémon en la run. Se divide en tres pilas: `drawPile`, `hand`, `discardPile`.
- **Pokémon (en combate)**: Estado de un Pokémon del equipo en combate. Atributos: criatura asociada, HP actual, HP máximo, mazo, objeto equipado, buffs/debuffs activos, estado alterado actual.
- **TrainerState (Estado del Entrenador)**: Atributos globales del jugador en la run: energía actual, energía máxima, Pokédólares, mochila de objetos equipados.
- **EnemyTrainer (Entrenador Enemigo)**: Oponente en combate con su propio equipo Pokémon. Atributos: nombre, clase (Entrenador / Élite / Líder), Pokémon activo (con HP, intención, buffs/debuffs), patrón de IA.
- **HeldItem (Objeto Equipado)**: Objeto pasivo equipable a un Pokémon con efecto permanente durante la run. Se activa en hooks definidos (inicio de combate, inicio de turno, al recibir daño, al debilitar enemigo, etc.).
- **StatusCondition (Estado Alterado)**: Condición que afecta a un Pokémon (Envenenado, Quemado, Paralizado, Congelado, Dormido, Confundido). Puede ser infligida por movimientos o habilidades.
- **StatModifier (Buff/Debuff)**: Modificador temporal de stats: Ataque ↑↓, Defensa ↑↓, Velocidad ↑↓. Afectan el daño infligido y recibido.
- **MapNode (Nodo del Mapa)**: Un encuentro en el mapa de la Liga. Atributos: tipo, posición (acto, fila, columna), conexiones a nodos siguientes, estado (visitado / disponible / bloqueado).
> Las mecánicas especiales (Mega Evolución, Movimientos Z, Gigantamax/Dynamax, Teracrestalización) y la Barra de Furor están definidas en `specs/spec-furor-system.md`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El jugador puede completar un combate (desde inicio hasta victoria o derrota) en menos de 5 minutos en condiciones normales.
- **SC-002**: El sistema resuelve cada movimiento usado (daño, Defensa, estados) en menos de 200ms sin drops de framerate perceptibles.
- **SC-003**: El 90% de los playtesters puede entender el loop básico de combate (usar movimientos, terminar turno, enemigo actúa) sin instrucciones adicionales en su primera sesión.
- **SC-004**: El mapa generado garantiza siempre al menos 2 caminos distintos al Líder de Gimnasio por acto, verificable en el 100% de las seeds probadas.
- **SC-005**: El estado de la run se guarda correctamente y puede restaurarse tras cerrar y reabrir la aplicación en el 100% de los casos de prueba.
- **SC-006**: Al menos el 60% de los jugadores en pruebas de usuario inician una segunda run inmediatamente después de perder en la primera (retención por loop).
- **SC-007**: El pool de movimientos y objetos equipados produce combinaciones suficientes para que ningún par de runs se sientan idénticas, medido cualitativamente en sesiones de playtest con al menos 10 runs distintas.
