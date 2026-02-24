import { Plus, ChevronRight, Dumbbell, TrendingUp, Target } from 'lucide-react';
import { Link } from 'react-router';

export default function ProgramsScreen() {
  const myPrograms = [
    { id: 1, name: 'Push Pull Legs', workouts: 6, weeks: 8, progress: 65 },
    { id: 2, name: 'Strength Builder', workouts: 4, weeks: 12, progress: 30 },
    { id: 3, name: 'Hypertrophy Focus', workouts: 5, weeks: 10, progress: 80 },
  ];

  const explorePrograms = [
    { id: 4, name: 'Beginner Full Body', workouts: 3, weeks: 4, difficulty: 'Beginner', icon: Target },
    { id: 5, name: 'Advanced PPL', workouts: 6, weeks: 12, difficulty: 'Advanced', icon: TrendingUp },
    { id: 6, name: 'Powerlifting Program', workouts: 4, weeks: 16, difficulty: 'Intermediate', icon: Dumbbell },
  ];

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="bg-card border-b border-border shadow-md">
        <div className="max-w-md mx-auto px-6 pt-12 pb-6">
          <h1 className="text-foreground">Programs</h1>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Create Program Card */}
        <Link to="/programs/create" className="block mb-6">
          <div className="bg-gradient-to-br from-primary to-accent rounded-xl p-6 shadow-lg hover:shadow-xl transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-white mb-1">Create New Program</h3>
                <p className="text-white/80 text-sm">Build your custom workout plan</p>
              </div>
              <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center shadow-md">
                <Plus className="w-6 h-6 text-white" />
              </div>
            </div>
          </div>
        </Link>

        {/* My Programs */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-foreground">My Programs</h2>
            <button className="text-sm text-primary">Manage</button>
          </div>

          <div className="space-y-3">
            {myPrograms.map((program) => (
              <Link
                key={program.id}
                to={`/programs/detail/${program.id}`}
                className="block"
              >
                <div className="bg-card border border-border rounded-xl p-4 shadow-md hover:shadow-lg transition-shadow">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1">
                      <h3 className="text-foreground font-medium mb-1">{program.name}</h3>
                      <div className="flex items-center gap-3 text-xs text-muted-foreground">
                        <span>{program.workouts} workouts</span>
                        <span>•</span>
                        <span>{program.weeks} weeks</span>
                      </div>
                    </div>
                    <ChevronRight className="w-5 h-5 text-muted-foreground flex-shrink-0" />
                  </div>

                  {/* Progress Bar */}
                  <div className="space-y-2">
                    <div className="flex items-center justify-between text-xs">
                      <span className="text-muted-foreground">Progress</span>
                      <span className="text-primary font-semibold">{program.progress}%</span>
                    </div>
                    <div className="h-2 bg-muted rounded-full overflow-hidden shadow-inner">
                      <div
                        className="h-full bg-gradient-to-r from-primary to-accent rounded-full shadow-sm"
                        style={{ width: `${program.progress}%` }}
                      ></div>
                    </div>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>

        {/* Explore Programs */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-foreground">Explore Programs</h2>
            <button className="text-sm text-primary">See All</button>
          </div>

          <div className="space-y-3">
            {explorePrograms.map((program) => {
              const Icon = program.icon;
              return (
                <Link
                  key={program.id}
                  to={`/programs/detail/${program.id}`}
                  className="block"
                >
                  <div className="bg-card border border-border rounded-xl p-4 shadow-md hover:shadow-lg transition-shadow">
                    <div className="flex items-start gap-3">
                      <div className="w-12 h-12 bg-gradient-to-br from-primary to-accent rounded-lg flex items-center justify-center flex-shrink-0 shadow-md">
                        <Icon className="w-6 h-6 text-white" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <h3 className="text-foreground font-medium mb-1">{program.name}</h3>
                        <div className="flex items-center gap-3 text-xs text-muted-foreground mb-2">
                          <span>{program.workouts} workouts</span>
                          <span>•</span>
                          <span>{program.weeks} weeks</span>
                        </div>
                        <div className="inline-flex items-center px-2 py-1 rounded-full bg-secondary/10 text-secondary text-xs font-medium shadow-sm">
                          {program.difficulty}
                        </div>
                      </div>
                      <ChevronRight className="w-5 h-5 text-muted-foreground flex-shrink-0 mt-2" />
                    </div>
                  </div>
                </Link>
              );
            })}
          </div>
        </div>

        {/* Featured Program */}
        <div className="bg-gradient-to-br from-secondary to-accent rounded-xl p-6 shadow-lg">
          <div className="text-white/80 text-xs font-semibold mb-2 tracking-wider">FEATURED</div>
          <h3 className="text-white mb-2">30-Day Challenge</h3>
          <p className="text-white/80 text-sm mb-4">
            Transform your physique with this intensive program
          </p>
          <button className="w-full bg-white text-secondary font-medium py-3 rounded-lg shadow-md hover:shadow-lg transition-shadow">
            Start Challenge
          </button>
        </div>
      </div>
    </div>
  );
}
