extends CanvasLayer

@onready var health_bar : TextureProgressBar = $HealthBar

func _ready():
	Globals.connect("stat_changed", update_stats)
	update_stats()


func update_stats():
	health_bar.value = Globals.health
