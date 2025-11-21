import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/config';

export interface UserData {
  email: string;
  firstName: string;
  lastName: string;
}

export interface EmailServiceResponse {
  success: boolean;
  taskId?: string;
  message?: string;
  error?: string;
}

export async function registerUser(userData: UserData): Promise<string> {
  try {
    const userDoc = {
      email: userData.email,
      firstName: userData.firstName,
      lastName: userData.lastName,
      createdAt: serverTimestamp(),
      emailSent: false,
    };

    const docRef = await addDoc(collection(db, 'users'), userDoc);
    return docRef.id;
  } catch (error) {
    console.error('Error registering user:', error);
    const err = error as Error;
    throw new Error(`Failed to register user: ${err.message}`);
  }
}

export async function triggerEmailSending(
  userId: string,
  email: string
): Promise<EmailServiceResponse> {
  try {
    const response = await fetch('http://localhost:5001/api/send-email', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        userId,
        email,
      }),
    });

    if (!response.ok) {
      throw new Error(`Email service error: ${response.statusText}`);
    }

    return await response.json();
  } catch (error) {
    console.error('Error triggering email:', error);
    const err = error as Error;
    throw new Error(`Failed to trigger email: ${err.message}`);
  }
}

