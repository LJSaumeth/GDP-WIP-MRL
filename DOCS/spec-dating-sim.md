# Feature Specification: Sistema de Dating Sim / Relaciones

**Created**: 2026-06-12

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Interacción Básica con Personajes (Priority: P1)

El jugador puede hablar con personajes romanceables en el overworld y durante eventos de historia. Cada interacción puede otorgar puntos de afinidad según las opciones de diálogo elegidas. El jugador puede ver el nivel de afinidad actual con cada personaje.

**Why this priority**: Es la base de todo el sistema de relaciones. Sin interacción básica no existe el dating sim.

**Independent Test**: Se puede testear colocando un personaje romanceable en una escena de prueba, interactuando con él mediante un menú de diálogo simple y verificando que la afinidad cambia correctamente según las opciones elegidas.

**Acceptance Scenarios**:

1. **Scenario**: Jugador habla con un personaje romanceable
   - **Given** el jugador está junto a un personaje romanceable en el overworld
   - **When** interactúa con el personaje
   - **Then** se muestra un diálogo con al menos una opción de respuesta que afecta la afinidad

2. **Scenario**: Opción de diálogo otorga afinidad positiva
   - **Given** el jugador está en un diálogo con un personaje romanceable
   - **When** elige una opción de respuesta "positiva"
   - **Then** la afinidad con ese personaje aumenta en la cantidad configurada y se muestra feedback visual (+X afinidad)

3. **Scenario**: Jugador consulta nivel de afinidad
   - **Given** el jugador ha interactuado al menos una vez con un personaje
   - **When** abre el menú de relaciones / perfil del personaje
   - **Then** se muestra una barra o valor numérico con el nivel actual de afinidad

---

### User Story 2 - Sistema de Afinidad y Estados de Relación (Priority: P1)

La afinidad se acumula por personaje. Al alcanzar ciertos umbrales, la relación cambia de estado (Desconocido → Amigo → Mejor Amigo → Interés Romántico → Enamorado). Cada estado desbloquea nuevas opciones de diálogo y eventos.

**Why this priority**: Sin progresión visible de la relación, las interacciones se sienten planas y sin propósito.

**Independent Test**: Se puede testear seteando manualmente la afinidad a un valor umbral y verificando que el estado de relación cambia y que las nuevas opciones de diálogo aparecen.

**Acceptance Scenarios**:

1. **Scenario**: Afinidad alcanza umbral de cambio de estado
   - **Given** un personaje tiene 90 puntos de afinidad (umbral: 100 para "Interés Romántico")
   - **When** el jugador gana 15 puntos de afinidad en una interacción
   - **Then** el estado cambia a "Interés Romántico" y se notifica al jugador con un mensaje o animación

2. **Scenario**: Opciones de diálogo bloqueadas por estado
   - **Given** el estado de relación con un personaje es "Amigo"
   - **When** el jugador interactúa con el personaje en una escena que tiene opciones de "Interés Romántico"
   - **Then** esas opciones no aparecen o aparecen bloqueadas

3. **Scenario**: Disminución de afinidad
   - **Given** el jugador elige repetidamente opciones negativas con un personaje
   - **When** la afinidad baja del umbral de un estado
   - **Then** el estado de relación retrocede al nivel correspondiente

---

### User Story 3 - Confesión y Establecimiento de Relación de Pareja (Priority: P2)

Al alcanzar el estado "Enamorado" con 100% de afinidad, se desbloquea la opción de "Confesarse". Si el jugador está en modo Harem=false y ya tiene una pareja, o el personaje está casado y Netori=false, la confesión es rechazada.

**Why this priority**: Es el clímax del arco de relación. Define las reglas de exclusividad y las limitaciones del sistema.

**Independent Test**: Se puede testear forzando afinidad máxima en un personaje y verificando las condiciones de aceptación/rechazo según los flags de Harem y Netori.

**Acceptance Scenarios**:

1. **Scenario**: Confesión exitosa sin pareja previa
   - **Given** el jugador tiene afinidad máxima con un personaje soltero, y no tiene pareja actual
   - **When** selecciona la opción "Confesarse"
   - **Then** el personaje acepta, se establece como pareja, y se desbloquean escenas de relación

2. **Scenario**: Confesión rechazada por pareja existente (Harem=false)
   - **Given** Harem=false, el jugador ya tiene una pareja y afinidad máxima con otro personaje
   - **When** intenta confesarse al segundo personaje
   - **Then** el personaje rechaza la confesión mencionando que "ya tienes a alguien"

3. **Scenario**: Confesión aceptada con Harem activado
   - **Given** Harem=true, el jugador ya tiene una pareja y afinidad máxima con otro personaje soltero
   - **When** se confiesa al segundo personaje
   - **Then** el personaje acepta, y los diálogos futuros reflejan la situación de harem

