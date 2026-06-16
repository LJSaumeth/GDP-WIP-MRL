@tool
extends EditorPlugin

const RenameDialog = preload("res://addons/gdscript_refactoring/qb_rename_dialog.gd")
const LspClient    = preload("res://addons/gdscript_refactoring/qb_lsp_client.gd")

var _dialog: AcceptDialog
var _context_menu_handler: Node


func _enter_tree() -> void:
	_dialog = RenameDialog.new()
	_dialog.editor_plugin = self
	_dialog.hide()
	get_editor_interface().get_base_control().add_child(_dialog)

	_context_menu_handler = ContextMenuHandler.new()
	_context_menu_handler.plugin = self
	add_child(_context_menu_handler)
	_context_menu_handler.watch_script_editor(
		get_editor_interface().get_script_editor()
	)


func _exit_tree() -> void:
	if is_instance_valid(_context_menu_handler):
		_context_menu_handler.cleanup()
		_context_menu_handler.queue_free()
	_context_menu_handler = null
	if is_instance_valid(_dialog):
		_dialog.queue_free()
	_dialog = null


func get_active_code_edit() -> CodeEdit:
	var se := get_editor_interface().get_script_editor()
	var base := se.get_current_editor()
	if base == null:
		return null
	return _find_code_edit(base)


func _find_code_edit(node: Node) -> CodeEdit:
	if node is CodeEdit:
		return node as CodeEdit
	for child in node.get_children():
		var result := _find_code_edit(child)
		if result:
			return result
	return null


func open_rename_dialog(symbol: String, symbol_pos: Dictionary) -> void:
	_dialog.open(symbol, symbol_pos)


# -------------------------------------------------------------------------
# Plugin-level undo/redo for multi-file renames.
# Ctrl+Z inside the script editor only triggers the CodeEdit's local undo,
# so the plugin intercepts the shortcut when the local history is empty
# and applies its own multi-file revert.
# -------------------------------------------------------------------------

var _undo_stack: Array[Dictionary] = []  # [{abs_path: {old, new}}]
var _redo_stack: Array[Dictionary] = []


func push_rename_action(files: Dictionary) -> void:
	_undo_stack.append(files)
	_redo_stack.clear()
	# Clear local undo history of affected open CodeEdits after the silent
	# reload completes, so a later Ctrl+Z reaches our multi-file undo instead
	# of reverting the buffer locally (which would desync buffer and disk).
	_clear_affected_histories_later(files.keys())


func perform_undo() -> bool:
	if _undo_stack.is_empty():
		return false
	var files: Dictionary = _undo_stack.pop_back()
	_redo_stack.append(files)
	for abs_path in files:
		_dialog._write_and_refresh(abs_path, files[abs_path]["old"])
	_clear_affected_histories_later(files.keys())
	return true


func perform_redo() -> bool:
	if _redo_stack.is_empty():
		return false
	var files: Dictionary = _redo_stack.pop_back()
	_undo_stack.append(files)
	for abs_path in files:
		_dialog._write_and_refresh(abs_path, files[abs_path]["new"])
	_clear_affected_histories_later(files.keys())
	return true


## Clears the local undo history of every open CodeEdit whose file was
## just rewritten. Runs several passes because the silent reload happens
## asynchronously and itself pushes a new entry into the buffer history.
func _clear_affected_histories_later(paths: Array) -> void:
	for delay in [0.3, 0.8, 1.5]:
		await get_tree().create_timer(delay).timeout
		_clear_histories_now(paths)


func _clear_histories_now(paths: Array) -> void:
	var se := get_editor_interface().get_script_editor()
	var open_scripts := se.get_open_scripts()
	var open_editors := se.get_open_script_editors()  # aligned with open_scripts
	for abs_path in paths:
		var res_path := ProjectSettings.localize_path(abs_path)
		for i in open_scripts.size():
			if open_scripts[i] == null or open_scripts[i].resource_path != res_path:
				continue
			if i >= open_editors.size():
				break
			var ce = open_editors[i].get_base_editor()
			if ce is CodeEdit:
				(ce as CodeEdit).clear_undo_history()
				(ce as CodeEdit).tag_saved_version()
			break


func get_word_under_cursor(code_edit: CodeEdit) -> String:
	var line_idx := code_edit.get_caret_line()
	var col_idx  := code_edit.get_caret_column()
	var line     := code_edit.get_line(line_idx)
	if line.is_empty():
		return ""
	var start := col_idx
	while start > 0 and _is_word_char(line[start - 1]):
		start -= 1
	var end := col_idx
	while end < line.length() and _is_word_char(line[end]):
		end += 1
	return line.substr(start, end - start)


