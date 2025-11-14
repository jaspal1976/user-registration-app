
import os
import json
import functions_framework
from google.cloud import firestore
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from email_template import get_welcome_email_html


@functions_framework.http
def send_email(request):
    
    try:
        # Parse request payload
        payload = request.get_json()
        if not payload:
            return {'error': 'No payload provided'}, 400
        
        user_id = payload.get('userId')
        email = payload.get('email')
        
        if not user_id or not email:
            return {'error': 'userId and email are required'}, 400
        
        # Get SendGrid API key
        sendgrid_api_key = os.environ.get('SENDGRID_API_KEY')
        if not sendgrid_api_key:
            return {'error': 'SENDGRID_API_KEY not configured'}, 500
        
        # Prepare email
        from_email = os.environ.get('SENDGRID_FROM_EMAIL', 'noreply@yourapp.com')
        
        message = Mail(
            from_email=from_email,
            to_emails=email,
            subject='Welcome to Our App!',
            html_content=get_welcome_email_html(user_id)
        )
        
        # Send email
        sg = SendGridAPIClient(sendgrid_api_key)
        response = sg.send(message)
        
        # Update Firestore
        db = firestore.Client()
        user_ref = db.collection('users').document(user_id)
        user_ref.update({
            'emailSent': True,
            'emailSentAt': firestore.SERVER_TIMESTAMP,
            'emailMessageId': str(response.status_code)
        })
        
        return {
            'success': True,
            'messageId': f'msg-{user_id}',
            'statusCode': response.status_code
        }, 200
        
    except Exception as e:
        print(f"Error sending email: {str(e)}")
        return {'error': str(e)}, 500

