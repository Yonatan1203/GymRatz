import { Heart, Dumbbell, NotebookPen, TrendingUp, Library, Users, ChevronRight, Settings, Award, Target, Edit, Trophy, Share2 } from 'lucide-react';
import { Link } from 'react-router';

export default function ProfileScreen() {
  const personalRecords = [
    { exercise: 'Barbell Bench Press', weight: 225, unit: 'lbs', date: 'Feb 10, 2026' },
    { exercise: 'Barbell Squat', weight: 315, unit: 'lbs', date: 'Feb 8, 2026' },
    { exercise: 'Deadlift', weight: 405, unit: 'lbs', date: 'Feb 5, 2026' },
  ];

  const sharePR = (pr: typeof personalRecords[0]) => {
    const text = `💪 New PR in GymRatz! ${pr.exercise}: ${pr.weight} ${pr.unit} 🎯`;
    if (navigator.share) {
      navigator.share({
        title: 'GymRatz Personal Record',
        text: text,
      }).catch(() => {});
    } else {
      navigator.clipboard.writeText(text);
      alert('PR copied to clipboard!');
    }
  };

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="bg-card border-b border-border shadow-md">
        <div className="max-w-md mx-auto px-6 pt-12 pb-6">
          <div className="flex items-center justify-between mb-6">
            <h1 className="text-foreground">Profile</h1>
            <Link to="/profile/edit" className="p-2 hover:bg-muted rounded-lg transition-colors shadow-sm">
              <Edit className="w-5 h-5 text-muted-foreground" />
            </Link>
          </div>
          
          {/* User Info */}
          <div className="flex flex-col items-center mb-6">
            <div className="w-24 h-24 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center mb-4 shadow-xl">
              <span className="text-3xl font-semibold text-white">YG</span>
            </div>
            <h2 className="mb-1">Yonatan Glav</h2>
            <p className="text-sm text-muted-foreground">Fitness Enthusiast</p>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-3 gap-3 mb-6">
            <div className="bg-muted rounded-lg p-4 text-center shadow-md">
              <div className="flex justify-center mb-2">
                <Target className="w-5 h-5 text-primary" />
              </div>
              <div className="text-xl font-semibold text-foreground">24</div>
              <div className="text-xs text-muted-foreground">Workouts</div>
            </div>
            <div className="bg-muted rounded-lg p-4 text-center shadow-md">
              <div className="flex justify-center mb-2">
                <TrendingUp className="w-5 h-5 text-accent" />
              </div>
              <div className="text-xl font-semibold text-foreground">12</div>
              <div className="text-xs text-muted-foreground">Streak</div>
            </div>
            <div className="bg-muted rounded-lg p-4 text-center shadow-md">
              <div className="flex justify-center mb-2">
                <Award className="w-5 h-5 text-secondary" />
              </div>
              <div className="text-xl font-semibold text-foreground">8</div>
              <div className="text-xs text-muted-foreground">Badges</div>
            </div>
          </div>

          {/* Invite Friends Card */}
          <div className="bg-gradient-to-r from-primary to-accent rounded-xl p-4 mb-6 shadow-lg">
            <div className="flex items-center justify-between text-white">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-white/20 rounded-lg flex items-center justify-center shadow-md">
                  <Users className="w-5 h-5" />
                </div>
                <div>
                  <div className="font-medium">Invite Your Friends</div>
                  <div className="text-xs text-white/80">Earn rewards together</div>
                </div>
              </div>
              <ChevronRight className="w-5 h-5" />
            </div>
          </div>
        </div>
      </div>

      {/* Menu Sections */}
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Personal Records */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-3">
            <div className="text-xs font-semibold text-muted-foreground tracking-wider">
              PERSONAL RECORDS
            </div>
            <Link to="/progress" className="text-xs text-primary font-medium">View All</Link>
          </div>
          <div className="space-y-2">
            {personalRecords.map((pr, index) => (
              <div key={index} className="bg-card border border-border rounded-xl p-4 shadow-md hover:shadow-lg transition-shadow relative">
                <button
                  onClick={() => sharePR(pr)}
                  className="absolute top-3 right-3 p-2 bg-muted rounded-lg hover:bg-muted/80 transition-colors shadow-sm"
                >
                  <Share2 className="w-4 h-4 text-primary" />
                </button>
                <div className="flex items-start gap-3 pr-10">
                  <div className="w-10 h-10 bg-gradient-to-br from-primary to-accent rounded-lg flex items-center justify-center flex-shrink-0 shadow-sm">
                    <Trophy className="w-5 h-5 text-white" />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-foreground font-medium text-sm mb-1">{pr.exercise}</h3>
                    <p className="text-xs text-muted-foreground mb-2">{pr.date}</p>
                    <div className="flex items-baseline gap-1">
                      <span className="text-2xl font-semibold text-primary">{pr.weight}</span>
                      <span className="text-sm text-muted-foreground">{pr.unit}</span>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Workouts & Training */}
        <div className="mb-6">
          <div className="text-xs font-semibold text-muted-foreground mb-3 tracking-wider">
            WORKOUTS & TRAINING
          </div>
          <div className="bg-card border border-border rounded-xl overflow-hidden shadow-lg">
            <MenuItem icon={<Heart className="w-5 h-5" />} label="Favorites" to="/favorites" />
            <MenuItem icon={<Dumbbell className="w-5 h-5" />} label="My Workout Plans" showBadge="3" to="/programs" />
            <MenuItem icon={<NotebookPen className="w-5 h-5" />} label="Workout Logs" to="/today" />
            <MenuItem icon={<TrendingUp className="w-5 h-5" />} label="Workout Statistics" to="/progress" />
            <MenuItem icon={<Library className="w-5 h-5" />} label="Exercise Library" to="/exercises" isLast />
          </div>
        </div>

        {/* Account Settings */}
        <div className="mb-6">
          <div className="text-xs font-semibold text-muted-foreground mb-3 tracking-wider">
            ACCOUNT
          </div>
          <div className="bg-card border border-border rounded-xl overflow-hidden shadow-lg">
            <MenuItem icon={<Settings className="w-5 h-5" />} label="Settings & Privacy" to="/settings" />
            <MenuItem icon={<Award className="w-5 h-5" />} label="Achievements" to="/achievements" isLast />
          </div>
        </div>
      </div>
    </div>
  );
}

function MenuItem({ icon, label, showBadge, isLast, to }: { icon: React.ReactNode; label: string; showBadge?: string; isLast?: boolean; to: string }) {
  return (
    <Link to={to} className={`w-full flex items-center justify-between px-4 py-4 hover:bg-muted/50 transition-colors ${!isLast ? 'border-b border-border' : ''}`}>
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 bg-muted rounded-lg flex items-center justify-center text-foreground shadow-sm">
          {icon}
        </div>
        <span className="text-foreground font-medium">{label}</span>
      </div>
      <div className="flex items-center gap-2">
        {showBadge && (
          <span className="bg-primary text-primary-foreground text-xs font-semibold px-2 py-1 rounded-full shadow-md">
            {showBadge}
          </span>
        )}
        <ChevronRight className="w-5 h-5 text-muted-foreground" />
      </div>
    </Link>
  );
}