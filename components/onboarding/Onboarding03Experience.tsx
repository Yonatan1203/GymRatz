import { useState } from 'react';
import { useNavigate } from 'react-router';
import OnboardingProgress from './OnboardingProgress';
import { Check } from 'lucide-react';

export default function Onboarding03Experience() {
  const navigate = useNavigate();
  const [selected, setSelected] = useState<string | null>(null);

  const levels = [
    {
      id: 'beginner',
      emoji: '👶',
      label: 'Beginner',
      description: 'First time lifting',
    },
    {
      id: 'intermediate',
      emoji: '📈',
      label: 'Intermediate',
      description: 'Consistent 6+ months',
    },
    {
      id: 'advanced',
      emoji: '🥇',
      label: 'Advanced',
      description: 'Lifting 2+ years',
    },
    {
      id: 'elite',
      emoji: '🔥',
      label: 'Elite',
      description: 'Compete or coach',
    },
  ];

  const handleContinue = () => {
    if (selected) {
      navigate('/onboarding/style');
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <OnboardingProgress currentStep={2} totalSteps={14} />

      <div className="pt-24 pb-32 px-6 max-w-md mx-auto">
        <h1 className="text-foreground text-3xl font-bold mb-3">
          How experienced are you?
        </h1>
        <p className="text-muted-foreground mb-8">
          No judgment here, we'll meet you exactly where you are!
        </p>

        <div className="space-y-3">
          {levels.map((level) => (
            <button
              key={level.id}
              onClick={() => setSelected(level.id)}
              className={`w-full rounded-2xl p-5 flex items-center gap-4 transition-all shadow-md ${
                selected === level.id
                  ? 'bg-primary/20 border-2 border-primary'
                  : 'bg-card border-2 border-border hover:border-primary/30'
              }`}
            >
              <div className="w-12 h-12 bg-muted rounded-xl flex items-center justify-center text-2xl flex-shrink-0">
                {level.emoji}
              </div>
              <div className="flex-1 text-left">
                <div className="text-lg font-medium text-foreground">
                  {level.label}
                </div>
                <div className="text-sm text-muted-foreground">
                  {level.description}
                </div>
              </div>
              {selected === level.id && (
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
            Continue
          </button>
        </div>
      </div>
    </div>
  );
}