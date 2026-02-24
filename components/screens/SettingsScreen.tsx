import { ArrowLeft, Moon, Sun, Bell, User, Lock, HelpCircle, Info, ChevronRight, Download, Trash2 } from 'lucide-react';
import { Link } from 'react-router';
import { useState } from 'react';
import { useTheme } from '../ThemeContext';

export default function SettingsScreen() {
  const { theme, toggleTheme } = useTheme();
  const [notifications, setNotifications] = useState(true);
  const [workoutReminders, setWorkoutReminders] = useState(true);
  const [restTimerSound, setRestTimerSound] = useState(true);

  return (
    <div className="min-h-screen bg-background pb-20">
      {/* Header */}
      <div className="bg-card border-b border-border shadow-md">
        <div className="max-w-md mx-auto px-6 pt-12 pb-6">
          <div className="flex items-center gap-3">
            <Link to="/profile" className="p-2 -ml-2 hover:bg-muted rounded-lg transition-colors">
              <ArrowLeft className="w-5 h-5 text-foreground" />
            </Link>
            <h1 className="text-foreground">Settings</h1>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Appearance */}
        <div className="mb-6">
          <h2 className="text-foreground mb-3 text-sm uppercase tracking-wider text-muted-foreground">Appearance</h2>
          <div className="bg-card border border-border rounded-xl shadow-md overflow-hidden">
            <div className="p-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                {theme === 'dark' ? (
                  <Moon className="w-5 h-5 text-primary" />
                ) : (
                  <Sun className="w-5 h-5 text-primary" />
                )}
                <div>
                  <div className="text-foreground font-medium">Dark Mode</div>
                  <div className="text-xs text-muted-foreground">Toggle theme appearance</div>
                </div>
              </div>
              <button
                onClick={toggleTheme}
                className={`relative w-12 h-7 rounded-full transition-colors shadow-inner ${
                  theme === 'dark' ? 'bg-primary' : 'bg-muted'
                }`}
              >
                <div
                  className={`absolute top-1 left-1 w-5 h-5 bg-white rounded-full shadow-md transition-transform ${
                    theme === 'dark' ? 'translate-x-5' : 'translate-x-0'
                  }`}
                />
              </button>
            </div>
          </div>
        </div>

        {/* Notifications */}
        <div className="mb-6">
          <h2 className="text-foreground mb-3 text-sm uppercase tracking-wider text-muted-foreground">Notifications</h2>
          <div className="bg-card border border-border rounded-xl shadow-md overflow-hidden divide-y divide-border">
            <div className="p-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-primary" />
                <div>
                  <div className="text-foreground font-medium">Push Notifications</div>
                  <div className="text-xs text-muted-foreground">Receive app notifications</div>
                </div>
              </div>
              <button
                onClick={() => setNotifications(!notifications)}
                className={`relative w-12 h-7 rounded-full transition-colors shadow-inner ${
                  notifications ? 'bg-primary' : 'bg-muted'
                }`}
              >
                <div
                  className={`absolute top-1 left-1 w-5 h-5 bg-white rounded-full shadow-md transition-transform ${
                    notifications ? 'translate-x-5' : 'translate-x-0'
                  }`}
                />
              </button>
            </div>

            <div className="p-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-secondary" />
                <div>
                  <div className="text-foreground font-medium">Workout Reminders</div>
                  <div className="text-xs text-muted-foreground">Daily workout notifications</div>
                </div>
              </div>
              <button
                onClick={() => setWorkoutReminders(!workoutReminders)}
                className={`relative w-12 h-7 rounded-full transition-colors shadow-inner ${
                  workoutReminders ? 'bg-primary' : 'bg-muted'
                }`}
              >
                <div
                  className={`absolute top-1 left-1 w-5 h-5 bg-white rounded-full shadow-md transition-transform ${
                    workoutReminders ? 'translate-x-5' : 'translate-x-0'
                  }`}
                />
              </button>
            </div>

            <div className="p-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-accent" />
                <div>
                  <div className="text-foreground font-medium">Rest Timer Sound</div>
                  <div className="text-xs text-muted-foreground">Sound when rest is complete</div>
                </div>
              </div>
              <button
                onClick={() => setRestTimerSound(!restTimerSound)}
                className={`relative w-12 h-7 rounded-full transition-colors shadow-inner ${
                  restTimerSound ? 'bg-primary' : 'bg-muted'
                }`}
              >
                <div
                  className={`absolute top-1 left-1 w-5 h-5 bg-white rounded-full shadow-md transition-transform ${
                    restTimerSound ? 'translate-x-5' : 'translate-x-0'
                  }`}
                />
              </button>
            </div>
          </div>
        </div>

        {/* Account */}
        <div className="mb-6">
          <h2 className="text-foreground mb-3 text-sm uppercase tracking-wider text-muted-foreground">Account</h2>
          <div className="bg-card border border-border rounded-xl shadow-md overflow-hidden divide-y divide-border">
            <Link to="/profile/edit" className="p-4 flex items-center justify-between hover:bg-muted/50 transition-colors">
              <div className="flex items-center gap-3">
                <User className="w-5 h-5 text-primary" />
                <div className="text-foreground font-medium">Edit Profile</div>
              </div>
              <ChevronRight className="w-5 h-5 text-muted-foreground" />
            </Link>

            <button className="w-full p-4 flex items-center justify-between hover:bg-muted/50 transition-colors">
              <div className="flex items-center gap-3">
                <Lock className="w-5 h-5 text-secondary" />
                <div className="text-foreground font-medium">Privacy & Security</div>
              </div>
              <ChevronRight className="w-5 h-5 text-muted-foreground" />
            </button>
          </div>
        </div>

        {/* Data */}
        <div className="mb-6">
          <h2 className="text-foreground mb-3 text-sm uppercase tracking-wider text-muted-foreground">Data</h2>
          <div className="bg-card border border-border rounded-xl shadow-md overflow-hidden divide-y divide-border">
            <button className="w-full p-4 flex items-center justify-between hover:bg-muted/50 transition-colors">
              <div className="flex items-center gap-3">
                <Download className="w-5 h-5 text-accent" />
                <div className="text-foreground font-medium">Export Data</div>
              </div>
              <ChevronRight className="w-5 h-5 text-muted-foreground" />
            </button>

            <button className="w-full p-4 flex items-center justify-between hover:bg-muted/50 transition-colors">
              <div className="flex items-center gap-3">
                <Trash2 className="w-5 h-5 text-red-500" />
                <div className="text-red-500 font-medium">Clear All Data</div>
              </div>
              <ChevronRight className="w-5 h-5 text-muted-foreground" />
            </button>
          </div>
        </div>

        {/* Support */}
        <div className="mb-6">
          <h2 className="text-foreground mb-3 text-sm uppercase tracking-wider text-muted-foreground">Support</h2>
          <div className="bg-card border border-border rounded-xl shadow-md overflow-hidden divide-y divide-border">
            <button className="w-full p-4 flex items-center justify-between hover:bg-muted/50 transition-colors">
              <div className="flex items-center gap-3">
                <HelpCircle className="w-5 h-5 text-primary" />
                <div className="text-foreground font-medium">Help & FAQ</div>
              </div>
              <ChevronRight className="w-5 h-5 text-muted-foreground" />
            </button>

            <button className="w-full p-4 flex items-center justify-between hover:bg-muted/50 transition-colors">
              <div className="flex items-center gap-3">
                <Info className="w-5 h-5 text-secondary" />
                <div className="text-foreground font-medium">About GymRatz</div>
              </div>
              <ChevronRight className="w-5 h-5 text-muted-foreground" />
            </button>
          </div>
        </div>

        {/* App Version */}
        <div className="text-center text-muted-foreground text-sm">
          <p>GymRatz v1.0.0</p>
          <p className="text-xs mt-1">Made with 💪 for fitness enthusiasts</p>
        </div>
      </div>
    </div>
  );
}
