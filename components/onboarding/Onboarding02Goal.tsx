import { useState } from 'react';
import { useNavigate } from 'react-router';
import OnboardingProgress from './OnboardingProgress';
import { Check } from 'lucide-react';

export default function Onboarding02Goal() {
  const navigate = useNavigate();
  const [selected, setSelected] = useState<string | null>(null);

  const goals = [
    { id: 'muscle', emoji: '💪', label: 'Build Muscle' },
    { id: 'fat', emoji: '🔥', label: 'Lose Fat' },
    { id: 'strength', emoji: '🏋️', label: 'Get Stronger' },
    { id: 'endurance', emoji: '🏃', label: 'Improve Endurance' },
  ];

  const handleContinue = () => {
    if (selected) {
      navigate('/onboarding/experience');
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <OnboardingProgress currentStep={1} totalSteps={14} />

      <div className="pt-24 pb-32 px-6 max-w-md mx-auto">
        <h1 className="text-foreground text-3xl font-bold mb-3">
          What's your main fitness goal?
        </h1>
        <p className="text-muted-foreground mb-8">
          Choose what resonates with you most
        </p>

        <div className="space-y-3">
          {goals.map((goal) => (
            <button
              key={goal.id}
              onClick={() => setSelected(goal.id)}
              className={`w-full rounded-2xl p-5 flex items-center gap-4 transition-all shadow-md ${
                selected === goal.id
                  ? 'bg-primary/20 border-2 border-primary'
                  : 'bg-card border-2 border-border hover:border-primary/30'
              }`}
            >
              <div className="w-12 h-12 bg-muted rounded-xl flex items-center justify-center text-2xl flex-shrink-0">
                {goal.emoji}
              </div>
              <span className="text-lg font-medium text-foreground flex-1 text-left">
                {goal.label}
              </span>
              {selected === goal.id && (
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