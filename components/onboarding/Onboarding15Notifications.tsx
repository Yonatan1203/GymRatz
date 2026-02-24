import { useState } from 'react';
import { useNavigate } from 'react-router';
import OnboardingProgress from './OnboardingProgress';
import { Check, Bell, Sparkles } from 'lucide-react';

export default function Onboarding15Notifications() {
  const navigate = useNavigate();
  const [selected, setSelected] = useState<string[]>([]);

  const notifications = [
    { id: 'features', icon: Sparkles, label: 'New feature announcements' },
    { id: 'reminders', icon: Bell, label: 'Workout reminders & tips' },
  ];

  const toggleSelection = (id: string) => {
    setSelected((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  const handleYes = () => {
    navigate('/onboarding/health');
  };

  const handleNo = () => {
    setSelected([]);
    navigate('/onboarding/health');
  };

  return (
    <div className="min-h-screen bg-background">
      <OnboardingProgress currentStep={10} totalSteps={14} />

      <div className="pt-24 pb-32 px-6 max-w-md mx-auto">
        <h1 className="text-foreground text-3xl font-bold mb-3">
          Stay motivated? 📱
        </h1>
        <p className="text-muted-foreground mb-8">
          Get helpful reminders and updates
        </p>

        <div className="space-y-3 mb-8">
          {notifications.map((notif) => {
            const Icon = notif.icon;
            return (
              <button
                key={notif.id}
                onClick={() => toggleSelection(notif.id)}
                className={`w-full rounded-2xl p-5 flex items-center gap-4 transition-all shadow-md ${
                  selected.includes(notif.id)
                    ? 'bg-primary/20 border-2 border-primary'
                    : 'bg-card border-2 border-border hover:border-primary/30'
                }`}
              >
                <div className="w-12 h-12 bg-muted rounded-xl flex items-center justify-center flex-shrink-0">
                  <Icon className="w-6 h-6 text-foreground" />
                </div>
                <span className="text-lg font-medium text-foreground flex-1 text-left">
                  {notif.label}
                </span>
                {selected.includes(notif.id) && (
                  <Check className="w-6 h-6 text-primary" />
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Fixed Bottom Buttons */}
      <div className="fixed bottom-0 left-0 right-0 p-6 bg-background border-t border-border">
        <div className="max-w-md mx-auto space-y-3">
          <button
            onClick={handleYes}
            className="w-full bg-primary text-primary-foreground rounded-2xl py-4 font-semibold shadow-md hover:shadow-lg transition-all"
          >
            Sure!
          </button>
          <button
            onClick={handleNo}
            className="w-full bg-card border-2 border-border text-foreground rounded-2xl py-4 font-semibold hover:bg-muted transition-colors"
          >
            No thank you :(
          </button>
        </div>
      </div>
    </div>
  );
}