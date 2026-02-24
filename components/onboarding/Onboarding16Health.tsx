import { useState } from 'react';
import { useNavigate } from 'react-router';
import OnboardingProgress from './OnboardingProgress';
import { Heart, Check } from 'lucide-react';

export default function Onboarding16Health() {
  const navigate = useNavigate();
  const [enabled, setEnabled] = useState(false);

  const benefits = [
    'Auto log workouts',
    'Sync steps & heart rate',
    'Unified fitness data',
  ];

  const handleContinue = () => {
    navigate('/onboarding/showcase');
  };

  return (
    <div className="min-h-screen bg-background">
      <OnboardingProgress currentStep={11} totalSteps={14} />

      <div className="pt-24 pb-32 px-6 max-w-md mx-auto">
        <h1 className="text-foreground text-3xl font-bold mb-3">
          Connect Apple Health?
        </h1>
        <p className="text-muted-foreground mb-8">
          Sync your fitness data for a complete picture
        </p>

        {/* Toggle */}
        <div className="bg-card border-2 border-border rounded-2xl p-6 mb-6 shadow-md">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-gradient-to-br from-red-500 to-pink-500 rounded-xl flex items-center justify-center shadow-sm">
                <Heart className="w-6 h-6 text-white" />
              </div>
              <span className="text-lg font-semibold text-foreground">
                Apple Health
              </span>
            </div>
            <button
              onClick={() => setEnabled(!enabled)}
              className={`w-14 h-8 rounded-full transition-colors relative ${
                enabled ? 'bg-primary' : 'bg-muted'
              }`}
            >
              <div
                className={`absolute top-1 w-6 h-6 bg-white rounded-full shadow-md transition-transform ${
                  enabled ? 'translate-x-7' : 'translate-x-1'
                }`}
              />
            </button>
          </div>

          {/* Benefits */}
          <div className="space-y-3">
            {benefits.map((benefit, index) => (
              <div key={index} className="flex items-center gap-3">
                <div className="w-5 h-5 rounded-full bg-primary/20 flex items-center justify-center flex-shrink-0">
                  <Check className="w-3 h-3 text-primary" />
                </div>
                <span className="text-sm text-foreground">{benefit}</span>
              </div>
            ))}
          </div>
        </div>

        <p className="text-xs text-muted-foreground text-center">
          You can change this anytime in Settings
        </p>
      </div>

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 p-6 bg-background border-t border-border">
        <div className="max-w-md mx-auto">
          <button
            onClick={handleContinue}
            className="w-full bg-primary text-primary-foreground rounded-2xl py-4 font-semibold shadow-md hover:shadow-lg transition-all"
          >
            {enabled ? 'Connect' : 'Skip for now'}
          </button>
        </div>
      </div>
    </div>
  );
}