func _is_word_char(c: String) -> bool:
	return c.length() == 1 and (c == "_" or c.to_upper() != c.to_lower() or c.is_valid_int())


# -------------------------------------------------------------------------
# Renameable-symbol detection
# -------------------------------------------------------------------------

## GDScript reserved keywords — cannot be renamed.
const GDSCRIPT_KEYWORDS := [
	# Declarations
	"var", "const", "func", "class", "class_name", "extends", "signal", "enum",
	"static",
	# Control flow
	"if", "elif", "else", "for", "while", "match", "when", "break", "continue",
	"pass", "return",
	# Operators / logic
	"and", "or", "not", "in", "is", "as",
	# Literals / constants
	"true", "false", "null", "self", "super",
	# Misc
	"await", "breakpoint", "tool", "void",
	# Built-in primitive type names
	"bool", "int", "float", "String", "StringName", "NodePath",
	"Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i",
	"Rect2", "Rect2i", "Transform2D", "Transform3D", "Plane", "Quaternion",
	"AABB", "Basis", "Projection", "Color", "RID", "Callable", "Signal",
	"Dictionary", "Array", "PackedByteArray", "PackedInt32Array",
	"PackedInt64Array", "PackedFloat32Array", "PackedFloat64Array",
	"PackedStringArray", "PackedVector2Array", "PackedVector3Array",
	"PackedColorArray", "Variant",
	# Annotations are caught by '@' check, but the bare words too
	"export", "onready", "tool", "icon", "rpc",
	# Global functions that look like identifiers
	"print", "push_error", "push_warning", "assert", "preload", "load",
	"range", "len", "abs", "min", "max", "clamp", "lerp",
]


## Returns true if the symbol under the cursor can be renamed:
## - a valid identifier
## - not a GDScript keyword or built-in type
## - not a native engine class (Node, Sprite2D, …)
## - not a number literal
## - not inside a string literal or comment
func is_renameable_symbol(code_edit: CodeEdit, symbol: String) -> bool:
	if symbol.is_empty():
		return false

	# Must be a valid identifier (starts with letter or _)
	var first := symbol[0]
	if not (first == "_" or first.to_upper() != first.to_lower()):
		return false  # starts with a digit → numeric literal

	# Reserved keyword or built-in type?
	if symbol in GDSCRIPT_KEYWORDS:
		return false

	# Native engine class (Node, Sprite2D, RefCounted, …)?
	if ClassDB.class_exists(symbol):
		return false

	# Inside a string literal or comment? → not code, not renameable
	if _cursor_in_string_or_comment(code_edit):
		return false

	return true


## Scans the current line up to the caret to check whether the caret sits
## inside a string literal or after a comment marker.
func _cursor_in_string_or_comment(code_edit: CodeEdit) -> bool:
	var line := code_edit.get_line(code_edit.get_caret_line())
	var col  := code_edit.get_caret_column()
	var in_single := false
	var in_double := false
	var i := 0
	while i < col and i < line.length():
		var c := line[i]
		if c == "\\" and (in_single or in_double):
			i += 2
			continue
		if c == "'" and not in_double:
			in_single = not in_single
		elif c == '"' and not in_single:
			in_double = not in_double
		elif c == "#" and not in_single and not in_double:
			return true  # caret is after a comment marker
		i += 1
	return in_single or in_double


