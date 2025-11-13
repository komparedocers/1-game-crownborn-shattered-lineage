# Logging System Documentation

Comprehensive logging has been implemented across all components of Crownborn: Shattered Lineage for error tracking and debugging.

## Overview

Logging is implemented in:
- **Server Backend** (FastAPI/Python)
- **Game Client** (Godot/GDScript)
- **Web Frontend** (React/JavaScript)

All logging systems provide:
- Multiple log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- File and console output
- Session tracking
- Performance monitoring
- Error stack traces

---

## Server Backend Logging (Python)

### Configuration

**File:** `server/config/logging_config.py`

**Log Levels:**
- `DEBUG` (10): Detailed information for diagnosis
- `INFO` (20): General informational messages
- `WARNING` (30): Warning messages
- `ERROR` (40): Error messages
- `CRITICAL` (50): Critical issues

**Log Files:**
- `logs/crownborn_all.log` - All logs (rotated at 10MB)
- `logs/crownborn_errors.log` - Errors only (rotated at 10MB)

### Environment Variables

Add to `.env`:
```env
LOG_LEVEL=20  # 10=DEBUG, 20=INFO, 30=WARNING, 40=ERROR
LOG_TO_FILE=True
LOG_TO_CONSOLE=True
```

### Usage in Code

```python
from config.logging_config import setup_logger, log_error, log_security_event

logger = setup_logger("module_name")

# Basic logging
logger.debug("Debug message")
logger.info("Info message")
logger.warning("Warning message")
logger.error("Error message")
logger.critical("Critical message")

# Specialized logging
log_error(logger, exception, "context")
log_security_event(logger, "EVENT_NAME", user_id, ip)
log_payment_event(logger, "PURCHASE", user_id, amount, provider)
```

### Request/Response Logging

All HTTP requests are automatically logged with:
- Request method and path
- Query parameters and headers (debug level)
- Response status code
- Processing time
- Request ID (in headers)

**Example Log Output:**
```
2025-11-08 19:30:15 - main - INFO - [1699472415.123] POST /v1/auth/register
2025-11-08 19:30:15 - api.auth - INFO - Registration attempt - Display name: PlayerName, Gender: boy, Country: US
2025-11-08 19:30:15 - api.auth - INFO - User created successfully - ID: abc-123, Name: PlayerName
2025-11-08 19:30:15 - main - INFO - [1699472415.123] Status: 200 | Time: 0.045s
```

### Error Tracking

All exceptions are automatically logged with full stack traces:
```
2025-11-08 19:30:20 - api.progress - ERROR - ERROR in stage submission: ValueError: Invalid stage number
Traceback (most recent call last):
  File "server/api/progress.py", line 45, in submit_stage
    ...
```

---

## Game Client Logging (Godot)

### Configuration

**File:** `android-game/godot-project/scripts/Logger.gd`

**Singleton:** Available globally as `Logger`

**Log Files:**
- `user://logs/game_TIMESTAMP.log` - All game logs
- `user://logs/errors_TIMESTAMP.log` - Errors only

**Log Rotation:**
- Max file size: 10MB
- Max files kept: 5 (oldest deleted automatically)

### Usage in GDScript

```gdscript
# Basic logging
Logger.debug("Debug message")
Logger.info("Info message")
Logger.warning("Warning message")
Logger.error("Error message")
Logger.critical("Critical message")

# With context
Logger.info("Player spawned", "GameFlow")
Logger.error("Failed to load level", "LevelLoader")

# Specialized logging
Logger.log_player_action("ATTACK_ENEMY", {"weapon": "sword", "damage": 25})
Logger.log_game_event("BOSS_DEFEATED", {"boss": "General Krath", "time": 45.3})
Logger.log_network_request("POST", "/v1/progress/stage")
Logger.log_network_response("POST", "/v1/progress/stage", 200)
Logger.log_network_error("POST", "/v1/progress/stage", "Connection timeout")
Logger.log_payment_event("PURCHASE_COMPLETED", "small_pack", 500)
Logger.log_performance("frame_time", 16.7, "ms")
Logger.log_exception("NullReferenceException", get_stack())
```

### Session Tracking

Each game session gets a unique ID:
```gdscript
var session_id = Logger.get_session_id()  # "1699472415_abc123xyz"
```

### Export Logs

Export logs for bug reports:
```gdscript
var logs = Logger.export_logs()  # Returns formatted string
# Or download logs (would trigger file save dialog)
```

### Log Levels

