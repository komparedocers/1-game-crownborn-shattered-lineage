extends Control
# In-game shop

@onready var catalog_container = $Panel/ScrollContainer/CatalogContainer
@onready var balance_label = $Panel/BalanceLabel

var catalog_items: Array = []

func _ready():
	visible = false
	load_catalog()

func load_catalog():
	var result = await NetClient.get_shop_catalog()

	if result.success:
		catalog_items = result.data
		display_catalog()

func display_catalog():
	# Clear existing items
	for child in catalog_container.get_children():
		child.queue_free()

	# Create shop item cards
	for item in catalog_items:
		var item_card = create_item_card(item)
		catalog_container.add_child(item_card)

	# Update balance
	balance_label.text = str(GameState.sky_crowns) + " SC"

func create_item_card(item: Dictionary) -> Control:
	var card = PanelContainer.new()
	var vbox = VBoxContainer.new()

	var name_label = Label.new()
	name_label.text = item.get("name", "Unknown Item")

	var desc_label = Label.new()
	desc_label.text = item.get("description", "")

	var price_label = Label.new()
	price_label.text = str(item.get("price_sc", 0)) + " SC"

	var buy_button = Button.new()
	buy_button.text = "Purchase"
	buy_button.pressed.connect(func(): purchase_item(item.get("item_id", "")))

	vbox.add_child(name_label)
	vbox.add_child(desc_label)
	vbox.add_child(price_label)
	vbox.add_child(buy_button)

	card.add_child(vbox)
	return card

func purchase_item(item_id: String):
	var result = await NetClient.purchase_item(item_id, 1)

	if result.success:
		print("Item purchased successfully!")
		load_catalog()  # Refresh
	else:
		print("Purchase failed: ", result.get("error", "Unknown error"))

func show_shop():
	visible = true
	load_catalog()

func hide_shop():
	visible = false

func _on_close_button_pressed():
	hide_shop()

func _on_iap_button_pressed():
	# Open IAP purchase screen
	show_iap_packages()

func show_iap_packages():
	var result = await NetClient.make_get_request(NetClient.API_BASE + "/v1/economy/iap-packages")

	if result.success:
		var packages = result.data.get("packages", {})
		# Display IAP packages
		# Would integrate with Google Play / Apple IAP here
