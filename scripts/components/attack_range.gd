extends Area2D

var markers := {}

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body == get_parent():
		return
	if body is CharacterBody2D and not markers.has(body):
		var marker := RedCircleMarker.new()
		body.add_child(marker)
		markers[body] = marker

func _on_body_exited(body: Node2D):
	if markers.has(body):
		var marker = markers[body]
		if is_instance_valid(marker):
			marker.queue_free()
		markers.erase(body)