Set minimum log level:
```gdscript
Logger.set_log_level(Logger.LogLevel.DEBUG)  # Show all logs
Logger.set_log_level(Logger.LogLevel.ERROR)  # Only errors
```

### Example Log Output

```
[2025-11-08 19:30:15] [INFO] [+0.123s] CROWNBORN: SHATTERED LINEAGE - GAME STARTING
[2025-11-08 19:30:15] [INFO] [+0.125s] Session ID: 1699472415_abc123xyz
[2025-11-08 19:30:15] [INFO] [+0.130s] Platform: Android
[2025-11-08 19:30:16] [INFO] [+1.250s] [Player] PLAYER_ACTION: ATTACK_ENEMY | {"weapon":"sword","damage":25}
[2025-11-08 19:30:18] [INFO] [+3.450s] [Network] NET_REQUEST: POST /v1/progress/stage
[2025-11-08 19:30:18] [INFO] [+3.520s] [Network] NET_RESPONSE: POST /v1/progress/stage -> Status 200
[2025-11-08 19:30:20] [ERROR] [+5.100s] [Exception] EXCEPTION: Failed to load texture: res://assets/missing.png
```

---

## Web Frontend Logging (React)

### Configuration

**File:** `server/web-gui/src/utils/logger.js`

**Singleton:** Import and use directly

**Storage:**
- Logs kept in memory (last 1000 entries)
- Critical errors sent to server in production
- Can be exported as JSON

### Usage in React

```javascript
import logger from './utils/logger'

// Basic logging
logger.debug('Debug message')
logger.info('Info message')
logger.warn('Warning message')
logger.error('Error message')
logger.critical('Critical message')

// With data
logger.info('User logged in', { userId: '123', name: 'Player' })

// Specialized logging
logger.logUserAction('CLICK_BUTTON', { button: 'submit' })
logger.logNavigation('/home', '/leaderboard')
logger.logComponentMount('LeaderboardTable')
logger.logComponentUnmount('LeaderboardTable')
logger.logPerformance('api_call', 150, 'ms')
```

### Automatic API Logging

Axios interceptors automatically log all API calls:
- Request method, URL, and data
- Response status and data
- Request duration
- Errors with full details

### Example Usage

```javascript
// In React components
useEffect(() => {
  logger.logComponentMount('App')
  return () => logger.logComponentUnmount('App')
}, [])

// User actions
const handleButtonClick = () => {
  logger.logUserAction('FETCH_LEADERBOARD', { mode, country })
  fetchData()
}

// Error boundaries
class ErrorBoundary extends React.Component {
  componentDidCatch(error, errorInfo) {
    logger.error('React error boundary caught error', {
      error: error.toString(),
      componentStack: errorInfo.componentStack
    })
  }
}
```

### Export Logs

```javascript
// Download logs as JSON file
logger.downloadLogs()

// Get logs programmatically
const recentLogs = logger.getRecentLogs(100)  // Last 100 logs
const allLogs = logger.exportLogs()  // All logs as JSON string
```

### Global Error Handling

Automatically captures:
- Unhandled JavaScript errors
- Unhandled promise rejections
- Performance metrics (page load time)

### Example Log Output

```
[2025-11-08T19:30:15.123Z] [INFO] [+0.001s] CROWNBORN LEADERBOARD - WEB APP STARTING
[2025-11-08T19:30:15.456Z] [DEBUG] [+0.334s] [API] API_REQUEST: GET /v1/leaderboard/global
[2025-11-08T19:30:15.789Z] [INFO] [+0.667s] [API] API_RESPONSE: GET /v1/leaderboard/global -> 200 (333ms)
[2025-11-08T19:30:16.000Z] [INFO] [+0.878s] [UserAction] USER_ACTION: CLICK_COUNTRY_FILTER | {"country":"US"}
[2025-11-08T19:30:17.500Z] [ERROR] [+2.378s] [API] API_ERROR: GET /v1/leaderboard/global | Network Error
```

---

## Log Locations

### Server
```
server/
├── logs/
│   ├── crownborn_all.log       # All logs
│   └── crownborn_errors.log    # Errors only
```

### Game Client (Android/iOS)
```
user://logs/                     # Platform-specific user directory
├── game_2025-11-08_19-30.log   # Game logs
└── errors_2025-11-08_19-30.log # Error logs
```

**Android:** `/data/data/com.crownborn.shatteredlineage/files/logs/`
**iOS:** `Documents/logs/`

### Web Frontend
- In-memory only
- Can be downloaded as JSON
- Critical errors sent to server in production

---

## Best Practices

### Server (Python)

