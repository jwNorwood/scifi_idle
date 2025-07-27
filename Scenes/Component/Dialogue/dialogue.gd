extends Control

@onready var panel: Panel = $Panel
@onready var rich_text_label: RichTextLabel = $Panel/RichTextLabel

# Dialogue state
var current_messages: Array[String] = []
var current_message_index: int = 0
var is_showing: bool = false
var auto_advance_timer: Timer

# Typing effect
var typing_speed: float = 0.03  # Seconds per character
var current_text: String = ""
var target_text: String = ""
var target_text_clean: String = ""  # Text without BBCode tags
var typing_tween: Tween

signal dialogue_finished
signal message_finished

func _ready():
	# Hide dialogue initially
	visible = false
	
	# Set up auto advance timer
	auto_advance_timer = Timer.new()
	auto_advance_timer.wait_time = 2.0  # Auto advance after 2 seconds
	auto_advance_timer.one_shot = true
	auto_advance_timer.timeout.connect(_auto_advance)
	add_child(auto_advance_timer)
	
	# Set up input handling
	set_process_input(true)

func _input(event):
	if not is_showing:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_advance_message()
		elif event.keycode == KEY_ESCAPE:
			_skip_dialogue()
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_advance_message()

func show_message(text: String, duration: float = 2.0):
	"""Show a single message"""
	var messages: Array[String] = [text]
	show_messages(messages, duration)

func show_messages(messages: Array[String], auto_advance_duration: float = 2.0):
	"""Show a sequence of messages"""
	if messages.is_empty():
		print("Warning: No messages to display")
		return
	
	print("Showing dialogue with ", messages.size(), " messages")
	print("Dialogue node visible: ", visible)
	print("Dialogue global position: ", global_position)
	print("Dialogue size: ", size)
	
	current_messages = messages
	current_message_index = 0
	is_showing = true
	auto_advance_timer.wait_time = auto_advance_duration
	
	visible = true
	print("Dialogue set to visible, now visible: ", visible)
	_display_current_message()

func _display_current_message():
	"""Display the current message with typing effect"""
	if current_message_index >= current_messages.size():
		_finish_dialogue()
		return
	
	target_text = current_messages[current_message_index]
	
	# Stop any existing typing tween
	if typing_tween:
		typing_tween.kill()
	
	# Check if message contains BBCode tags
	if target_text.find("[") != -1 and target_text.find("]") != -1:
		# For BBCode messages, show instantly with fade-in to avoid tag display issues
		rich_text_label.modulate.a = 0.0
		rich_text_label.text = target_text
		
		typing_tween = create_tween()
		typing_tween.tween_property(rich_text_label, "modulate:a", 1.0, 0.5)
		typing_tween.finished.connect(_on_typing_finished)
	else:
		# For plain text, use character-by-character typing
		target_text_clean = target_text
		current_text = ""
		rich_text_label.text = ""
		rich_text_label.modulate.a = 1.0
		
		typing_tween = create_tween()
		typing_tween.tween_method(_update_typing_text, 0.0, 1.0, target_text.length() * typing_speed)
		typing_tween.finished.connect(_on_typing_finished)

func _update_typing_text(progress: float):
	"""Update text during typing effect (for plain text only)"""
	var char_count = int(target_text.length() * progress)
	current_text = target_text.substr(0, char_count)
	rich_text_label.text = current_text

func _on_typing_finished():
	"""Called when typing effect finishes"""
	# Ensure text is fully visible and properly set
	rich_text_label.modulate.a = 1.0
	rich_text_label.text = target_text
	
	# Add instruction text for continuing
	if current_message_index < current_messages.size() - 1:
		rich_text_label.text += "\n[right][color=gray][i](Press SPACE or click to continue)[/i][/color][/right]"
	else:
		rich_text_label.text += "\n[right][color=gray][i](Press SPACE or click to close)[/i][/color][/right]"
	
	message_finished.emit()
	
	# Start auto advance timer if this isn't the last message
	if current_message_index < current_messages.size() - 1:
		auto_advance_timer.start()

func _advance_message():
	"""Advance to next message or finish dialogue"""
	# If still typing, complete current message immediately
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
		rich_text_label.modulate.a = 1.0
		rich_text_label.text = target_text
		_on_typing_finished()
		return
	
	# Stop auto advance timer
	auto_advance_timer.stop()
	
	# Move to next message
	current_message_index += 1
	_display_current_message()

func _auto_advance():
	"""Auto advance to next message"""
	_advance_message()

func _skip_dialogue():
	"""Skip entire dialogue sequence"""
	auto_advance_timer.stop()
	if typing_tween:
		typing_tween.kill()
	_finish_dialogue()

func _finish_dialogue():
	"""Finish and hide dialogue"""
	is_showing = false
	visible = false
	current_messages.clear()
	current_message_index = 0
	dialogue_finished.emit()

func hide_dialogue():
	"""Manually hide dialogue"""
	_finish_dialogue()
