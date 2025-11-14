
import os
import json
import asyncio
from typing import Dict, Any
from dotenv import load_dotenv

load_dotenv()

# check if running in GCP or local mode
USE_GCP = os.getenv('USE_GCP', 'false').lower() == 'true'
LOCAL_MODE = not USE_GCP

if USE_GCP:
    from google.cloud import tasks_v2
    from google.cloud.firestore import Client as FirestoreClient
    from sendgrid import SendGridAPIClient
    from sendgrid.helpers.mail import Mail


async def send_email_task(user_id: str, email: str) -> Dict[str, Any]:
   
    try:
        sendgrid_api_key = os.getenv('SENDGRID_API_KEY')
        
        if not sendgrid_api_key:
            # In local development without SendGrid, simulate email sending
            print(f"[EMAIL SERVICE] [LOCAL MODE] Simulating email to {email} for user {user_id}")
            await asyncio.sleep(1)  # Simulate network delay
            return {
                'success': True,
                'messageId': f'msg-{user_id}',
                'email': email,
                'userId': user_id,
                'mode': 'local-simulated'
            }
        
        # Send email using SendGrid
        from_email = os.getenv('SENDGRID_FROM_EMAIL', 'noreply@yourapp.com')
        
        message = Mail(
            from_email=from_email,
            to_emails=email,
            subject='Welcome to Our App!',
            html_content=f'''
            <html>
                <body>
                    <h1>Welcome!</h1>
                    <p>Thank you for registering with us!</p>
                    <p>Your user ID: {user_id}</p>
                    <p>We're excited to have you on board.</p>
                </body>
            </html>
            '''
        )
        
        # Run SendGrid in executor to avoid blocking
        loop = asyncio.get_event_loop()
        sg = SendGridAPIClient(sendgrid_api_key)
        response = await loop.run_in_executor(None, sg.send, message)
        
        # Update Firestore to mark email as sent
        if USE_GCP:
            try:
                db = FirestoreClient()
                user_ref = db.collection('users').document(user_id)
                user_ref.update({
                    'emailSent': True,
                    'emailSentAt': FirestoreClient.SERVER_TIMESTAMP,
                    'emailMessageId': str(response.status_code)
                })
            except Exception as e:
                print(f"[EMAIL SERVICE] Warning: Could not update Firestore: {str(e)}")
        
        return {
            'success': True,
            'messageId': f'msg-{user_id}',
            'email': email,
            'userId': user_id,
            'statusCode': response.status_code,
            'mode': 'gcp-sendgrid' if USE_GCP else 'local-sendgrid'
        }
    except Exception as e:
        print(f"[EMAIL SERVICE] Error sending email: {str(e)}")
        return {
            'success': False,
            'error': str(e),
            'email': email,
            'userId': user_id
        }


class EmailService:
    
    def __init__(self):
        
        if USE_GCP:
            self._init_gcp()
        else:
            self._init_local()
    
    def _init_gcp(self):
        """Initialize GCP Cloud Tasks client."""
        try:
            self.tasks_client = tasks_v2.CloudTasksClient()
            self.project_id = os.getenv('GCP_PROJECT_ID', 'demo-project')
            self.location = os.getenv('GCP_LOCATION', 'us-central1')
            self.queue_name = os.getenv('GCP_QUEUE_NAME', 'email-queue')
            
            # Construct queue path
            parent = self.tasks_client.queue_path(
                self.project_id, 
                self.location, 
                self.queue_name
            )
            self.queue_path = parent
            
            # Cloud Function or Cloud Run endpoint for processing emails
            self.email_handler_url = os.getenv(
                'EMAIL_HANDLER_URL',
                'https://your-region-your-project.cloudfunctions.net/send-email'
            )
        except Exception as e:
            print(f"[EMAIL SERVICE] Warning: GCP initialization failed: {str(e)}")
            print("[EMAIL SERVICE] Falling back to local mode")
            self._init_local()
            global USE_GCP, LOCAL_MODE
            USE_GCP = False
            LOCAL_MODE = True
    
    def _init_local(self):
        """Initialize local asyncio task queue."""
        self.task_queue = asyncio.Queue()
        # Start background task processor
        self._background_task = None
    
    async def queue_email(self, user_id: str, email: str) -> str:
        
        try:
            if USE_GCP and hasattr(self, 'tasks_client'):
                return self._queue_gcp_task(user_id, email)
            else:
                return await self._queue_local_task(user_id, email)
        except Exception as e:
            raise Exception(f"Failed to queue email task: {str(e)}")
    
    def _queue_gcp_task(self, user_id: str, email: str) -> str:
        
        # Create task payload
        task_payload = {
            'userId': user_id,
            'email': email
        }
        
        # Create task
        task = {
            'http_request': {
                'http_method': tasks_v2.HttpMethod.POST,
                'url': self.email_handler_url,
                'headers': {
                    'Content-Type': 'application/json',
                },
                'body': json.dumps(task_payload).encode(),
            }
        }
        
        # Create the task
        response = self.tasks_client.create_task(
            request={
                'parent': self.queue_path,
                'task': task
            }
        )
        
        return response.name
    
    async def _queue_local_task(self, user_id: str, email: str) -> str:
        
        import time
        
        # Add minimum delay for local testing (to show spinner in frontend)
        start_time = time.time()
        min_delay = float(os.getenv('EMAIL_MIN_DELAY_SECONDS', '1.0'))  # Default 1 second
        
        # Create a background task
        task_id = f'task-{user_id}-{email}'
        
        # Start background task
        asyncio.create_task(send_email_task(user_id, email))
        
        # Ensure minimum delay has passed (for local testing)
        elapsed_time = time.time() - start_time
        if elapsed_time < min_delay:
            await asyncio.sleep(min_delay - elapsed_time)
        
        return task_id
