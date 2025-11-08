extends CanvasLayer
# Heads-up display

@onready var health_bar = $Panel/HealthBar
@onready var lives_label = $Panel/LivesLabel
@onready var currency_label = $Panel/CurrencyLabel
@onready var ammo_label = $Panel/AmmoLabel
@onready var stage_label = $Panel/StageLabel

func _ready():
	# Connect to GameState signals
	GameState.lives_changed.connect(_on_lives_changed)
	GameState.currency_changed.connect(_on_currency_changed)

	update_hud()

func update_hud():
	lives_label.text = "Lives: " + str(GameState.lives)
	currency_label.text = str(GameState.sky_crowns) + " SC"
	stage_label.text = "Stage " + str(GameState.current_stage)

func update_health(current: float, maximum: float):
	if health_bar:
		health_bar.value = (current / maximum) * 100.0

func update_ammo(count: int):
	if ammo_label:
		ammo_label.text = "Arrows: " + str(count)

func _on_lives_changed(new_lives: int):
	lives_label.text = "Lives: " + str(new_lives)

func _on_currency_changed(new_amount: int):
	currency_label.text = str(new_amount) + " SC"

func show_shaman_wisdom():
	var wisdom = get_current_shaman_wisdom()
	$ShamanPanel.visible = true
	$ShamanPanel/WisdomLabel.text = wisdom

	# Auto-hide after 5 seconds
	await get_tree().create_timer(5.0).timeout
	$ShamanPanel.visible = false

func get_current_shaman_wisdom() -> String:
	var mission = MissionLoader.current_mission
	return mission.get("guidance", {}).get("shamanWisdom", "Trust your instincts.")
