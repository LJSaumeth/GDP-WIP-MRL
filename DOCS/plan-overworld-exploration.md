# Implementation Plan: Exploración / Overworld 2D-HD

**Date**: 2026-06-12
**Spec**: `DOCS/spec-overworld-exploration.md`

## Summary

Implementar el sistema de exploración en estilo 2D-HD: personajes 2D (sprites) en entornos 3D con cámara semi-fija, movimiento en 8 direcciones, interacción con NPCs y objetos, transiciones entre zonas con fade, ciclo día/noche, encuentros aleatorios en zonas hostiles, y vehículos desbloqueables (patines → bicicleta → motocicleta).

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Godot 3D nodes (MeshInstance3D), Sprite3D para personajes, AnimationPlayer
**Storage**: Estado de overworld en memoria durante la sesión, posición del jugador persistida en save
**Testing**: Test scenes in-editor
**Target Platform**: Windows D3D12
**Performance Goals**: 60fps estables, carga de zona <2s, depth-sorting correcto en todo momento
**Constraints**: Sprites 2D con billboarding automático, iluminación 3D afectando sprites
**Scale/Scope**: ~15 zonas (pueblos, rutas, interiores, mazmorras), ~30 NPCs, ciclo día/noche completo

## Project Structure

### Source Code (within `wip/`)

```text
src/overworld/
├── zones/                          # Escenas de zonas del overworld
│   ├── test_zone.tscn              # Zona de prueba con todos los features
│   ├── town_template.tscn          # Template para pueblos
│   └── route_template.tscn         # Template para rutas
├── player/
│   ├── overworld_player.gd         # Control del personaje: input, movimiento 8-dir, animaciones
│   ├── overworld_player.tscn       # Escena del jugador (Sprite3D + collider)
│   └── player_state.gd            # Estado persistente: zona, posición, vehículo
├── camera/
│   ├── hd2d_camera.gd             # Cámara 2D-HD: ángulo fijo, billboarding, depth-sorting
│   └── camera_zone_config.gd      # Config de cámara por zona (ángulo, altura, FOV)
├── interaction/
│   ├── interactable.gd            # Clase base para objetos/NPCs interactuables
│   ├── interaction_detector.gd    # Detecta interactuables en rango, prioridad por cercanía
│   ├── interaction_prompt.gd      # Indicador visual (ícono flotante sobre interactuable)
│   └── npc_overworld.gd          # NPC con sprite, diálogos, patrulla opcional
├── zones/
│   ├── zone_manager.gd            # Singleton: carga/descarga zonas, fade transitions
│   ├── transition_trigger.gd      # Trigger de transición entre zonas (Area3D)
│   ├── zone_data.gd               # Resource: datos de zona (ID, tipo, segura/hostil, BGM)
│   └── zone_spawn_point.gd       # Punto de spawn del jugador al entrar a zona
├── encounters/
│   ├── encounter_system.gd        # Gestión de encuentros aleatorios (contador de pasos)
│   ├── encounter_trigger.gd       # Trigger de encuentro fijo (historia)
│   ├── encounter_transition.gd    # Efecto de transición a combate (swipe, destello)
│   └── repell_manager.gd         # Lógica del repulsor (desactiva encuentros aleatorios)
├── time/
│   ├── day_night_cycle.gd         # Singleton: ciclo día/noche (reloj interno)
│   ├── time_based_lighting.gd     # Ajusta luces 3D según hora del día
│   └── time_affects.gd            # Efectos: visibilidad, encuentros, NPCs con horario
├── vehicles/
│   ├── vehicle_base.gd            # Clase base para vehículos (velocidad, animación, desbloqueo)
│   └── vehicle_data.gd            # Resource: roller_blades, bicycle, motorcycle
└── ui/
    ├── overworld_hud.gd           # HUD mínimo: minimapa, hora del día, vehículo actual
    └── zone_name_display.gd      # Muestra nombre de zona al entrar (fade in/out)
```

## Phases

### Phase 1: Movimiento del Personaje (Fundacional)

**Purpose**: El jugador puede moverse en un entorno 3D con sprite 2D.

