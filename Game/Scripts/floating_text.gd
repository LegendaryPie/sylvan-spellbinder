extends Node2D

var velocity = Vector2.UP * 100
var fade_time = 1.0
var elapsed = 0.0
var initial_scale = Vector2(1, 1)
var final_scale = Vector2(1.5, 1.5)

func _ready():
	# Start with a small pop effect
	scale = Vector2(0.5, 0.5)
	create_tween().tween_property(self, "scale", initial_scale, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _process(delta):
	position += velocity * delta
	elapsed += delta
	
	if elapsed >= fade_time:
		queue_free()
	else:
		modulate.a = 1.0 - (elapsed / fade_time)
		scale = initial_scale.lerp(final_scale, elapsed / fade_time)

func display(text: String, color: Color = Color.WHITE):
	$Label.text = text
	$Label.add_theme_color_override("font_color", color)
