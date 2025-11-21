import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import RegistrationForm from '../RegistrationForm';
import * as userService from '../../services/userService';

vi.mock('../../services/userService', () => ({
  registerUser: vi.fn(),
  triggerEmailSending: vi.fn(),
}));

describe('RegistrationForm', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.spyOn(console, 'log').mockImplementation(() => {});
    vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  it('renders registration form with all fields', () => {
    render(<RegistrationForm />);

    expect(screen.getByLabelText(/email address/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/first name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/last name/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /register/i })).toBeInTheDocument();
  });

  it('shows validation errors for empty fields', async () => {
    const user = userEvent.setup();
    render(<RegistrationForm />);

    const submitButton = screen.getByRole('button', { name: /register/i });
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(/email is required/i)).toBeInTheDocument();
      expect(screen.getByText(/first name is required/i)).toBeInTheDocument();
      expect(screen.getByText(/last name is required/i)).toBeInTheDocument();
    });
  });

  it('validates email format', async () => {
    const user = userEvent.setup();
    render(<RegistrationForm />);

    const emailInput = screen.getByLabelText(/email address/i);
    const firstNameInput = screen.getByLabelText(/first name/i);
    const lastNameInput = screen.getByLabelText(/last name/i);
    
    await user.clear(emailInput);
    await user.type(emailInput, 'invalid-email');
    await user.type(firstNameInput, 'John');
    await user.type(lastNameInput, 'Doe');

    const submitButton = screen.getByRole('button', { name: /register/i });
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText('Please enter a valid email address')).toBeInTheDocument();
    }, { timeout: 3000 });
  });

  it('submits form with valid data', async () => {
    const user = userEvent.setup();
    const mockUserId = 'test-user-id';
    
    (userService.registerUser as ReturnType<typeof vi.fn>).mockResolvedValue(mockUserId);
    (userService.triggerEmailSending as ReturnType<typeof vi.fn>).mockResolvedValue({ 
      success: true 
    });

    render(<RegistrationForm />);

    await user.type(screen.getByLabelText(/email address/i), 'test@example.com');
    await user.type(screen.getByLabelText(/first name/i), 'John');
    await user.type(screen.getByLabelText(/last name/i), 'Doe');

    const submitButton = screen.getByRole('button', { name: /register/i });
    await user.click(submitButton);

    await waitFor(() => {
      expect(userService.registerUser).toHaveBeenCalledWith({
        email: 'test@example.com',
        firstName: 'John',
        lastName: 'Doe',
      });
      expect(userService.triggerEmailSending).toHaveBeenCalledWith(
        mockUserId,
        'test@example.com'
      );
    });

    await waitFor(() => {
      expect(screen.getByText(/registration successful/i)).toBeInTheDocument();
    });
  });

  it('handles registration errors', async () => {
    const user = userEvent.setup();
    const errorMessage = 'Failed to register user';
    
    (userService.registerUser as ReturnType<typeof vi.fn>).mockRejectedValue(
      new Error(errorMessage)
    );

    render(<RegistrationForm />);

    await user.type(screen.getByLabelText(/email address/i), 'test@example.com');
    await user.type(screen.getByLabelText(/first name/i), 'John');
    await user.type(screen.getByLabelText(/last name/i), 'Doe');

    const submitButton = screen.getByRole('button', { name: /register/i });
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(/failed to register user/i)).toBeInTheDocument();
    });
  });

  it('disables form during submission', async () => {
    const user = userEvent.setup();
    let resolveRegister: (value: string) => void;
    const registerPromise = new Promise<string>((resolve) => {
      resolveRegister = resolve;
    });
    
    (userService.registerUser as ReturnType<typeof vi.fn>).mockReturnValue(registerPromise);
    (userService.triggerEmailSending as ReturnType<typeof vi.fn>).mockResolvedValue({ 
      success: true 
    });

    render(<RegistrationForm />);

    await user.type(screen.getByLabelText(/email address/i), 'test@example.com');
    await user.type(screen.getByLabelText(/first name/i), 'John');
    await user.type(screen.getByLabelText(/last name/i), 'Doe');

    const submitButton = screen.getByRole('button', { name: /register/i });
    await user.click(submitButton);

    await waitFor(() => {
      expect(submitButton).toBeDisabled();
      expect(submitButton).toHaveTextContent(/registering/i);
    });

    resolveRegister!('test-user-id');
  });
});

