# res://scripts/Main.gd
extends Node2D

func _ready():
	await create_rail()
	await create_tank()
	await create_tower()
	
func create_tower():
	var tower_scene = preload("res://scenes/tower/tower.tscn")
	var tower_instance = tower_scene.instantiate()
	
	var screen_center = get_viewport_rect().size / 2
	tower_instance.position = screen_center
	tower_instance.position.x += 350 
	tower_instance.position.y = tower_instance.position.y * 2 - 30
	
	add_child(tower_instance)
	
func create_tank():
	var tank_scene = preload("res://scenes/tank/tank.tscn")
	var tank_instance = tank_scene.instantiate()
	
	var screen_center = get_viewport_rect().size / 2
	tank_instance.position = screen_center
	tank_instance.position.y = 0
	
	add_child(tank_instance)

func create_rail():
	var rail_scene = preload("res://scenes/rail/rail.tscn")
	var rail_instance = rail_scene.instantiate()
	
	var screen_center = get_viewport_rect().size / 2
	rail_instance.position = screen_center 

	add_child(rail_instance)