4. **Scenario**: Confesión rechazada por personaje casado (Netori=false)
   - **Given** Netori=false, el personaje objetivo tiene estado civil "casado", afinidad máxima
   - **When** el jugador intenta confesarse
   - **Then** el personaje rechaza indicando su compromiso matrimonial

5. **Scenario**: Confesión aceptada con Netori activado
   - **Given** Netori=true, el personaje objetivo está casado, afinidad máxima
   - **When** el jugador se confiesa
   - **Then** el personaje acepta, los diálogos reflejan la naturaleza de la relación, y el cónyuge puede reaccionar en eventos posteriores

---

### User Story 4 - Configuración de Harem y Netori (Priority: P2)

Al inicio del juego (Nueva Partida), el jugador puede configurar los flags Harem y Netori. Ambos están en "false" por defecto. Una vez iniciada la partida, no pueden cambiarse.

**Why this priority**: Define parámetros fundamentales que afectan toda la experiencia de dating sim. Debe estar implementado antes de que el jugador avance en relaciones.

**Independent Test**: Se puede testear creando una nueva partida, verificando que los flags se guardan correctamente en el save file, y comprobando que las interacciones respetan los valores configurados.

**Acceptance Scenarios**:

1. **Scenario**: Pantalla de configuración al inicio de partida
   - **Given** el jugador inicia una Nueva Partida
   - **When** se muestra la configuración inicial
   - **Then** aparecen toggles para Harem (default: false) y Netori (default: false) con descripciones de cada opción

2. **Scenario**: Flags inmutables durante la partida
   - **Given** el jugador está en mitad de una partida con Harem=false
   - **When** intenta cambiar la configuración desde el menú de opciones
   - **Then** los flags de Harem y Netori no son editables y se muestra un mensaje "Solo disponible al iniciar nueva partida"

3. **Scenario**: Efecto de Harem=true en diálogos
   - **Given** Harem=true y el jugador tiene múltiples parejas
   - **When** ocurre una escena grupal donde hay más de una pareja presente
   - **Then** los diálogos reflejan la dinámica de harem (celos, complicidad, referencias a la situación)

---

### User Story 5 - Eventos de Citas y Escenas Especiales (Priority: P3)

Al alcanzar ciertos estados de relación o puntos de la historia, se desbloquean escenas de cita con el personaje. Estas escenas son eventos únicos que otorgan recompensas (cartas exclusivas, mejoras de afinidad con la criatura del personaje, items).

**Why this priority**: Añade profundidad y recompensa tangible al sistema de relaciones, pero el sistema base de afinidad y confesión funciona sin esto.

**Independent Test**: Se puede testear forzando el trigger de un evento de cita y verificando que la escena se reproduce correctamente y otorga las recompensas esperadas.

**Acceptance Scenarios**:

1. **Scenario**: Invitación a cita al alcanzar umbral de afinidad
   - **Given** el jugador alcanza 50% de afinidad con un personaje
   - **When** ocurre el siguiente descanso o punto de guardado
   - **Then** el personaje invita al jugador a una escena de cita corta

2. **Scenario**: Recompensa tras cita exitosa
   - **Given** el jugador completa una escena de cita
   - **When** la cita termina
   - **Then** el jugador recibe una recompensa (carta exclusiva de la criatura del personaje, item, o bonus de afinidad)

3. **Scenario**: Cita con personaje en modo Netori
   - **Given** Netori=true y el jugador sale con un personaje casado
   - **When** ocurre una escena de cita
   - **Then** la narrativa refleja el riesgo de ser descubiertos y puede tener consecuencias únicas

---

### Edge Cases

