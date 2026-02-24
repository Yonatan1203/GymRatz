import { useState } from 'react';
import { useNavigate } from 'react-router';
import OnboardingProgress from './OnboardingProgress';
import { Check } from 'lucide-react';

export default function Onboarding10Injury() {
  const navigate = useNavigate();
  const [selected, setSelected] = useState<string[]>([]);

  const injuries = [
    { id: 'none', label: 'No injuries' },
    { id: 'shoulder', label: 'Shoulder' },
    { id: 'back', label: 'Back' },
    { id: 'knee', label: 'Knee' },
    { id: 'other', label: 'Other (tell us later)' },
  ];

  const toggleSelection = (id: string) => {
    if (id === 'none') {
      setSelected(['none']);
    } else {
      setSelected((prev) => {
        const filtered = prev.filter((item) => item !== 'none');
        return filtered.includes(id)
          ? filtered.filter((item) => item !== id)
          : [...filtered, id];
      });
    }
  };

  const handleContinue = () => {
    if (selected.length > 0) {
      navigate('/onboarding/units');
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <OnboardingProgress currentStep={4} totalSteps={14} />

      <div className="pt-24 pb-32 px-6 max-w-md mx-auto">
        <h1 className="text-foreground text-3xl font-bold mb-3">
          Any injury history?
        </h1>
        <p className="text-muted-foreground mb-8">
          We'll help you train safely around any limitations
        </p>

        <div className="space-y-3">
          {injuries.map((injury) => (
            <button
              key={injury.id}
              onClick={() => toggleSelection(injury.id)}
              className={`w-full rounded-2xl p-5 flex items-center justify-between transition-all shadow-md ${
                selected.includes(injury.id)
                  ? 'bg-primary/20 border-2 border-primary'
                  : 'bg-card border-2 border-border hover:border-primary/30'
              }`}
            >
              <span className="text-lg font-medium text-foreground">
                {injury.label}
              </span>
              {selected.includes(injury.id) && (
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
            disabled={selected.length === 0}
            className={`w-full rounded-2xl py-4 font-semibold transition-all shadow-md ${
              selected.length > 0
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