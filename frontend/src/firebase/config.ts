import { initializeApp, FirebaseApp } from 'firebase/app';
import { getFirestore, Firestore, connectFirestoreEmulator } from 'firebase/firestore';
import { getAuth, Auth, connectAuthEmulator } from 'firebase/auth';

// Firebase configuration for emulator
const firebaseConfig = {
  projectId: 'demo-project',
  apiKey: 'demo-api-key',
  authDomain: 'localhost',
};

// Initialize Firebase
const app: FirebaseApp = initializeApp(firebaseConfig);

// Initialize Firestore
const db: Firestore = getFirestore(app);

// Initialize Auth
const auth: Auth = getAuth(app);

// Connect to emulators in development
if (import.meta.env.DEV) {
  try {
    // Check if emulators are already connected
    const authConfig = (auth as any)._delegate?._config;
    if (!authConfig?.emulator) {
      connectFirestoreEmulator(db, 'localhost', 8080);
      connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true });
    }
  } catch (error) {
    // Emulators already connected or not available
    const err = error as Error;
    console.log('Emulator connection note:', err.message);
  }
}

export { db, auth, app };

