import { useState } from 'react';
import { useNavigate } from 'react-router';
import OnboardingProgress from './OnboardingProgress';
import { Check } from 'lucide-react';

export default function Onboarding18Discovery() {
  const navigate = useNavigate();
  const [selected, setSelected] = useState<string | null>(null);

  const sources = [
    { id: 'friend', label: 'Friend recommended' },
    { id: 'social', label: 'TikTok/Instagram' },
    { id: 'appstore', label: 'App Store' },
    { id: 'gym', label: 'Gym ad' },
    { id: 'other', label: 'Other' },
  ];

  const handleContinue = () => {
    if (selected) {
      // Navigate to home after onboarding complete
      navigate('/home');
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <OnboardingProgress currentStep={14} totalSteps={14} />

      <div className="pt-24 pb-32 px-6 max-w-md mx-auto">
        <h1 className="text-foreground text-3xl font-bold mb-3">
          How'd you find GymRatz?
        </h1>
        <p className="text-muted-foreground mb-8">
          We love hearing how people discover us!
        </p>

        <div className="space-y-3">
          {sources.map((source) => (
            <button
              key={source.id}
              onClick={() => setSelected(source.id)}
              className={`w-full rounded-2xl p-5 flex items-center justify-between transition-all shadow-md ${
                selected === source.id
                  ? 'bg-primary/20 border-2 border-primary'
                  : 'bg-card border-2 border-border hover:border-primary/30'
              }`}
            >
              <span className="text-lg font-medium text-foreground">
                {source.label}
              </span>
              {selected === source.id && (
                <Check className="w-6 h-6 text-primary" />
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 p-6 bg-background border-t border-border">
        <div className="max-w-md mx-auto">
          <button
            onClick={handleContinue}
            disabled={!selected}
            className={`w-full rounded-2xl py-4 font-semibold transition-all shadow-md ${
              selected
                ? 'bg-primary text-primary-foreground hover:shadow-lg'
                : 'bg-muted text-muted-foreground cursor-not-allowed'
            }`}
          >
            All Set! 🎉
          </button>
        </div>
      </div>
    </div>
  );
}