extends Control

@onready var title_label = $Panel/VBoxContainer/Title
@onready var description_label = $Panel/VBoxContainer/Description

func _ready():
	visible = false

func setTitle(title: String):
	if title_label:
		title_label.text = title

func setDescription(description: String):
	if description_label:
		description_label.text = description

func show_modal():
	visible = true

func hide_modal():
	visible = false
