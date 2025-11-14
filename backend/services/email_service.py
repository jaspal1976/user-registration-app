
import os
import json
import asyncio
from typing import Dict, Any
from dotenv import load_dotenv
from logger_config import logger

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
    """Send email task - processes email sending asynchronously."""
    logger.info(f"Processing email task for user: {user_id}, email: {email}")
    
    try:
        sendgrid_api_key = os.getenv('SENDGRID_API_KEY')
        
        if not sendgrid_api_key:
            # In local development without SendGrid, simulate email sending
            logger.info(f"[LOCAL MODE] Simulating email to {email} for user {user_id}")
            await asyncio.sleep(1)  # Simulate network delay
            logger.info(f"Email simulation completed for user {user_id}")
            return {
                'success': True,
                'messageId': f'msg-{user_id}',
                'email': email,
                'userId': user_id,
                'mode': 'local-simulated'
            }
        
        # Send email using SendGrid
        from_email = os.getenv('SENDGRID_FROM_EMAIL', 'noreply@yourapp.com')
        logger.info(f"Sending email via SendGrid from {from_email} to {email}")
        
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
        logger.debug(f"Sending email via SendGrid API for user {user_id}")
        response = await loop.run_in_executor(None, sg.send, message)
        logger.info(f"Email sent successfully via SendGrid. Status: {response.status_code}, User: {user_id}")
        
        # Update Firestore to mark email as sent
        if USE_GCP:
            try:
                logger.debug(f"Updating Firestore for user {user_id} to mark email as sent")
                db = FirestoreClient()
                user_ref = db.collection('users').document(user_id)
                user_ref.update({
                    'emailSent': True,
                    'emailSentAt': FirestoreClient.SERVER_TIMESTAMP,
                    'emailMessageId': str(response.status_code)
                })
                logger.info(f"Firestore updated successfully for user {user_id}")
            except Exception as e:
                logger.warning(f"Could not update Firestore for user {user_id}: {str(e)}", exc_info=True)
        
        mode = 'gcp-sendgrid' if USE_GCP else 'local-sendgrid'
        logger.info(f"Email task completed successfully. Mode: {mode}, User: {user_id}")
        return {
            'success': True,
            'messageId': f'msg-{user_id}',
            'email': email,
            'userId': user_id,
            'statusCode': response.status_code,
            'mode': mode
        }
    except Exception as e:
        logger.error(f"Error sending email for user {user_id}: {str(e)}", exc_info=True)
        return {
            'success': False,
            'error': str(e),
            'email': email,
            'userId': user_id
        }


class EmailService:
    """Service for queuing and processing email tasks."""
    
    def __init__(self):
        logger.info(f"Initializing EmailService. Mode: {'GCP' if USE_GCP else 'Local'}")
        if USE_GCP:
            self._init_gcp()
        else:
            self._init_local()
    
    def _init_gcp(self):
        """Initialize GCP Cloud Tasks client."""
        try:
            logger.info("Initializing GCP Cloud Tasks client")
            self.tasks_client = tasks_v2.CloudTasksClient()
            self.project_id = os.getenv('GCP_PROJECT_ID', 'demo-project')
            self.location = os.getenv('GCP_LOCATION', 'us-central1')
            self.queue_name = os.getenv('GCP_QUEUE_NAME', 'email-queue')
            
            logger.info(f"GCP configuration - Project: {self.project_id}, Location: {self.location}, Queue: {self.queue_name}")
            
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
            logger.info(f"Email handler URL: {self.email_handler_url}")
            logger.info("GCP Cloud Tasks client initialized successfully")
        except Exception as e:
            logger.warning(f"GCP initialization failed: {str(e)}. Falling back to local mode", exc_info=True)
            self._init_local()
            global USE_GCP, LOCAL_MODE
            USE_GCP = False
            LOCAL_MODE = True
    
    def _init_local(self):
        """Initialize local asyncio task queue."""
        logger.info("Initializing local asyncio task queue")
        self.task_queue = asyncio.Queue()
        # Start background task processor
        self._background_task = None
        logger.info("Local mode initialized successfully")
    
    async def queue_email(self, user_id: str, email: str) -> str:
        """Queue an email task for processing."""
        logger.info(f"Queueing email task for user: {user_id}, email: {email}")
        try:
            if USE_GCP and hasattr(self, 'tasks_client'):
                logger.debug(f"Using GCP Cloud Tasks for user {user_id}")
                return self._queue_gcp_task(user_id, email)
            else:
                logger.debug(f"Using local asyncio for user {user_id}")
                return await self._queue_local_task(user_id, email)
        except Exception as e:
            logger.error(f"Failed to queue email task for user {user_id}: {str(e)}", exc_info=True)
            raise Exception(f"Failed to queue email task: {str(e)}")
    
    def _queue_gcp_task(self, user_id: str, email: str) -> str:
        """Queue email task using GCP Cloud Tasks."""
        logger.info(f"Creating Cloud Task for user: {user_id}, email: {email}")
        
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
        logger.debug(f"Submitting task to Cloud Tasks queue: {self.queue_name}")
        response = self.tasks_client.create_task(
            request={
                'parent': self.queue_path,
                'task': task
            }
        )
        
        logger.info(f"Cloud Task created successfully. Task name: {response.name}, User: {user_id}")
        return response.name
    
    async def _queue_local_task(self, user_id: str, email: str) -> str:
        """Queue email task using asyncio background task (local development)."""
        import time
        
        logger.debug(f"Queueing local task for user: {user_id}, email: {email}")
        
        # Add minimum delay for local testing (to show spinner in frontend)
        start_time = time.time()
        min_delay = float(os.getenv('EMAIL_MIN_DELAY_SECONDS', '1.0'))  # Default 1 second
        
        # Create a background task
        task_id = f'task-{user_id}-{email}'
        logger.debug(f"Created task ID: {task_id}")
        
        # Start background task
        logger.info(f"Starting background email task for user: {user_id}")
        asyncio.create_task(send_email_task(user_id, email))
        
        # Ensure minimum delay has passed (for local testing)
        elapsed_time = time.time() - start_time
        if elapsed_time < min_delay:
            await asyncio.sleep(min_delay - elapsed_time)
        
        logger.info(f"Local task queued successfully. Task ID: {task_id}, User: {user_id}")
        return task_id
