import { useNavigate } from 'react-router';
import OnboardingProgress from './OnboardingProgress';
import { Target, TrendingUp, Dumbbell } from 'lucide-react';

export default function Onboarding13Summary() {
  const navigate = useNavigate();

  const summary = [
    { icon: Target, label: 'Goal', value: 'Build Muscle' },
    { icon: TrendingUp, label: 'Experience', value: 'Intermediate' },
    { icon: Dumbbell, label: 'Style', value: 'Strength Training' },
  ];

  const handleContinue = () => {
    navigate('/onboarding/email');
  };

  return (
    <div className="min-h-screen bg-background">
      <OnboardingProgress currentStep={8} totalSteps={14} />

      <div className="pt-24 pb-32 px-6 max-w-md mx-auto">
        <h1 className="text-foreground text-3xl font-bold mb-3">
          Perfect! Here's your starter profile:
        </h1>
        <p className="text-muted-foreground mb-8">
          We're ready to build your personalized experience
        </p>

        {/* Summary Cards */}
        <div className="space-y-3 mb-8">
          {summary.map((item, index) => {
            const Icon = item.icon;
            return (
              <div
                key={index}
                className="bg-card border-2 border-primary/20 rounded-2xl p-5 flex items-center gap-4 shadow-md"
              >
                <div className="w-12 h-12 bg-gradient-to-br from-primary to-accent rounded-xl flex items-center justify-center flex-shrink-0 shadow-sm">
                  <Icon className="w-6 h-6 text-white" />
                </div>
                <div className="flex-1">
                  <div className="text-sm text-muted-foreground mb-1">
                    {item.label}
                  </div>
                  <div className="text-lg font-semibold text-foreground">
                    {item.value}
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Additional Info */}
        <div className="bg-primary/10 border border-primary/20 rounded-2xl p-5">
          <p className="text-sm text-foreground text-center">
            🎯 You're all set for a customized workout journey! Let's create your account to save your progress.
          </p>
        </div>
      </div>

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 p-6 bg-background border-t border-border">
        <div className="max-w-md mx-auto">
          <button
            onClick={handleContinue}
            className="w-full bg-primary text-primary-foreground rounded-2xl py-4 font-semibold shadow-md hover:shadow-lg transition-all"
          >
            Create Account
          </button>
        </div>
      </div>
    </div>
  );
}