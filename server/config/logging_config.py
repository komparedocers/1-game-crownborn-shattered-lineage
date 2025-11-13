import logging
import sys
from pathlib import Path
from logging.handlers import RotatingFileHandler
from datetime import datetime

# Create logs directory
LOGS_DIR = Path("logs")
LOGS_DIR.mkdir(exist_ok=True)

# Log format
LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(filename)s:%(lineno)d - %(funcName)s() - %(message)s"
DATE_FORMAT = "%Y-%m-%d %H:%M:%S"

def setup_logger(name: str, level: int = logging.INFO) -> logging.Logger:
    """
    Setup logger with file and console handlers

    Args:
        name: Logger name (usually module name)
        level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)

    Returns:
        Configured logger instance
    """
    logger = logging.getLogger(name)
    logger.setLevel(level)

    # Prevent duplicate handlers
    if logger.handlers:
        return logger

    # Console handler (stdout)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)
    console_formatter = logging.Formatter(LOG_FORMAT, DATE_FORMAT)
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)

    # File handler - All logs
    all_logs_file = LOGS_DIR / "crownborn_all.log"
    file_handler = RotatingFileHandler(
        all_logs_file,
        maxBytes=10 * 1024 * 1024,  # 10MB
        backupCount=5
    )
    file_handler.setLevel(logging.DEBUG)
    file_formatter = logging.Formatter(LOG_FORMAT, DATE_FORMAT)
    file_handler.setFormatter(file_formatter)
    logger.addHandler(file_handler)

    # File handler - Errors only
    error_logs_file = LOGS_DIR / "crownborn_errors.log"
    error_handler = RotatingFileHandler(
        error_logs_file,
        maxBytes=10 * 1024 * 1024,  # 10MB
        backupCount=5
    )
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(file_formatter)
    logger.addHandler(error_handler)

    return logger

def log_request(logger: logging.Logger, method: str, url: str, params: dict = None, body: dict = None):
    """Log incoming HTTP request"""
    logger.info(f"REQUEST: {method} {url}")
    if params:
        logger.debug(f"Query params: {params}")
    if body:
        logger.debug(f"Request body: {body}")

def log_response(logger: logging.Logger, status_code: int, response_data: dict = None):
    """Log HTTP response"""
    logger.info(f"RESPONSE: Status {status_code}")
    if response_data:
        logger.debug(f"Response data: {response_data}")

def log_error(logger: logging.Logger, error: Exception, context: str = ""):
    """Log exception with full traceback"""
    logger.error(f"ERROR in {context}: {type(error).__name__}: {str(error)}", exc_info=True)

def log_database_query(logger: logging.Logger, query: str, params: dict = None):
    """Log database query"""
    logger.debug(f"DB QUERY: {query}")
    if params:
        logger.debug(f"DB PARAMS: {params}")

def log_payment_event(logger: logging.Logger, event: str, user_id: str, amount: int, provider: str):
    """Log payment-related events"""
    logger.info(f"PAYMENT: {event} - User: {user_id}, Amount: {amount}, Provider: {provider}")

def log_security_event(logger: logging.Logger, event: str, user_id: str = None, ip: str = None):
    """Log security-related events"""
    logger.warning(f"SECURITY: {event} - User: {user_id}, IP: {ip}")

# Create main application logger
app_logger = setup_logger("crownborn", logging.INFO)
