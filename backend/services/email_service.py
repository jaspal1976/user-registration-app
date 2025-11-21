
import os
import json
import asyncio
from typing import Dict, Any
from dotenv import load_dotenv
from logger_config import logger

load_dotenv()

USE_GCP = os.getenv('USE_GCP', 'false').lower() == 'true'
LOCAL_MODE = not USE_GCP

if USE_GCP:
    from google.cloud import tasks_v2
    from google.cloud.firestore import Client as FirestoreClient
    from sendgrid import SendGridAPIClient
    from sendgrid.helpers.mail import Mail


async def send_email_task(user_id: str, email: str) -> Dict[str, Any]:
    logger.info(f"Processing email for user {user_id}")
    
    try:
        sendgrid_api_key = os.getenv('SENDGRID_API_KEY')
        
        if not sendgrid_api_key:
            logger.info(f"[LOCAL] Simulating email to {email}")
            await asyncio.sleep(1)
            return {
                'success': True,
                'messageId': f'msg-{user_id}',
                'email': email,
                'userId': user_id,
                'mode': 'local-simulated'
            }
        
        from_email = os.getenv('SENDGRID_FROM_EMAIL', 'noreply@yourapp.com')
        logger.info(f"Sending email via SendGrid to {email}")
        
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
        
        loop = asyncio.get_event_loop()
        sg = SendGridAPIClient(sendgrid_api_key)
        response = await loop.run_in_executor(None, sg.send, message)
        logger.info(f"Email sent. Status: {response.status_code}")
        
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
                logger.warning(f"Could not update Firestore: {str(e)}", exc_info=True)
        
        mode = 'gcp-sendgrid' if USE_GCP else 'local-sendgrid'
        return {
            'success': True,
            'messageId': f'msg-{user_id}',
            'email': email,
            'userId': user_id,
            'statusCode': response.status_code,
            'mode': mode
        }
    except Exception as e:
        logger.error(f"Error sending email for {user_id}: {str(e)}", exc_info=True)
        return {
            'success': False,
            'error': str(e),
            'email': email,
            'userId': user_id
        }


class EmailService:
    def __init__(self):
        logger.info(f"Initializing EmailService ({'GCP' if USE_GCP else 'Local'})")
        if USE_GCP:
            self._init_gcp()
        else:
            self._init_local()
    
    def _init_gcp(self):
        try:
            self.tasks_client = tasks_v2.CloudTasksClient()
            self.project_id = os.getenv('GCP_PROJECT_ID', 'demo-project')
            self.location = os.getenv('GCP_LOCATION', 'us-central1')
            self.queue_name = os.getenv('GCP_QUEUE_NAME', 'email-queue')
            
            logger.info(f"GCP config - Project: {self.project_id}, Location: {self.location}, Queue: {self.queue_name}")
            
            parent = self.tasks_client.queue_path(
                self.project_id, 
                self.location, 
                self.queue_name
            )
            self.queue_path = parent
            
            self.email_handler_url = os.getenv(
                'EMAIL_HANDLER_URL',
                'https://your-region-your-project.cloudfunctions.net/send-email'
            )
            logger.info("GCP Cloud Tasks initialized")
        except Exception as e:
            logger.warning(f"GCP init failed, falling back to local: {str(e)}", exc_info=True)
            self._init_local()
            global USE_GCP, LOCAL_MODE
            USE_GCP = False
            LOCAL_MODE = True
    
    def _init_local(self):
        self.task_queue = asyncio.Queue()
        self._background_task = None
        logger.info("Local mode initialized")
    
    async def queue_email(self, user_id: str, email: str) -> str:
        logger.info(f"Queueing email for user {user_id}")
        try:
            if USE_GCP and hasattr(self, 'tasks_client'):
                return self._queue_gcp_task(user_id, email)
            else:
                return await self._queue_local_task(user_id, email)
        except Exception as e:
            logger.error(f"Failed to queue email for {user_id}: {str(e)}", exc_info=True)
            raise Exception(f"Failed to queue email task: {str(e)}")
    
    def _queue_gcp_task(self, user_id: str, email: str) -> str:
        logger.info(f"Creating Cloud Task for {user_id}")
        
        task_payload = {
            'userId': user_id,
            'email': email
        }
        
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
        
        response = self.tasks_client.create_task(
            request={
                'parent': self.queue_path,
                'task': task
            }
        )
        
        logger.info(f"Cloud Task created: {response.name}")
        return response.name
    
    async def _queue_local_task(self, user_id: str, email: str) -> str:
        import time
        
        start_time = time.time()
        min_delay = float(os.getenv('EMAIL_MIN_DELAY_SECONDS', '1.0'))
        
        task_id = f'task-{user_id}-{email}'
        asyncio.create_task(send_email_task(user_id, email))
        
        elapsed_time = time.time() - start_time
        if elapsed_time < min_delay:
            await asyncio.sleep(min_delay - elapsed_time)
        
        logger.info(f"Local task queued: {task_id}")
        return task_id
