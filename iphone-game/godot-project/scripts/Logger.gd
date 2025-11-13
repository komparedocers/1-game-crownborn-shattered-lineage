extends Node
# Global logging system for comprehensive error tracking

enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3,
	CRITICAL = 4
}

# Configuration
var current_log_level: LogLevel = LogLevel.INFO
var log_to_file: bool = true
var log_to_console: bool = true
var max_log_file_size: int = 10 * 1024 * 1024  # 10MB
var max_log_files: int = 5

# Log file paths
var log_directory: String = "user://logs"
var current_log_file: String = ""
var error_log_file: String = ""

# Session info
var session_id: String = ""
var session_start_time: int = 0

func _ready():
	# Generate session ID
	session_id = "%d_%s" % [Time.get_unix_time_from_system(), OS.get_unique_id().substr(0, 8)]
	session_start_time = Time.get_ticks_msec()

	# Setup log directory
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("logs"):
		dir.make_dir("logs")

	# Initialize log files
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	current_log_file = "%s/game_%s.log" % [log_directory, timestamp]
	error_log_file = "%s/errors_%s.log" % [log_directory, timestamp]

	# Log startup
	info("=" * 80)
	info("CROWNBORN: SHATTERED LINEAGE - GAME STARTING")
	info("Session ID: %s" % session_id)
	info("Platform: %s" % OS.get_name())
	info("Version: %s" % ProjectSettings.get_setting("application/config/version", "1.0.0"))
	info("=" * 80)

	# Clean old log files
	clean_old_logs()

func _exit_tree():
	info("=" * 80)
	info("GAME SHUTTING DOWN")
	var uptime_ms = Time.get_ticks_msec() - session_start_time
	info("Session duration: %.2f seconds" % (uptime_ms / 1000.0))
	info("=" * 80)

# Main logging functions
func debug(message: String, context: String = ""):
	_log(LogLevel.DEBUG, message, context)

func info(message: String, context: String = ""):
	_log(LogLevel.INFO, message, context)

func warning(message: String, context: String = ""):
	_log(LogLevel.WARNING, message, context)

func error(message: String, context: String = ""):
	_log(LogLevel.ERROR, message, context)

func critical(message: String, context: String = ""):
	_log(LogLevel.CRITICAL, message, context)

# Specialized logging functions
func log_player_action(action: String, details: Dictionary = {}):
	"""Log player actions for analytics"""
	var msg = "PLAYER_ACTION: %s" % action
	if not details.is_empty():
		msg += " | " + JSON.stringify(details)
	info(msg, "Player")

func log_game_event(event: String, data: Dictionary = {}):
	"""Log important game events"""
	var msg = "GAME_EVENT: %s" % event
	if not data.is_empty():
		msg += " | " + JSON.stringify(data)
	info(msg, "GameEvent")

func log_network_request(method: String, url: String, status: int = 0):
	"""Log network requests"""
	if status == 0:
		debug("NET_REQUEST: %s %s" % [method, url], "Network")
	else:
		info("NET_RESPONSE: %s %s -> Status %d" % [method, url, status], "Network")

func log_network_error(method: String, url: String, error_msg: String):
	"""Log network errors"""
	error("NET_ERROR: %s %s - %s" % [method, url, error_msg], "Network")

func log_payment_event(event: String, package_id: String, amount: int = 0):
	"""Log payment events"""
	info("PAYMENT: %s - Package: %s, Amount: %d SC" % [event, package_id, amount], "Payment")

func log_performance(metric: String, value: float, unit: String = "ms"):
	"""Log performance metrics"""
	debug("PERFORMANCE: %s = %.2f %s" % [metric, value, unit], "Performance")

func log_exception(exception: String, stack_trace: String = ""):
	"""Log exceptions with stack trace"""
	var msg = "EXCEPTION: %s" % exception
	if not stack_trace.is_empty():
		msg += "\nStack trace:\n%s" % stack_trace
	error(msg, "Exception")

