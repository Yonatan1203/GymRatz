import { useNavigate } from 'react-router';
import OnboardingProgress from './OnboardingProgress';
import { Dumbbell, Trophy, TrendingUp, Users } from 'lucide-react';

export default function Onboarding17Showcase() {
  const navigate = useNavigate();

  const features = [
    {
      icon: Dumbbell,
      title: 'Workout Tracker',
      description: 'Log every rep, set, and RIR',
      color: 'from-primary to-accent',
    },
    {
      icon: Trophy,
      title: 'Challenges',
      description: 'Compete and stay motivated',
      color: 'from-secondary to-yellow-500',
    },
    {
      icon: TrendingUp,
      title: 'Progress Charts',
      description: 'Visualize your gains',
      color: 'from-green-500 to-emerald-500',
    },
    {
      icon: Users,
      title: 'Community Feed',
      description: 'Share and inspire',
      color: 'from-purple-500 to-pink-500',
    },
  ];

  const handleContinue = () => {
    navigate('/onboarding/discovery');
  };

  return (
    <div className="min-h-screen bg-background">
      <OnboardingProgress currentStep={13} totalSteps={14} />

      <div className="pt-24 pb-32 px-6 max-w-md mx-auto">
        <h1 className="text-foreground text-3xl font-bold mb-3">
          Meet GymRatz ✨
        </h1>
        <p className="text-muted-foreground mb-8">
          Everything you need to crush your fitness goals
        </p>

        {/* Vertical Feature Cards */}
        <div className="space-y-4 mb-8">
          {features.map((feature, index) => {
            const Icon = feature.icon;
            return (
              <div
                key={index}
                className="bg-card border-2 border-border rounded-2xl p-6 shadow-md"
              >
                <div className={`w-14 h-14 bg-gradient-to-br ${feature.color} rounded-2xl flex items-center justify-center mb-4 shadow-md`}>
                  <Icon className="w-7 h-7 text-white" />
                </div>
                <h3 className="text-xl font-bold text-foreground mb-2">
                  {feature.title}
                </h3>
                <p className="text-sm text-muted-foreground">
                  {feature.description}
                </p>
              </div>
            );
          })}
        </div>
      </div>

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 p-6 bg-background border-t border-border">
        <div className="max-w-md mx-auto">
          <button
            onClick={handleContinue}
            className="w-full bg-primary text-primary-foreground rounded-2xl py-4 font-semibold shadow-md hover:shadow-lg transition-all"
          >
            Start Crushing It
          </button>
        </div>
      </div>
    </div>
  );
}