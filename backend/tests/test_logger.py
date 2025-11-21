import pytest
import os
import logging
from pathlib import Path
from unittest.mock import patch, MagicMock
import sys

backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

from logger_config import setup_logger, logger, LOG_DIR, LOG_FILE, ERROR_LOG_FILE


class TestLoggerConfig:
    def test_log_dir_created(self):
        assert LOG_DIR.exists()
        assert LOG_DIR.is_dir()

    def test_log_files_exist(self):
        assert LOG_FILE is not None
        assert ERROR_LOG_FILE is not None
        assert LOG_FILE.parent == LOG_DIR
        assert ERROR_LOG_FILE.parent == LOG_DIR

    def test_setup_logger_creates_logger(self):
        test_logger = setup_logger("test_logger")
        assert isinstance(test_logger, logging.Logger)
        assert test_logger.name == "test_logger"

    def test_setup_logger_handlers_exist(self):
        test_logger = setup_logger("test_logger_handlers")
        handlers = test_logger.handlers
        assert len(handlers) >= 2
        
        handler_types = [type(h).__name__ for h in handlers]
        assert 'StreamHandler' in handler_types or 'RotatingFileHandler' in handler_types

    def test_setup_logger_uses_env_level(self):
        with patch.dict(os.environ, {'LOG_LEVEL': 'DEBUG'}, clear=False):
            test_logger = setup_logger("test_env_logger")
            assert test_logger.level == logging.DEBUG

    def test_setup_logger_default_level(self):
        with patch.dict(os.environ, {}, clear=True):
            if 'LOG_LEVEL' in os.environ:
                del os.environ['LOG_LEVEL']
            test_logger = setup_logger("test_default_logger", level=None)
            assert test_logger.level == logging.INFO

    def test_setup_logger_custom_level(self):
        test_logger = setup_logger("test_custom_logger", level="WARNING")
        assert test_logger.level == logging.WARNING

    def test_setup_logger_idempotent(self):
        test_logger = setup_logger("test_idempotent")
        initial_handler_count = len(test_logger.handlers)
        
        same_logger = setup_logger("test_idempotent")
        
        assert test_logger is same_logger
        assert len(same_logger.handlers) == initial_handler_count

    def test_default_logger_instance(self):
        assert logger is not None
        assert isinstance(logger, logging.Logger)

    def test_logger_logs_to_console(self, caplog):
        with caplog.at_level("INFO"):
            logger.info("Test console log message")
            assert "Test console log message" in caplog.text

    def test_logger_format(self, caplog):
        with caplog.at_level("INFO"):
            logger.info("Format test")
            assert "user_registration_app" in caplog.text or "INFO" in caplog.text
            assert "Format test" in caplog.text