- [ ] T001 Crear `overworld_player.tscn` — Sprite3D + CollisionShape3D (capsule) + AnimationPlayer. Spritesheet con 4 u 8 direcciones (idle + walk + run)
- [ ] T002 Crear `overworld_player.gd` — Input handling: WASD/joystick → Vector3 movimiento, 8 direcciones, dos velocidades (walk/run con Shift), orientación del sprite hacia la dirección de movimiento
- [ ] T003 Implementar animaciones: idle (quieto), walk (caminar), run (correr) con blend tree
- [ ] T004 Detección de colisiones con el entorno 3D (paredes, obstáculos) usando PhysicsBody3D + CharacterBody3D
- [ ] T005 Crear escena de prueba: terreno 3D simple (plano + cubos como obstáculos), spawnear jugador, testear movimiento

### Phase 2: Cámara 2D-HD

**Purpose**: Configurar cámara con perspectiva fija que emule 2D-HD.

- [ ] T006 Crear `hd2d_camera.gd` — Camera3D hija del jugador con offset fijo. Ángulo: ~45°俯角, posición detrás y arriba. Suavizado opcional (lerp)
- [ ] T007 Implementar billboarding en sprites: `sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED` para que siempre enfrenten a la cámara
- [ ] T008 Implementar depth-sorting por Y: sprites con Y menor (más lejos en perspectiva) se renderizan primero. Usar `Material3D` con `render_priority` o `y_sort_enabled` en Node3D padre
- [ ] T009 Crear `camera_zone_config.gd` — Resource con parámetros de cámara por zona: ángulo, altura, distancia, FOV, suavizado
- [ ] T010 Ajustar iluminación: DirectionalLight3D principal que afecta tanto al entorno 3D como a los sprites (modular el color del sprite según luz recibida)

### Phase 3: Interacción con NPCs y Objetos

**Purpose**: Sistema de interacción con entidades del overworld.

- [ ] T011 Crear `interactable.gd` — Clase base (Node3D) con: tipo (NPC/cofre/puerta/señal/item), `interaction_range` (float), señal `interacted`, método virtual `on_interact()`
- [ ] T012 Crear `interaction_detector.gd` — Area3D hijo del jugador. Detecta interactuables en rango, mantiene lista ordenada por distancia. Señal `closest_interactable_changed(interactable)`
- [ ] T013 Implementar prioridad por cercanía: si múltiples interactuables en rango, el más cercano tiene prioridad
- [ ] T014 Crear `interaction_prompt.gd` — Sprite3D o Label3D que aparece sobre el interactuable más cercano (ícono ❗ o similar), sigue al interactuable si se mueve
- [ ] T015 Input de interacción: tecla E / botón A → llama `on_interact()` del interactuable más cercano
- [ ] T016 Crear `npc_overworld.gd` — Extiende Interactable. Atributos: diálogos (DialogueData del addon sprouty_dialogs), patrulla (array de waypoints, velocidad), horario (si día/noche activo)

### Phase 4: Zonas y Transiciones

**Purpose**: Sistema de zonas independientes con transiciones suaves.

- [ ] T017 Crear `zone_data.gd` — Resource: zone_id, display_name, type (town/route/dungeon/interior), is_safe_zone, camera_config, bgm_path, encounter_pool
- [ ] T018 Crear `transition_trigger.gd` — Area3D con: zona_destino (zone_id), punto_entrada_destino (string), dirección. Al entrar jugador → fade out → carga zona destino → fade in → spawn en punto entrada
- [ ] T019 Crear `zone_spawn_point.gd` — Node3D marcador con nombre (string ID). El jugador aparece aquí al entrar a la zona
- [ ] T020 Crear `zone_manager.gd` — Autoload. Métodos: `transition_to(zone_id, spawn_point_id)`, `get_current_zone()`. Maneja:
  - Fade out (ColorRect negro, 0.5s)
  - `SceneManager.change_scene_to_file(zone_path)` (o `ResourceLoader.load` asíncrono)
  - Fade in (0.5s)
  - Bloquea input durante transición
- [ ] T021 Guardar/restaurar posición del jugador al volver a zona previamente visitada (persistencia de estado de zona)

