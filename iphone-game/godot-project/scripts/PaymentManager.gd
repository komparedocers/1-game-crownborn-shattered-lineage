extends Node
# Handles in-app purchases for Google Play, Apple Pay, and Stripe

signal purchase_completed(success: bool, product_id: String)
signal purchase_failed(error: String)

var is_android: bool = OS.get_name() == "Android"
var is_ios: bool = OS.get_name() == "iOS"

# Google Play Billing (Android)
var google_play_billing

# Apple StoreKit (iOS)
var ios_in_app_store

func _ready():
	if is_android:
		setup_google_play_billing()
	elif is_ios:
		setup_apple_iap()

func setup_google_play_billing():
	# Initialize Google Play Billing
	if Engine.has_singleton("GodotGooglePlayBilling"):
		google_play_billing = Engine.get_singleton("GodotGooglePlayBilling")
		google_play_billing.connect("purchase_updated", _on_google_purchase_updated)
		google_play_billing.connect("purchase_error", _on_google_purchase_error)

		# Start connection
		google_play_billing.startConnection()

func setup_apple_iap():
	# Initialize Apple In-App Purchase
	if Engine.has_singleton("InAppStore"):
		ios_in_app_store = Engine.get_singleton("InAppStore")
		ios_in_app_store.connect("purchase_success", _on_apple_purchase_success)
		ios_in_app_store.connect("purchase_fail", _on_apple_purchase_fail)

		# Request products
		var product_ids = ["small_pack", "medium_pack", "large_pack", "mega_pack", "legendary_pack"]
		ios_in_app_store.request_product_info({"product_ids": product_ids})

func purchase_package(package_id: String):
	"""Purchase a currency package"""

	if is_android and google_play_billing:
		# Google Play purchase
		google_play_billing.purchase(package_id)

	elif is_ios and ios_in_app_store:
		# Apple IAP purchase
		ios_in_app_store.purchase({"product_id": package_id})

	else:
		# Web/Desktop - use Stripe
		purchase_with_stripe(package_id)

func purchase_with_stripe(package_id: String):
	"""Web-based Stripe purchase"""
	# This would open a web view or external browser for Stripe checkout
	var stripe_url = "https://your-domain.com/stripe-checkout?package=" + package_id
	OS.shell_open(stripe_url)

# Google Play callbacks
func _on_google_purchase_updated(purchases):
	for purchase in purchases:
		var product_id = purchase.get("sku", "")
		var purchase_token = purchase.get("purchaseToken", "")

		# Verify with server
		verify_purchase_with_server("google_play", purchase_token, product_id)

func _on_google_purchase_error(code, message):
	print("Google Play purchase error: ", message)
	purchase_failed.emit(message)

# Apple IAP callbacks
func _on_apple_purchase_success(receipt):
	var product_id = receipt.get("productID", "")
	var transaction_id = receipt.get("transactionID", "")

	# Verify with server
	verify_purchase_with_server("apple_iap", transaction_id, product_id)

func _on_apple_purchase_fail(error):
	print("Apple IAP purchase error: ", error)
	purchase_failed.emit(error)

# Server verification
func verify_purchase_with_server(provider: String, receipt_id: String, product_id: String):
	"""Verify purchase with game server"""
	var result = await NetClient.process_iap_purchase(provider, receipt_id, product_id)

	if result.success:
		var sc_granted = result.data.get("sc_granted", 0)
		var new_balance = result.data.get("new_balance", 0)

		# Update local currency
		GameState.sky_crowns = new_balance

		print("Purchase successful! Granted: ", sc_granted, " SC")
		purchase_completed.emit(true, product_id)
	else:
		print("Purchase verification failed: ", result.get("error", "Unknown"))
		purchase_failed.emit(result.get("error", "Verification failed"))

# Helper function to get product prices
func get_product_info() -> Array:
	return [
		{"id": "small_pack", "sc": 500, "price": "$0.99"},
		{"id": "medium_pack", "sc": 1200, "price": "$1.99"},
		{"id": "large_pack", "sc": 2800, "price": "$4.99"},
		{"id": "mega_pack", "sc": 6000, "price": "$9.99"},
		{"id": "legendary_pack", "sc": 15000, "price": "$19.99"},
	]
