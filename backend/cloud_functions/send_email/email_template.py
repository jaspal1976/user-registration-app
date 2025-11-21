def get_welcome_email_html(user_id: str) -> str:
    return f'''
    <html>
        <body>
            <h1>Welcome!</h1>
            <p>Thank you for registering with us!</p>
            <p>Your user ID: {user_id}</p>
            <p>We're excited to have you on board.</p>
        </body>
    </html>
    '''

