import { ArrowLeft, Camera, Save, Moon, Sun } from 'lucide-react';
import { Link } from 'react-router';
import { useState } from 'react';
import { useTheme } from '../ThemeContext';

export default function EditProfileScreen() {
  const { theme, toggleTheme } = useTheme();
  const [formData, setFormData] = useState({
    name: 'Yonatan Glav',
    email: 'yonatan@gymratz.com',
    weight: '185',
    height: '5\'11"',
    age: '28',
    experience: 'intermediate',
    goal: 'muscle',
    unit: 'imperial',
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  return (
    <div className="min-h-screen bg-background pb-6">
      {/* Header */}
      <div className="bg-gradient-to-br from-primary to-accent text-white shadow-lg sticky top-0 z-10">
        <div className="max-w-md mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <Link to="/profile" className="p-2 -ml-2 hover:bg-white/10 rounded-lg transition-colors">
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <h1 className="text-white text-lg">Edit Profile</h1>
            <button className="p-2 -mr-2 hover:bg-white/10 rounded-lg transition-colors">
              <Save className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Profile Photo */}
        <div className="flex flex-col items-center mb-8">
          <div className="relative mb-3">
            <div className="w-24 h-24 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center shadow-xl">
              <span className="text-3xl font-semibold text-white">YG</span>
            </div>
            <button className="absolute bottom-0 right-0 w-8 h-8 bg-card border-2 border-background rounded-full flex items-center justify-center shadow-lg hover:bg-muted transition-colors">
              <Camera className="w-4 h-4 text-foreground" />
            </button>
          </div>
          <button className="text-sm text-primary font-medium">Change Photo</button>
        </div>

        {/* Personal Information */}
        <div className="mb-6">
          <div className="text-xs font-semibold text-muted-foreground mb-3 tracking-wider">
            PERSONAL INFORMATION
          </div>
          <div className="bg-card border border-border rounded-xl p-5 shadow-lg space-y-4">
            <div>
              <label className="block text-sm font-medium text-foreground mb-2">Full Name</label>
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleChange}
                className="w-full px-4 py-2.5 bg-muted border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-ring text-foreground shadow-sm"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-2">Email</label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                className="w-full px-4 py-2.5 bg-muted border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-ring text-foreground shadow-sm"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-foreground mb-2">Age</label>
                <input
                  type="number"
                  name="age"
                  value={formData.age}
                  onChange={handleChange}
                  className="w-full px-4 py-2.5 bg-muted border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-ring text-foreground shadow-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-foreground mb-2">Height</label>
                <input
                  type="text"
                  name="height"
                  value={formData.height}
                  onChange={handleChange}
                  className="w-full px-4 py-2.5 bg-muted border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-ring text-foreground shadow-sm"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Fitness Profile */}
        <div className="mb-6">
          <div className="text-xs font-semibold text-muted-foreground mb-3 tracking-wider">
            FITNESS PROFILE
          </div>
          <div className="bg-card border border-border rounded-xl p-5 shadow-lg space-y-4">
            <div>
              <label className="block text-sm font-medium text-foreground mb-2">Current Weight</label>
              <div className="flex gap-2">
                <input
                  type="number"
                  name="weight"
                  value={formData.weight}
                  onChange={handleChange}
                  className="flex-1 px-4 py-2.5 bg-muted border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-ring text-foreground shadow-sm"
                />
                <select
                  name="unit"
                  value={formData.unit}
                  onChange={handleChange}
                  className="px-4 py-2.5 bg-muted border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-ring text-foreground shadow-sm"
                >
                  <option value="imperial">lbs</option>
                  <option value="metric">kg</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-2">Experience Level</label>
              <select
                name="experience"
                value={formData.experience}
                onChange={handleChange}
                className="w-full px-4 py-2.5 bg-muted border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-ring text-foreground shadow-sm"
              >
                <option value="beginner">Beginner (0-1 years)</option>
                <option value="intermediate">Intermediate (1-3 years)</option>
                <option value="advanced">Advanced (3+ years)</option>
                <option value="expert">Expert (5+ years)</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-2">Primary Goal</label>
              <select
                name="goal"
                value={formData.goal}
                onChange={handleChange}
                className="w-full px-4 py-2.5 bg-muted border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-ring text-foreground shadow-sm"
              >
                <option value="muscle">Build Muscle</option>
                <option value="strength">Increase Strength</option>
                <option value="endurance">Improve Endurance</option>
                <option value="weight">Lose Weight</option>
                <option value="general">General Fitness</option>
              </select>
            </div>
          </div>
        </div>

        {/* Preferences */}
        <div className="mb-6">
          <div className="text-xs font-semibold text-muted-foreground mb-3 tracking-wider">
            PREFERENCES
          </div>
          <div className="bg-card border border-border rounded-xl overflow-hidden shadow-lg">
            <button className="w-full flex items-center justify-between px-5 py-4 hover:bg-muted/50 transition-colors border-b border-border">
              <div className="text-left">
                <div className="text-sm font-medium text-foreground">Notifications</div>
                <div className="text-xs text-muted-foreground">Workout reminders and updates</div>
              </div>
              <div className="w-11 h-6 bg-primary rounded-full relative shadow-inner">
                <div className="absolute right-0.5 top-0.5 w-5 h-5 bg-white rounded-full shadow-sm"></div>
              </div>
            </button>

            <button className="w-full flex items-center justify-between px-5 py-4 hover:bg-muted/50 transition-colors border-b border-border">
              <div className="text-left">
                <div className="text-sm font-medium text-foreground">Rest Day Reminders</div>
                <div className="text-xs text-muted-foreground">Get notified on scheduled rest days</div>
              </div>
              <div className="w-11 h-6 bg-muted rounded-full relative shadow-inner">
                <div className="absolute left-0.5 top-0.5 w-5 h-5 bg-white rounded-full shadow-sm"></div>
              </div>
            </button>

            <button
              className="w-full flex items-center justify-between px-5 py-4 hover:bg-muted/50 transition-colors"
              onClick={toggleTheme}
            >
              <div className="text-left">
                <div className="text-sm font-medium text-foreground">Dark Mode</div>
                <div className="text-xs text-muted-foreground">Use dark theme</div>
              </div>
              <div className={`w-11 h-6 rounded-full relative shadow-inner ${theme === 'dark' ? 'bg-primary' : 'bg-muted'}`}>
                <div className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow-sm transition-all ${theme === 'dark' ? 'right-0.5' : 'left-0.5'}`}></div>
              </div>
            </button>
          </div>
        </div>

        {/* Save Button */}
        <Link
          to="/profile"
          className="block w-full bg-gradient-to-r from-primary to-accent text-white rounded-xl py-4 font-semibold text-center shadow-lg hover:shadow-xl transition-shadow"
        >
          Save Changes
        </Link>

        {/* Danger Zone */}
        <div className="mt-8 pt-6 border-t border-border">
          <button className="text-sm text-destructive font-medium">
            Delete Account
          </button>
        </div>
      </div>
    </div>
  );
}