- **Afinidad negativa (<0)**: Sí, existe estado de "Enemistad". Sirve como una "deuda" de afinidad que debe saldarse antes de poder generar afinidad positiva.
- **Personaje muere en la historia**: Su afinidad se bloquea permanentemente. No puede subir ni bajar.
- **Personaje romanceable como compañero de equipo**: La afinidad otorga aumentos mínimos en stats (ej. cada nivel de afinidad: +5 de defensa).
- **Interacción entre personajes del harem**: Existen escenas de conflicto, celos y alianzas entre personajes (relaciones poliamorosas complejas, ver FR-013).
- **Netori: cónyuge confronta al jugador**: Sí, el cónyuge puede confrontar al jugador si se entera de la relación.
- **Afinidad baja y ruptura**: Al alcanzar el estado "Enamorado", la afinidad deja de bajar (no hay rupturas una vez consolidada la relación).
- **Reflejo de relación en el overworld**: Interacciones especiales (diálogos, animaciones) y eventos de historia de "relleno" según el estado de relación.
- **Relaciones en NG+ y Modo Roguelike**: En NG+ se reinician todas las relaciones. En modo Roguelike no se ven afectadas (el modo Roguelike se accede desde la historia, no es un modo separado).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sistema DEBE mantener un valor numérico de afinidad (0-100) por cada personaje romanceable, independiente entre personajes.
- **FR-002**: El sistema DEBE definir al menos 5 estados de relación secuenciales (Desconocido, Amigo, Mejor Amigo, Interés Romántico, Enamorado) con umbrales de afinidad configurables.
- **FR-003**: Cada opción de diálogo DEBE tener un modificador de afinidad configurable (positivo, negativo o neutro).
- **FR-004**: El sistema DEBE presentar opciones de diálogo condicionales según el estado de relación actual con el personaje.
- **FR-005**: El sistema DEBE soportar los flags globales Harem (bool, default false) y Netori (bool, default false), configurables SOLO al iniciar nueva partida.
- **FR-006**: Con Harem=false, el sistema DEBE limitar al jugador a UNA (1) pareja activa. Intentos de confesión adicionales DEBEN ser rechazados.
- **FR-007**: Con Netori=false, los personajes con estado civil "Casado" NO DEBEN ser elegibles para confesión/relación de pareja. Con Netori=true, DEBEN ser elegibles.
- **FR-008**: El sistema DEBE reflejar visualmente el estado de relación en la UI del personaje (icono, barra, etiqueta de estado).
- **FR-009**: El sistema DEBE proveer una pantalla o menú donde el jugador pueda consultar el estado de afinidad y relación con todos los personajes conocidos.
- **FR-010**: El sistema DEBE soportar triggers de escenas especiales (citas, eventos) basados en umbrales de afinidad o flags de historia.
- **FR-011**: El sistema DEBE persistir afinidad, estado de relación y pareja(s) actual(es) en el archivo de guardado.
- **FR-012**: Las escenas de cita DEBEN poder otorgar recompensas: cartas, items, o modificadores de afinidad con la criatura del personaje.

- **FR-013**: El sistema DEBE soportar relaciones poliamorosas complejas entre personajes del harem (celos, conflictos, alianzas entre personajes).
- **FR-014**: El sistema DEBE mantener una historia principal con final fijo, independiente de las relaciones de pareja del jugador.

### Key Entities

- **Affinity (Afinidad)**: Valor numérico (0-100) entre el protagonista y un personaje específico. Determina el estado de relación y desbloquea opciones.
- **RelationshipState (Estado de Relación)**: Fase actual de la relación: Desconocido, Amigo, Mejor Amigo, Interés Romántico, Enamorado. Definido por umbrales de afinidad.
- **RomanceableCharacter (Personaje Romanceable)**: Personaje del juego que puede ser sujeto de una relación. Atributos: ID, nombre, estado civil (Soltero/Casado), afinidad actual, estado de relación, pareja actual (ID del protagonista si corresponde).
- **DialogueOption (Opción de Diálogo)**: Opción presentada al jugador durante una interacción. Atributos: texto, modificador de afinidad, estado de relación requerido, flags requeridos.
- **RomanceConfig (Configuración de Romance)**: Flags globales de la partida: Harem (bool), Netori (bool). Inmutables tras inicio de partida.
- **Couple (Pareja)**: Vínculo establecido entre el protagonista y un personaje. En modo Harem=true, pueden existir múltiples parejas simultáneas.
- **DateEvent (Evento de Cita)**: Escena especial desbloqueada por afinidad o historia. Atributos: personaje asociado, umbral requerido, recompensas, diálogos únicos.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El jugador puede alcanzar el estado "Enamorado" con un personaje en aproximadamente 5-8 interacciones significativas (no instantáneo ni excesivamente lento).
- **SC-002**: Las opciones de diálogo condicionales al estado de relación funcionan correctamente en el 100% de las escenas verificadas.
- **SC-003**: El sistema de confesión respeta correctamente los 4 escenarios posibles (Harem ON/OFF × Netori ON/OFF × personaje casado/soltero) en el 100% de los casos de prueba.
- **SC-004**: El 80% de playtesters reporta que el sistema de afinidad es "claro y comprensible" sin necesidad de tutorial externo.
- **SC-005**: La UI de estado de relaciones carga y actualiza en menos de 100ms con hasta 20 personajes romanceables registrados.
- **SC-006**: El estado completo de relaciones se guarda y restaura correctamente tras cerrar y reabrir la aplicación en el 100% de los casos de prueba.
- **SC-007**: Al menos 3 personajes tienen arcos de relación completos (conocido → enamorado) con diálogos únicos por cada estado.
