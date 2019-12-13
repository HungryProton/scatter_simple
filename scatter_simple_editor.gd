tool
extends EditorPlugin
"""
Plugin starting point.
Defines what happens when the plugin is enabled or disabled. Here we simply register a new node
type so it's available from the 'Add child node' menu.
"""


func _enter_tree() -> void:
	add_custom_type(
			"ScatterSimple",
			"Spatial",
			load("res://addons/scatter_simple/scatter_simple.gd"),
			load("res://addons/scatter_simple/icon.svg")
	)


func _exit_tree() -> void:
	remove_custom_type("ScatterSimple")
