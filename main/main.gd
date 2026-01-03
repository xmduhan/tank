# res://scripts/Main.gd
extends Node2D

func _ready():
	await create_rail()

func create_rail():
	var rail_scene = preload("res://scenes/rail/rail.tscn")
	var rail_instance = rail_scene.instantiate()
	
	var screen_center = get_viewport_rect().size / 2
	rail_instance.position = screen_center 
	
	
	add_child(rail_instance)