```python
# Use appropriate log levels
logger.debug("Query: SELECT * FROM users WHERE id = %s", user_id)  # Debug
logger.info("User %s logged in", user_id)                          # Info
logger.warning("Rate limit approaching for user %s", user_id)      # Warning
logger.error("Failed to process payment for user %s", user_id)     # Error

# Use context managers for timing
import time
start = time.time()
# ... operation ...
logger.info(f"Operation completed in {time.time() - start:.3f}s")

# Log exceptions with context
try:
    risky_operation()
except Exception as e:
    log_error(logger, e, "risky_operation")
    raise
```

### Game Client (GDScript)

```gdscript
# Log important events
Logger.info("Level loaded: %s" % level_name)
Logger.log_game_event("MISSION_START", {"stage": 1, "character": "boy"})

# Log performance issues
var start_time = Time.get_ticks_msec()
heavy_operation()
var duration = Time.get_ticks_msec() - start_time
if duration > 100:
    Logger.warning("Heavy operation took %d ms" % duration)
Logger.log_performance("heavy_operation", duration)

# Log user actions for analytics
Logger.log_player_action("POWER_ACTIVATED", {"power": "Blink Step", "cooldown": 5.0})

# Always log errors
if not file:
    Logger.error("Failed to open file: %s" % filepath)
```

### Web Frontend (JavaScript)

```javascript
// Log component lifecycle
useEffect(() => {
  logger.logComponentMount('ComponentName')
  return () => logger.logComponentUnmount('ComponentName')
}, [])

// Log state changes
useEffect(() => {
  logger.debug('State changed', { mode, country, loading })
}, [mode, country, loading])

// Log errors in try-catch
try {
  await riskyOperation()
} catch (error) {
  logger.error('Operation failed', { error: error.message, stack: error.stack })
  throw error
}
```

---

## Troubleshooting

### Server logs not appearing

1. Check `LOG_LEVEL` in `.env`
2. Ensure `logs/` directory exists and is writable
3. Check `LOG_TO_FILE` and `LOG_TO_CONSOLE` settings
4. Restart server after changing `.env`

### Game logs not appearing

1. Check Logger singleton is loaded (should auto-load)
2. Verify `user://logs/` directory is accessible
3. Check log level: `Logger.set_log_level(Logger.LogLevel.DEBUG)`
4. Use Godot's Output panel to see console logs

### Web logs not appearing

1. Open browser Developer Tools → Console
2. Check `logger.setLogLevel(0)` for DEBUG level
3. In production, check Network tab for errors being sent to server

---

## Log Analysis

### Finding Errors

**Server:**
```bash
grep "ERROR" logs/crownborn_all.log
# Or just check
cat logs/crownborn_errors.log
```

**Game:**
Check `errors_TIMESTAMP.log` file

**Web:**
```javascript
const errors = logger.getRecentLogs(1000).filter(log => log.level >= 3)
console.table(errors)
```

### Performance Analysis

**Server:**
```bash
grep "Time:" logs/crownborn_all.log | grep -oP "\d+\.\d+s" | sort -n
```

**Game:**
```bash
grep "PERFORMANCE" game_TIMESTAMP.log
```

**Web:**
```javascript
const perfLogs = logger.getRecentLogs(1000).filter(log => log.context === 'Performance')
console.table(perfLogs)
```

---

## Production Considerations

### Server
- Set `LOG_LEVEL=20` (INFO) or higher in production
- Enable log rotation (already configured)
- Monitor disk space in `logs/` directory
- Consider centralized logging (e.g., ELK stack, Grafana Loki)

### Game Client
- Logs stored locally on device
- Old logs auto-deleted (keeps last 5)
- Can export logs for bug reports
- Consider sending critical errors to server

### Web Frontend
- In production, critical errors automatically sent to server
- In-memory logs cleared on page reload
- Users can download logs for bug reports

---

## Security Considerations

- **Never log sensitive data** (passwords, tokens, API keys)
- **Sanitize user input** before logging
- **Restrict log file access** in production
- **Rotate logs regularly** to prevent disk space issues
- **Monitor for log injection attacks**

**Example - DO NOT DO THIS:**
```python
logger.info(f"User password: {password}")  # NEVER!
logger.info(f"JWT token: {token}")         # NEVER!
```

**Example - SAFE:**
```python
logger.info(f"User authenticated: {user_id}")
logger.info(f"Token issued for user: {user_id}")
```

---

## Support

For issues or questions about the logging system:
1. Check this documentation
2. Review log files for errors
3. Check console output
4. Export and inspect logs

**Log files are your best debugging tool!**
