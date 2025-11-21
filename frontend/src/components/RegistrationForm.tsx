import { useState, FormEvent, ChangeEvent } from 'react';
import { registerUser, triggerEmailSending, UserData } from '../services/userService';
import './RegistrationForm.css';

interface FormErrors {
  email?: string;
  firstName?: string;
  lastName?: string;
}

interface SubmitStatus {
  type: 'success' | 'error';
  message: string;
}

export default function RegistrationForm(): JSX.Element {
  const [formData, setFormData] = useState<UserData>({
    email: '',
    firstName: '',
    lastName: '',
  });
  const [errors, setErrors] = useState<FormErrors>({});
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [submitStatus, setSubmitStatus] = useState<SubmitStatus | null>(null);

  const validateEmail = (email: string): boolean => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {};

    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!validateEmail(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    if (!formData.firstName.trim()) {
      newErrors.firstName = 'First name is required';
    }

    if (!formData.lastName.trim()) {
      newErrors.lastName = 'Last name is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleChange = (e: ChangeEvent<HTMLInputElement>): void => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
    
    if (errors[name as keyof FormErrors]) {
      setErrors((prev) => ({
        ...prev,
        [name]: '',
      }));
    }
  };

  const handleSubmit = async (e: FormEvent<HTMLFormElement>): Promise<void> => {
    e.preventDefault();
    setSubmitStatus(null);

    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);

    try {
      const userId = await registerUser(formData);
      await triggerEmailSending(userId, formData.email);

      setSubmitStatus({
        type: 'success',
        message: 'Registration successful! A confirmation email will be sent shortly.',
      });

      // Reset form
      setFormData({
        email: '',
        firstName: '',
        lastName: '',
      });
    } catch (error) {
      console.error('Registration error:', error);
      const err = error as Error;
      setSubmitStatus({
        type: 'error',
        message: err.message || 'Registration failed. Please try again.',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="registration-container">
      <div className="registration-card">
        <h1 className="registration-title">Create Your Account</h1>
        <p className="registration-subtitle">
          Fill in your details to get started
        </p>

        <form onSubmit={handleSubmit} className="registration-form" noValidate>
          <div className="form-group">
            <label htmlFor="email" className="form-label">
              Email Address *
            </label>
            <input
              type="email"
              id="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              className={`form-input ${errors.email ? 'form-input-error' : ''}`}
              placeholder="you@example.com"
              disabled={isSubmitting}
            />
            {errors.email && (
              <span className="error-message">{errors.email}</span>
            )}
          </div>

          <div className="form-group">
            <label htmlFor="firstName" className="form-label">
              First Name *
            </label>
            <input
              type="text"
              id="firstName"
              name="firstName"
              value={formData.firstName}
              onChange={handleChange}
              className={`form-input ${
                errors.firstName ? 'form-input-error' : ''
              }`}
              placeholder="John"
              disabled={isSubmitting}
            />
            {errors.firstName && (
              <span className="error-message">{errors.firstName}</span>
            )}
          </div>

          <div className="form-group">
            <label htmlFor="lastName" className="form-label">
              Last Name *
            </label>
            <input
              type="text"
              id="lastName"
              name="lastName"
              value={formData.lastName}
              onChange={handleChange}
              className={`form-input ${
                errors.lastName ? 'form-input-error' : ''
              }`}
              placeholder="Doe"
              disabled={isSubmitting}
            />
            {errors.lastName && (
              <span className="error-message">{errors.lastName}</span>
            )}
          </div>

          {submitStatus && (
            <div
              className={`status-message status-${submitStatus.type}`}
              role="alert"
              aria-live="polite"
            >
              {submitStatus.type === 'success' && (
                <span className="success-icon">✓</span>
              )}
              {submitStatus.message}
            </div>
          )}

          <button
            type="submit"
            className="submit-button"
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <>
                <span className="spinner"></span>
                <span>Registering...</span>
              </>
            ) : (
              'Register'
            )}
          </button>
        </form>
      </div>
    </div>
  );
}

