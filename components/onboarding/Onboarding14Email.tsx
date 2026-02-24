import { useState } from 'react';
import { useNavigate } from 'react-router';
import OnboardingProgress from './OnboardingProgress';
import { Mail, Apple } from 'lucide-react';

export default function Onboarding14Email() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');

  const handleContinue = () => {
    if (email && email.includes('@')) {
      navigate('/onboarding/notifications');
    }
  };

  const handleGoogleLogin = () => {
    // Mock Google login
    navigate('/onboarding/notifications');
  };

  const handleAppleLogin = () => {
    // Mock Apple login
    navigate('/onboarding/notifications');
  };

  return (
    <div className="min-h-screen bg-background">
      <OnboardingProgress currentStep={9} totalSteps={14} />

      <div className="pt-24 pb-32 px-6 max-w-md mx-auto">
        <h1 className="text-foreground text-3xl font-bold mb-3">
          What's your email address?
        </h1>
        <p className="text-muted-foreground mb-8">
          Don't worry, we'll just send you a verification code. No spamming, we hate it too, we promise.
        </p>

        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="your@email.com"
          className="w-full bg-card border-2 border-border rounded-2xl px-6 py-5 text-lg text-foreground placeholder:text-muted-foreground focus:outline-none focus:border-primary transition-colors shadow-sm mb-4"
        />

        <button
          onClick={handleContinue}
          disabled={!email || !email.includes('@')}
          className={`w-full rounded-2xl py-4 font-semibold transition-all shadow-md mb-6 ${
            email && email.includes('@')
              ? 'bg-primary text-primary-foreground hover:shadow-lg'
              : 'bg-muted text-muted-foreground cursor-not-allowed'
          }`}
        >
          Send Code
        </button>

        {/* Divider */}
        <div className="flex items-center gap-4 mb-6">
          <div className="flex-1 h-px bg-border" />
          <span className="text-sm text-muted-foreground">or continue with</span>
          <div className="flex-1 h-px bg-border" />
        </div>

        {/* Social Login Buttons */}
        <div className="space-y-3 mb-4">
          <button
            onClick={handleGoogleLogin}
            className="w-full bg-card border-2 border-border rounded-2xl py-4 flex items-center justify-center gap-3 hover:bg-muted transition-colors shadow-sm"
          >
            <svg viewBox="0 0 24 24" className="w-5 h-5">
              <path
                fill="#4285F4"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="#34A853"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="#FBBC05"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
              />
              <path
                fill="#EA4335"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
              />
            </svg>
            <span className="font-medium text-foreground">Continue with Google</span>
          </button>

          <button
            onClick={handleAppleLogin}
            className="w-full bg-foreground text-background rounded-2xl py-4 flex items-center justify-center gap-3 hover:bg-foreground/90 transition-colors shadow-sm"
          >
            <Apple className="w-5 h-5" />
            <span className="font-medium">Continue with Apple</span>
          </button>
        </div>

        <p className="text-sm text-muted-foreground text-center">
          You can opt out at any time
        </p>
      </div>
    </div>
  );
}