# =============================================================================
class ContextMenuHandler extends Node:
	var plugin
	var _hooked_popup: PopupMenu  = null
	var _hooked_code_edits: Array = []
	var _hooked_code_edit: CodeEdit = null


	func watch_script_editor(se: ScriptEditor) -> void:
		if not se.editor_script_changed.is_connected(_on_script_changed):
			se.editor_script_changed.connect(_on_script_changed)
		_hook_current_editor()


	func cleanup() -> void:
		_hooked_popup = null
		_hooked_code_edits.clear()


	func _on_script_changed(_script) -> void:
		_hook_current_editor()


	func _hook_current_editor() -> void:
		await get_tree().process_frame
		var code_edit: CodeEdit = plugin.get_active_code_edit()
		if code_edit == null or code_edit in _hooked_code_edits:
			return
		_hooked_code_edits.append(code_edit)
		var erase_cb := _hooked_code_edits.erase.bind(code_edit)
		if not code_edit.tree_exited.is_connected(erase_cb):
			code_edit.tree_exited.connect(erase_cb, CONNECT_ONE_SHOT)
		var input_cb := _on_code_edit_gui_input.bind(code_edit)
		if not code_edit.gui_input.is_connected(input_cb):
			code_edit.gui_input.connect(input_cb)


	func _on_code_edit_gui_input(event: InputEvent, code_edit: CodeEdit) -> void:
		# Right-click → context menu injection
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
				call_deferred("_inject_menu_items", code_edit)
			return

		if not (event is InputEventKey):
			return
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return

		# Shift+F2 → open Rename dialog (standard IDE rename shortcut,
		# no conflict with Godot's built-in shortcuts)
		if key.keycode == KEY_F2 and key.shift_pressed \
				and not key.ctrl_pressed and not key.alt_pressed:
			var symbol: String = plugin.get_word_under_cursor(code_edit)
			if plugin.is_renameable_symbol(code_edit, symbol):
				var se := EditorInterface.get_script_editor()
				var current_script := se.get_current_script()
				var symbol_pos := {}
				if current_script:
					var abs_path := ProjectSettings.globalize_path(current_script.resource_path)
					symbol_pos = {
						"uri":       LspClient.path_to_uri(abs_path),
						"line":      code_edit.get_caret_line(),
						"character": code_edit.get_caret_column()
					}
				plugin.open_rename_dialog(symbol, symbol_pos)
				code_edit.accept_event()
			return

		# Ctrl+Z / Ctrl+Shift+Z / Ctrl+Y → multi-file undo/redo when the
		# CodeEdit's own history is exhausted
		if not key.ctrl_pressed:
			return
		if key.keycode == KEY_Z and not key.shift_pressed:
			if not code_edit.has_undo() and plugin.perform_undo():
				code_edit.accept_event()
		elif (key.keycode == KEY_Z and key.shift_pressed) or key.keycode == KEY_Y:
			if not code_edit.has_redo() and plugin.perform_redo():
				code_edit.accept_event()


	func _inject_menu_items(code_edit: CodeEdit) -> void:
		var popup := _find_context_popup(code_edit)
		if popup == null:
			return
		_hooked_popup = popup
		_hooked_code_edit = code_edit
		# Connect once per popup; bound Callables differ each call so we must
		# guard with is_connected on the SAME stored callable.
		if not popup.about_to_popup.is_connected(_on_popup_about_to_show):
			popup.about_to_popup.connect(_on_popup_about_to_show)
		if not popup.id_pressed.is_connected(_on_menu_id_pressed):
			popup.id_pressed.connect(_on_menu_id_pressed)
		_add_rename_item(popup, code_edit)


	func _on_popup_about_to_show() -> void:
		if _hooked_popup and _hooked_code_edit:
			call_deferred("_add_rename_item", _hooked_popup, _hooked_code_edit)


	func _add_rename_item(popup: PopupMenu, code_edit: CodeEdit) -> void:
		for i in range(popup.item_count):
			if popup.get_item_id(i) == 9900:
				return
		var symbol: String = plugin.get_word_under_cursor(code_edit)
		# Only show "Rename..." when the symbol is actually renameable
		if not plugin.is_renameable_symbol(code_edit, symbol):
			return
		popup.add_separator("GDScript Refactoring")
		var idx := popup.item_count
		popup.add_item("Rename...", 9900)
		popup.set_item_metadata(idx, symbol)
		# Show the keyboard shortcut next to the menu label
		var shortcut := Shortcut.new()
		var key_event := InputEventKey.new()
		key_event.keycode      = KEY_F2
		key_event.shift_pressed = true
		shortcut.events        = [key_event]
		popup.set_item_shortcut(idx, shortcut, false)  # false = show shortcut in menu


	func _on_menu_id_pressed(id: int) -> void:
		if id != 9900 or _hooked_popup == null:
			return
		var code_edit := _hooked_code_edit
		if code_edit == null:
			return
		var item_idx := _hooked_popup.get_item_index(9900)
		if item_idx == -1:
			return
		var symbol: String = _hooked_popup.get_item_metadata(item_idx)

		# Build the LSP position from the current caret
		var se := EditorInterface.get_script_editor()
		var current_script := se.get_current_script()
		var symbol_pos := {}
		if current_script:
			var abs_path := ProjectSettings.globalize_path(current_script.resource_path)
			symbol_pos = {
				"uri":       LspClient.path_to_uri(abs_path),
				"line":      code_edit.get_caret_line(),
				"character": code_edit.get_caret_column()
			}

		plugin.open_rename_dialog(symbol, symbol_pos)


	func _find_context_popup(code_edit: CodeEdit) -> PopupMenu:
		for child in code_edit.get_children():
			if child is PopupMenu:
				return child as PopupMenu
		return _find_visible_popup(plugin.get_tree().root)


	func _find_visible_popup(node: Node) -> PopupMenu:
		if node is PopupMenu and (node as PopupMenu).visible:
			return node as PopupMenu
		for child in node.get_children():
			var result := _find_visible_popup(child)
			if result:
				return result
		return null
