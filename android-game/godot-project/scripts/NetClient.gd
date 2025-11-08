extends Node
# Network client for server communication

const API_BASE = "http://your-server-url:8000"

var http_client = HTTPClient.new()

func _ready():
	pass

func register_user(display_name: String, gender: String, country_code: String) -> Dictionary:
	var url = API_BASE + "/v1/auth/register"
	var data = {
		"display_name": display_name,
		"gender": gender,
		"country_code": country_code
	}

	var result = await make_post_request(url, data)
	if result.success:
		GameState.user_id = result.data.get("user_id", "")
		GameState.jwt_token = result.data.get("access_token", "")
		GameState.display_name = display_name
		GameState.save_game()

	return result

func submit_stage_completion(stage: int, time_ms: int, deaths: int, stars: int, completed: bool) -> Dictionary:
	var url = API_BASE + "/v1/progress/stage"
	var data = {
		"stage": stage,
		"time_ms": time_ms,
		"deaths": deaths,
		"stars": stars,
		"completed": completed
	}

	return await make_post_request(url, data, GameState.jwt_token)

func get_leaderboard(mode: String = "fastest_total", country: String = "") -> Dictionary:
	var url = API_BASE + "/v1/leaderboard/global?mode=" + mode
	if country:
		url += "&country=" + country

	return await make_get_request(url)

func get_shop_catalog() -> Dictionary:
	var url = API_BASE + "/v1/economy/catalog"
	return await make_get_request(url)

func purchase_item(item_id: String, quantity: int = 1) -> Dictionary:
	var url = API_BASE + "/v1/economy/spend"
	var data = {
		"item_id": item_id,
		"quantity": quantity
	}

	return await make_post_request(url, data, GameState.jwt_token)

func process_iap_purchase(provider: String, receipt_id: String, package_id: String) -> Dictionary:
	var url = API_BASE + "/v1/economy/purchase"
	var data = {
		"provider": provider,
		"receipt_id": receipt_id,
		"package_id": package_id
	}

	return await make_post_request(url, data, GameState.jwt_token)

func make_get_request(url: String, token: String = "") -> Dictionary:
	var http_request = HTTPRequest.new()
	add_child(http_request)

	var headers = ["Content-Type: application/json"]
	if token:
		headers.append("Authorization: Bearer " + token)

	http_request.request(url, headers, HTTPClient.METHOD_GET)
	var response = await http_request.request_completed

	http_request.queue_free()

	var result_code = response[1]
	var body = response[3]

	if result_code == 200:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		return {"success": true, "data": json.get_data()}
	else:
		return {"success": false, "error": "Request failed"}

func make_post_request(url: String, data: Dictionary, token: String = "") -> Dictionary:
	var http_request = HTTPRequest.new()
	add_child(http_request)

	var headers = ["Content-Type: application/json"]
	if token:
		headers.append("Authorization: Bearer " + token)

	var json_data = JSON.stringify(data)

	http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	var response = await http_request.request_completed

	http_request.queue_free()

	var result_code = response[1]
	var body = response[3]

	if result_code == 200:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		return {"success": true, "data": json.get_data()}
	else:
		return {"success": false, "error": "Request failed"}