# Core logging implementation
func _log(level: LogLevel, message: String, context: String = ""):
	# Skip if below current log level
	if level < current_log_level:
		return

	# Format log message
	var level_str = _get_level_string(level)
	var timestamp = Time.get_datetime_string_from_system()
	var uptime = (Time.get_ticks_msec() - session_start_time) / 1000.0

	var formatted_message = "[%s] [%s] [+%.3fs]" % [timestamp, level_str, uptime]

	if context:
		formatted_message += " [%s]" % context

	formatted_message += " %s" % message

	# Console output
	if log_to_console:
		match level:
			LogLevel.DEBUG:
				print_debug(formatted_message)
			LogLevel.INFO:
				print(formatted_message)
			LogLevel.WARNING:
				push_warning(formatted_message)
			LogLevel.ERROR, LogLevel.CRITICAL:
				push_error(formatted_message)

	# File output
	if log_to_file:
		_write_to_file(current_log_file, formatted_message)

		# Also write errors to separate error log
		if level >= LogLevel.ERROR:
			_write_to_file(error_log_file, formatted_message)

func _write_to_file(filepath: String, message: String):
	"""Write log message to file"""
	var file = FileAccess.open(filepath, FileAccess.READ_WRITE)

	if not file:
		push_error("Failed to open log file: %s" % filepath)
		return

	# Check file size and rotate if needed
	file.seek_end()
	if file.get_position() > max_log_file_size:
		file.close()
		_rotate_log_file(filepath)
		file = FileAccess.open(filepath, FileAccess.WRITE)

	file.seek_end()
	file.store_line(message)
	file.close()

func _rotate_log_file(filepath: String):
	"""Rotate log file when it exceeds max size"""
	var dir = DirAccess.open(log_directory)

	# Rename current log
	var base_name = filepath.get_file().trim_suffix(".log")
	var timestamp = Time.get_unix_time_from_system()
	var new_name = "%s/%s_%d.log" % [log_directory, base_name, timestamp]

	dir.rename(filepath, new_name)
	info("Log file rotated: %s" % new_name)

func clean_old_logs():
	"""Remove old log files keeping only max_log_files most recent"""
	var dir = DirAccess.open(log_directory)
	if not dir:
		return

	var files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".log"):
			var full_path = "%s/%s" % [log_directory, file_name]
			var modified_time = FileAccess.get_modified_time(full_path)
			files.append({"name": file_name, "time": modified_time, "path": full_path})

		file_name = dir.get_next()

	dir.list_dir_end()

	# Sort by modification time (oldest first)
	files.sort_custom(func(a, b): return a.time < b.time)

	# Remove old files
	var files_to_remove = files.size() - max_log_files
	if files_to_remove > 0:
		for i in range(files_to_remove):
			dir.remove(files[i].path)
			debug("Removed old log file: %s" % files[i].name)

func _get_level_string(level: LogLevel) -> String:
	match level:
		LogLevel.DEBUG: return "DEBUG"
		LogLevel.INFO: return "INFO"
		LogLevel.WARNING: return "WARN"
		LogLevel.ERROR: return "ERROR"
		LogLevel.CRITICAL: return "CRITICAL"
		_: return "UNKNOWN"

# Helper functions
func set_log_level(level: LogLevel):
	"""Set minimum log level"""
	current_log_level = level
	info("Log level set to: %s" % _get_level_string(level))

func get_session_id() -> String:
	return session_id

func get_log_directory() -> String:
	return log_directory

func export_logs() -> String:
	"""Export all logs as a single string for bug reports"""
	var export_text = "=== CROWNBORN LOG EXPORT ===\n"
	export_text += "Session ID: %s\n" % session_id
	export_text += "Platform: %s\n" % OS.get_name()
	export_text += "Export Time: %s\n\n" % Time.get_datetime_string_from_system()

	# Read current log file
	var file = FileAccess.open(current_log_file, FileAccess.READ)
	if file:
		export_text += "=== GAME LOG ===\n"
		export_text += file.get_as_text()
		file.close()

	# Read error log file
	file = FileAccess.open(error_log_file, FileAccess.READ)
	if file:
		export_text += "\n\n=== ERROR LOG ===\n"
		export_text += file.get_as_text()
		file.close()

	return export_text
