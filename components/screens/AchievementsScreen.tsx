import { ArrowLeft, Trophy, Star, Target, Flame, Award, TrendingUp, Calendar, Dumbbell, Lock, Share2 } from 'lucide-react';
import { Link } from 'react-router';
import { useState } from 'react';

interface Achievement {
  id: number;
  title: string;
  description: string;
  icon: any;
  progress: number;
  total: number;
  unlocked: boolean;
  unlockedDate?: string;
  rarity: 'Common' | 'Rare' | 'Epic' | 'Legendary';
  points: number;
}

export default function AchievementsScreen() {
  const [selectedTab, setSelectedTab] = useState<'all' | 'unlocked' | 'locked'>('all');

  const achievements: Achievement[] = [
    {
      id: 1,
      title: 'First Steps',
      description: 'Complete your first workout',
      icon: Target,
      progress: 1,
      total: 1,
      unlocked: true,
      unlockedDate: '2024-01-15',
      rarity: 'Common',
      points: 10,
    },
    {
      id: 2,
      title: 'Week Warrior',
      description: 'Complete 7 consecutive workouts',
      icon: Flame,
      progress: 7,
      total: 7,
      unlocked: true,
      unlockedDate: '2024-01-22',
      rarity: 'Rare',
      points: 25,
    },
    {
      id: 3,
      title: 'Strength Master',
      description: 'Bench press 225 lbs',
      icon: Dumbbell,
      progress: 185,
      total: 225,
      unlocked: false,
      rarity: 'Epic',
      points: 50,
    },
    {
      id: 4,
      title: 'Consistency King',
      description: 'Workout 30 days in a month',
      icon: Calendar,
      progress: 18,
      total: 30,
      unlocked: false,
      rarity: 'Legendary',
      points: 100,
    },
    {
      id: 5,
      title: 'Volume Veteran',
      description: 'Complete 1,000 total reps',
      icon: TrendingUp,
      progress: 1000,
      total: 1000,
      unlocked: true,
      unlockedDate: '2024-02-01',
      rarity: 'Rare',
      points: 30,
    },
    {
      id: 6,
      title: 'Program Pioneer',
      description: 'Finish a 12-week program',
      icon: Award,
      progress: 6,
      total: 12,
      unlocked: false,
      rarity: 'Epic',
      points: 75,
    },
    {
      id: 7,
      title: 'Early Bird',
      description: 'Complete 10 morning workouts (before 8am)',
      icon: Star,
      progress: 3,
      total: 10,
      unlocked: false,
      rarity: 'Common',
      points: 15,
    },
    {
      id: 8,
      title: 'Iron Collector',
      description: 'Log workouts with 10 different exercises',
      icon: Trophy,
      progress: 10,
      total: 10,
      unlocked: true,
      unlockedDate: '2024-01-28',
      rarity: 'Common',
      points: 20,
    },
    {
      id: 9,
      title: '100 Club',
      description: 'Complete 100 total workouts',
      icon: Trophy,
      progress: 42,
      total: 100,
      unlocked: false,
      rarity: 'Legendary',
      points: 150,
    },
    {
      id: 10,
      title: 'PR Crusher',
      description: 'Set 25 personal records',
      icon: TrendingUp,
      progress: 12,
      total: 25,
      unlocked: false,
      rarity: 'Epic',
      points: 60,
    },
  ];

  const totalPoints = achievements.filter(a => a.unlocked).reduce((sum, a) => sum + a.points, 0);
  const unlockedCount = achievements.filter(a => a.unlocked).length;

  const filteredAchievements = achievements.filter(achievement => {
    if (selectedTab === 'unlocked') return achievement.unlocked;
    if (selectedTab === 'locked') return !achievement.unlocked;
    return true;
  });

  const getRarityColor = (rarity: Achievement['rarity']) => {
    switch (rarity) {
      case 'Common': return 'text-muted-foreground bg-muted';
      case 'Rare': return 'text-accent bg-accent/20';
      case 'Epic': return 'text-primary bg-primary/20';
      case 'Legendary': return 'text-secondary bg-secondary/20';
    }
  };

  const shareAchievement = (achievement: Achievement) => {
    const text = `🏆 Just unlocked "${achievement.title}" in GymRatz! ${achievement.description} (+${achievement.points} points)`;
    if (navigator.share) {
      navigator.share({
        title: 'GymRatz Achievement',
        text: text,
      }).catch(() => {});
    } else {
      navigator.clipboard.writeText(text);
      alert('Achievement copied to clipboard!');
    }
  };

  return (
    <div className="min-h-screen bg-background pb-20">
      {/* Header */}
      <div className="bg-gradient-to-br from-primary to-accent text-white shadow-lg">
        <div className="max-w-md mx-auto px-6 pt-12 pb-6">
          <div className="flex items-center gap-3 mb-4">
            <Link to="/profile" className="p-2 -ml-2 hover:bg-white/10 rounded-lg transition-colors">
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <h1 className="text-white">Achievements</h1>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-3 mt-6">
            <div className="bg-white/10 rounded-lg p-3 text-center shadow-md">
              <div className="text-2xl font-semibold">{unlockedCount}</div>
              <div className="text-xs text-white/80">Unlocked</div>
            </div>
            <div className="bg-white/10 rounded-lg p-3 text-center shadow-md">
              <div className="text-2xl font-semibold">{achievements.length}</div>
              <div className="text-xs text-white/80">Total</div>
            </div>
            <div className="bg-white/10 rounded-lg p-3 text-center shadow-md">
              <div className="text-2xl font-semibold">{totalPoints}</div>
              <div className="text-xs text-white/80">Points</div>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="bg-card border-b border-border shadow-sm sticky top-0 z-10">
        <div className="max-w-md mx-auto px-6">
          <div className="flex gap-4 -mb-px">
            {['all', 'unlocked', 'locked'].map((tab) => (
              <button
                key={tab}
                onClick={() => setSelectedTab(tab as typeof selectedTab)}
                className={`py-3 px-1 font-medium text-sm capitalize transition-colors relative ${
                  selectedTab === tab
                    ? 'text-primary'
                    : 'text-muted-foreground hover:text-foreground'
                }`}
              >
                {tab}
                {selectedTab === tab && (
                  <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary" />
                )}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-md mx-auto px-6 py-6">
        <div className="space-y-3">
          {filteredAchievements.map((achievement) => {
            const Icon = achievement.icon;
            const progressPercent = (achievement.progress / achievement.total) * 100;

            return (
              <div
                key={achievement.id}
                className={`bg-card border border-border rounded-xl p-4 shadow-md transition-all relative ${ 
                  achievement.unlocked ? 'opacity-100' : 'opacity-75'
                }`}
              >
                {/* Share Button */}
                {achievement.unlocked && (
                  <button
                    className="absolute bottom-4 right-4 p-2 bg-muted rounded-lg transition-colors hover:bg-muted/80 shadow-sm"
                    onClick={() => shareAchievement(achievement)}
                  >
                    <Share2 className="w-4 h-4 text-primary" />
                  </button>
                )}
                
                <div className="flex items-start gap-4">
                  {/* Icon */}
                  <div className={`w-14 h-14 rounded-xl flex items-center justify-center flex-shrink-0 shadow-md ${
                    achievement.unlocked
                      ? 'bg-gradient-to-br from-primary to-accent'
                      : 'bg-muted'
                  }`}>
                    {achievement.unlocked ? (
                      <Icon className="w-7 h-7 text-white" />
                    ) : (
                      <Lock className="w-7 h-7 text-muted-foreground" />
                    )}
                  </div>

                  {/* Content */}
                  <div className="flex-1 min-w-0 pr-8">
                    <div className="flex items-start justify-between gap-2 mb-1">
                      <h3 className="text-foreground font-medium">{achievement.title}</h3>
                      <div className="flex items-center gap-1 text-primary">
                        <Star className="w-4 h-4 fill-primary" />
                        <span className="text-sm font-semibold">{achievement.points}</span>
                      </div>
                    </div>

                    <p className="text-sm text-muted-foreground mb-2">{achievement.description}</p>

                    {/* Rarity Badge */}
                    <div className="flex items-center gap-2 mb-2">
                      <span className={`text-xs px-2 py-1 rounded font-medium ${getRarityColor(achievement.rarity)}`}>
                        {achievement.rarity}
                      </span>
                      {achievement.unlocked && achievement.unlockedDate && (
                        <span className="text-xs text-muted-foreground">
                          Unlocked {new Date(achievement.unlockedDate).toLocaleDateString()}
                        </span>
                      )}
                    </div>

                    {/* Progress Bar */}
                    {!achievement.unlocked && (
                      <div className="space-y-1">
                        <div className="flex items-center justify-between text-xs">
                          <span className="text-muted-foreground">Progress</span>
                          <span className="text-primary font-semibold">
                            {achievement.progress} / {achievement.total}
                          </span>
                        </div>
                        <div className="h-2 bg-muted rounded-full overflow-hidden shadow-inner">
                          <div
                            className="h-full bg-gradient-to-r from-primary to-accent rounded-full shadow-sm transition-all"
                            style={{ width: `${Math.min(progressPercent, 100)}%` }}
                          />
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {filteredAchievements.length === 0 && (
          <div className="text-center py-12">
            <Trophy className="w-12 h-12 text-muted-foreground mx-auto mb-3 opacity-50" />
            <p className="text-muted-foreground">No achievements in this category</p>
          </div>
        )}
      </div>
    </div>
  );
}