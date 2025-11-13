/**
 * Comprehensive logging system for React frontend
 * Tracks errors, user actions, API calls, and performance
 */

const LogLevel = {
  DEBUG: 0,
  INFO: 1,
  WARN: 2,
  ERROR: 3,
  CRITICAL: 4
};

class Logger {
  constructor() {
    this.logLevel = import.meta.env.DEV ? LogLevel.DEBUG : LogLevel.INFO;
    this.sessionId = this.generateSessionId();
    this.sessionStartTime = Date.now();
    this.logs = [];
    this.maxLogs = 1000; // Keep last 1000 logs in memory

    this.init();
  }

  init() {
    this.info('='.repeat(80));
    this.info('CROWNBORN LEADERBOARD - WEB APP STARTING');
    this.info(`Session ID: ${this.sessionId}`);
    this.info(`Environment: ${import.meta.env.MODE}`);
    this.info(`User Agent: ${navigator.userAgent}`);
    this.info('='.repeat(80));

    // Setup global error handler
    window.addEventListener('error', (event) => {
      this.error(`Unhandled error: ${event.message}`, {
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
        error: event.error?.stack
      });
    });

    // Setup unhandled promise rejection handler
    window.addEventListener('unhandledrejection', (event) => {
      this.error(`Unhandled promise rejection: ${event.reason}`, {
        promise: event.promise,
        reason: event.reason
      });
    });

    // Log performance metrics
    if (window.performance && window.performance.timing) {
      window.addEventListener('load', () => {
        setTimeout(() => {
          const timing = window.performance.timing;
          const loadTime = timing.loadEventEnd - timing.navigationStart;
          this.logPerformance('page_load', loadTime, 'ms');
        }, 0);
      });
    }
  }

  generateSessionId() {
    return `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  getUptime() {
    return (Date.now() - this.sessionStartTime) / 1000;
  }

  formatMessage(level, message, context = null) {
    const timestamp = new Date().toISOString();
    const uptime = this.getUptime().toFixed(3);
    const levelStr = Object.keys(LogLevel).find(key => LogLevel[key] === level);

    let formatted = `[${timestamp}] [${levelStr}] [+${uptime}s]`;

    if (context) {
      formatted += ` [${context}]`;
    }

    formatted += ` ${message}`;

    return formatted;
  }

  log(level, message, data = null, context = null) {
    if (level < this.logLevel) {
      return;
    }

    const formatted = this.formatMessage(level, message, context);
    const logEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      data,
      context,
      sessionId: this.sessionId,
      uptime: this.getUptime()
    };

    // Store in memory
    this.logs.push(logEntry);
    if (this.logs.length > this.maxLogs) {
      this.logs.shift();
    }

    // Console output with appropriate method
    const consoleData = data ? [formatted, data] : [formatted];

    switch (level) {
      case LogLevel.DEBUG:
        console.debug(...consoleData);
        break;
      case LogLevel.INFO:
        console.log(...consoleData);
        break;
      case LogLevel.WARN:
        console.warn(...consoleData);
        break;
      case LogLevel.ERROR:
      case LogLevel.CRITICAL:
        console.error(...consoleData);
        break;
    }

    // Send critical errors to server if in production
    if (level >= LogLevel.ERROR && !import.meta.env.DEV) {
      this.sendToServer(logEntry);
    }
  }

  // Main logging methods
  debug(message, data = null, context = null) {
    this.log(LogLevel.DEBUG, message, data, context);
  }

  info(message, data = null, context = null) {
    this.log(LogLevel.INFO, message, data, context);
  }

  warn(message, data = null, context = null) {
    this.log(LogLevel.WARN, message, data, context);
  }

  error(message, data = null, context = null) {
    this.log(LogLevel.ERROR, message, data, context);
  }

  critical(message, data = null, context = null) {
    this.log(LogLevel.CRITICAL, message, data, context);
  }

  // Specialized logging methods
  logUserAction(action, details = {}) {
    this.info(`USER_ACTION: ${action}`, details, 'UserAction');
  }

  logApiRequest(method, url, requestData = null) {
    this.debug(`API_REQUEST: ${method} ${url}`, requestData, 'API');
  }

  logApiResponse(method, url, status, responseData = null, duration = 0) {
    const message = `API_RESPONSE: ${method} ${url} -> ${status} (${duration}ms)`;

    if (status >= 200 && status < 300) {
      this.info(message, responseData, 'API');
    } else if (status >= 400) {
      this.error(message, responseData, 'API');
    } else {
      this.warn(message, responseData, 'API');
    }
  }

  logApiError(method, url, error) {
    this.error(`API_ERROR: ${method} ${url}`, {
      message: error.message,
      stack: error.stack,
      response: error.response?.data
    }, 'API');
  }

  logPerformance(metric, value, unit = 'ms') {
    this.debug(`PERFORMANCE: ${metric} = ${value}${unit}`, null, 'Performance');
  }

  logNavigation(from, to) {
    this.info(`NAVIGATION: ${from} -> ${to}`, null, 'Navigation');
  }

  logComponentMount(componentName) {
    this.debug(`COMPONENT_MOUNT: ${componentName}`, null, 'Component');
  }

  logComponentUnmount(componentName) {
    this.debug(`COMPONENT_UNMOUNT: ${componentName}`, null, 'Component');
  }

  // Export logs
  exportLogs() {
    const export_data = {
      sessionId: this.sessionId,
      startTime: new Date(this.sessionStartTime).toISOString(),
      endTime: new Date().toISOString(),
      duration: this.getUptime(),
      userAgent: navigator.userAgent,
      logs: this.logs
    };

    return JSON.stringify(export_data, null, 2);
  }

  // Download logs as file
  downloadLogs() {
    const logsJson = this.exportLogs();
    const blob = new Blob([logsJson], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `crownborn_logs_${this.sessionId}.json`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    this.info('Logs downloaded');
  }

  // Send logs to server (for error reporting)
  async sendToServer(logEntry) {
    try {
      // Only send in production to avoid spam during development
      if (import.meta.env.DEV) {
        return;
      }

      await fetch('/api/v1/logs/client', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(logEntry)
      });
    } catch (error) {
      // Fail silently to avoid infinite loop
      console.error('Failed to send log to server:', error);
    }
  }

  // Get recent logs
  getRecentLogs(count = 100) {
    return this.logs.slice(-count);
  }

  // Clear logs
  clearLogs() {
    this.logs = [];
    this.info('Logs cleared');
  }

  // Set log level
  setLogLevel(level) {
    this.logLevel = level;
    this.info(`Log level set to: ${Object.keys(LogLevel).find(key => LogLevel[key] === level)}`);
  }
}

// Create singleton instance
const logger = new Logger();

// Expose globally for debugging
if (import.meta.env.DEV) {
  window.logger = logger;
}

export default logger;
export { LogLevel };
