import { describe, it, expect, vi, beforeEach } from 'vitest';
import { registerUser, triggerEmailSending, UserData } from '../userService';
import { collection, addDoc } from 'firebase/firestore';
import { db } from '../../firebase/config';

vi.mock('firebase/app', () => ({
  initializeApp: vi.fn(() => ({})),
}));

vi.mock('firebase/firestore', () => ({
  collection: vi.fn(),
  addDoc: vi.fn(),
  getFirestore: vi.fn(() => ({})),
  connectFirestoreEmulator: vi.fn(),
  serverTimestamp: vi.fn(() => ({ seconds: Date.now() / 1000 })),
}));

vi.mock('firebase/auth', () => ({
  getAuth: vi.fn(() => ({})),
  connectAuthEmulator: vi.fn(),
}));

vi.mock('../../firebase/config', () => ({
  db: {},
  auth: {},
  app: {},
}));

global.fetch = vi.fn() as typeof fetch;

describe('userService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  describe('registerUser', () => {
    it('successfully registers a user', async () => {
      const mockDocRef = { id: 'test-user-id' };
      const mockCollection = {};
      
      (collection as ReturnType<typeof vi.fn>).mockReturnValue(mockCollection);
      (addDoc as ReturnType<typeof vi.fn>).mockResolvedValue(mockDocRef);

      const userData: UserData = {
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
      };

      const userId = await registerUser(userData);

      expect(collection).toHaveBeenCalledWith(db, 'users');
      expect(addDoc).toHaveBeenCalledWith(
        mockCollection,
        expect.objectContaining({
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          emailSent: false,
        })
      );
      expect(userId).toBe('test-user-id');
    });

    it('throws error on registration failure', async () => {
      const error = new Error('Firestore error');
      (collection as ReturnType<typeof vi.fn>).mockReturnValue({});
      (addDoc as ReturnType<typeof vi.fn>).mockRejectedValue(error);

      const userData: UserData = {
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
      };

      await expect(registerUser(userData)).rejects.toThrow(
        'Failed to register user'
      );
    });
  });

  describe('triggerEmailSending', () => {
    it('successfully triggers email sending', async () => {
      const mockResponse = { success: true, messageId: 'msg-123' };
      (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
        ok: true,
        json: async () => mockResponse,
      } as Response);

      const result = await triggerEmailSending('user-id', 'test@example.com');

      expect(global.fetch).toHaveBeenCalledWith('http://localhost:5001/api/send-email', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId: 'user-id',
          email: 'test@example.com',
        }),
      });
      expect(result).toEqual(mockResponse);
    });

    it('throws error on email service failure', async () => {
      (global.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
        ok: false,
        statusText: 'Internal Server Error',
      } as Response);

      await expect(
        triggerEmailSending('user-id', 'test@example.com')
      ).rejects.toThrow('Email service error');
    });

    it('handles network errors', async () => {
      (global.fetch as ReturnType<typeof vi.fn>).mockRejectedValue(
        new Error('Network error')
      );

      await expect(
        triggerEmailSending('user-id', 'test@example.com')
      ).rejects.toThrow('Failed to trigger email');
    });
  });
});

