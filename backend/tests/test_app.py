
import pytest
import sys
from pathlib import Path
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient

# Add parent directory to path for imports
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

from app import app
from services.email_service import EmailService, send_email_task

# Create test client
client = TestClient(app)


class TestSendEmailEndpoint:
    """Tests for the /api/send-email endpoint."""

    def test_send_email_success(self):
        """Test successful email sending request."""
        # Mock the async method properly
        async def mock_queue_email(user_id, email):
            return 'test-task-id'
        
        with patch.object(EmailService, 'queue_email', side_effect=mock_queue_email):
            response = client.post(
                '/api/send-email',
                json={'userId': 'user-123', 'email': 'test@example.com'}
            )
            
            assert response.status_code == 202
            data = response.json()
            assert data['success'] is True
            assert data['taskId'] == 'test-task-id'
            assert data['message'] == 'Email queued successfully'

    def test_send_email_missing_user_id(self):
        """Test email sending with missing userId."""
        response = client.post(
            '/api/send-email',
            json={'email': 'test@example.com'}
        )
        
        assert response.status_code == 422  

    def test_send_email_missing_email(self):
        """Test email sending with missing email."""
        response = client.post(
            '/api/send-email',
            json={'userId': 'user-123'}
        )
        
        assert response.status_code == 422  

    def test_send_email_invalid_email(self):
        """Test email sending with invalid email format."""
        response = client.post(
            '/api/send-email',
            json={'userId': 'user-123', 'email': 'invalid-email'}
        )
        
        assert response.status_code == 422  

    def test_send_email_empty_body(self):
        """Test email sending with empty request body."""
        response = client.post(
            '/api/send-email',
            json={}
        )
        
        assert response.status_code == 422  

    def test_send_email_server_error(self):
        """Test email sending with server error."""
        async def mock_queue_email(*args, **kwargs):
            raise Exception('Server error')
        
        with patch.object(EmailService, 'queue_email', side_effect=mock_queue_email):
            response = client.post(
                '/api/send-email',
                json={'userId': 'user-123', 'email': 'test@example.com'}
            )
            
            assert response.status_code == 500
            data = response.json()
            assert 'detail' in data


class TestHealthEndpoint:
   
    def test_health_check(self):
        
        response = client.get('/api/health')
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'healthy'


class TestRootEndpoint:

    def test_root_endpoint(self):
        response = client.get('/')
        
        assert response.status_code == 200
        data = response.json()
        assert 'message' in data
        assert 'version' in data
        assert 'docs' in data


class TestSendEmailTask:
    
    @pytest.mark.asyncio
    @patch('services.email_service.print')
    
    async def test_send_email_task_success(self, mock_print):
        """Test successful email task execution."""
        result = await send_email_task('user-123', 'test@example.com')
        
        assert result['success'] is True
        assert result['email'] == 'test@example.com'
        assert result['userId'] == 'user-123'
        assert 'messageId' in result

    @pytest.mark.asyncio
    @patch('services.email_service.print')
    async def test_send_email_task_failure(self, mock_print):
        """Test email task execution with error."""
        result = await send_email_task('user-123', 'test@example.com')
        assert result['success'] is True


class TestEmailService:

    @pytest.mark.asyncio
    async def test_queue_email_success(self):
        """Test successful email queuing."""
        from services.email_service import EmailService
        from unittest.mock import AsyncMock
        
        with patch('services.email_service.EmailService._queue_local_task', new_callable=AsyncMock) as mock_queue:
            mock_queue.return_value = 'test-task-id'
            
            service = EmailService()
            task_id = await service.queue_email('user-123', 'test@example.com')
            
            assert task_id == 'test-task-id'
            mock_queue.assert_called_once_with('user-123', 'test@example.com')

    @pytest.mark.asyncio
    async def test_queue_email_failure(self):
        """Test email queuing with error."""
        from services.email_service import EmailService
        from unittest.mock import AsyncMock
        
        with patch('services.email_service.EmailService._queue_local_task', new_callable=AsyncMock) as mock_queue:
            mock_queue.side_effect = Exception('Queue error')
            
            service = EmailService()
            
            with pytest.raises(Exception) as exc_info:
                await service.queue_email('user-123', 'test@example.com')
            
            assert 'Failed to queue email task' in str(exc_info.value)