### Phase 5: Encuentros

**Purpose**: Sistema de encuentros que conecta overworld con combate.

- [ ] T022 Crear `encounter_system.gd` — Contador de pasos invisible. Cada paso en zona hostil incrementa contador. Al alcanzar umbral aleatorio (configurable por zona) → trigger encuentro
- [ ] T023 Definir pools de encuentros por zona: `encounter_pools.json` con `zone_id → [enemy_trainer_ids]` y pesos (probabilidad)
- [ ] T024 Crear `encounter_transition.gd` — Efecto visual al iniciar combate: wipe, destello, transición personalizada. Carga `battle_scene.tscn` pasando datos del encuentro
- [ ] T025 Crear `encounter_trigger.gd` — Trigger de encuentro fijo (historia). Area3D que al entrar inicia combate con entrenador/enemigos predefinidos (sin aleatoriedad)
- [ ] T026 Crear `repell_manager.gd` — Estado de repulsor: activo/inactivo, contador de pasos restantes. Cuando activo, `encounter_system` no incrementa contador

### Phase 6: Ciclo Día/Noche

**Purpose**: Reloj interno que afecta iluminación y visibilidad.

- [ ] T027 Crear `day_night_cycle.gd` — Autoload. Reloj interno (0.0 a 24.0 horas), velocidad configurable (ej. 1h real = 24h juego). Señales: `time_changed(hour)`, `sunrise`, `sunset`, `nightfall`
- [ ] T028 Implementar `time_based_lighting.gd` — Ajusta DirectionalLight3D: rotación del sol, color (blanco→naranja→negro), intensidad, luz ambiental según hora
- [ ] T029 Implementar `time_affects.gd` — Visibilidad reducida de noche, encuentros más frecuentes de noche en ciertas zonas, NPCs con horario (solo aparecen a ciertas horas)
- [ ] T030 Actualizar NPCs para soportar horarios: `npc_overworld.gd` con `active_hours` (rango), visibilidad condicional

### Phase 7: Vehículos

**Purpose**: Vehículos desbloqueables para viaje rápido.

- [ ] T031 Crear `vehicle_data.gd` — Resource: vehicle_id, nombre, speed_multiplier, sprite_override (opcional), unlock_flag
- [ ] T032 Crear `vehicle_base.gd` — Lógica: al activar vehículo, cambia velocidad del jugador, opcionalmente cambia sprite (montado en bici/moto)
- [ ] T033 Implementar progresión: roller_blades (×1.3 speed) → bicycle (×1.6) → motorcycle (×2.0). Desbloqueo por flags de historia
- [ ] T034 Restricción: vehículos solo en zonas exteriores (rutas, no interiores ni pueblos densos)

### Phase 8: UI Overworld

**Purpose**: HUD mínimo durante exploración.

- [ ] T035 Crear `overworld_hud.gd` — Reloj (hora del día), indicador de vehículo activo, minimapa simple (opcional)
- [ ] T036 Crear `zone_name_display.gd` — Label animado al entrar a zona: fade in nombre → espera 2s → fade out
- [ ] T037 Integrar menú de pausa: acceso a equipo, criaturas, inventario, guardar

### Phase 9: Integración con Otros Sistemas

**Purpose**: Conectar overworld con dating sim, progresión y combate.

- [ ] T038 Puntos de acceso a Roguelike: `interactable` especial en overworld que transiciona al mapa de la Liga (`map_scene.tscn`)
- [ ] T039 NPCs romanceables: integrar con sistema de afinidad (mostrar indicador de relación en interaction prompt)
- [ ] T040 Transición overworld ↔ combate: guardar estado overworld antes de combate, restaurar al terminar (posición, zona)

## Dependencies

- **Depende de**: `addons/sprouty_dialogs` (sistema de diálogos para NPCs)
- **Bloquea**: `plan-dating-sim.md` (los personajes romanceables existen como NPCs en el overworld)
- **Relación con**: `plan-gameplay-deckbuilder.md` (transiciones a combate), `plan-meta-progression.md` (puntos de acceso a Roguelike)
