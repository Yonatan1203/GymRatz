import { TrendingUp, Flame, Award, ChevronRight, Play, Dumbbell } from 'lucide-react';
import { Link } from 'react-router';

export default function HomeScreen() {
  const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const today = 2; // Wednesday

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="bg-gradient-to-br from-primary to-accent text-white shadow-lg">
        <div className="max-w-md mx-auto px-6 pt-12 pb-8">
          <div className="flex items-center justify-between mb-6">
            <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center shadow-md">
              <span className="text-sm font-semibold">YG</span>
            </div>
            <h1 className="text-white">GymRatz</h1>
            <Link to="/profile" className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center shadow-md">
              <span className="text-sm">👤</span>
            </Link>
          </div>

          <div className="mb-6">
            <h2 className="text-white mb-1">Hi, Yonatan 👋</h2>
            <div className="flex items-center gap-2 text-white/90">
              <Flame className="w-4 h-4" />
              <span className="text-sm">12 day streak</span>
            </div>
          </div>

          {/* Weekly Schedule Strip */}
          <div className="flex gap-2 overflow-x-auto pb-2">
            {weekDays.map((day, index) => (
              <div
                key={day}
                className={`flex-shrink-0 w-14 h-20 rounded-lg flex flex-col items-center justify-center shadow-md ${
                  index === today
                    ? 'bg-white text-primary'
                    : 'bg-white/20 text-white'
                }`}
              >
                <span className="text-xs mb-1">{day}</span>
                <span className="text-lg font-semibold">{index + 10}</span>
                {index < today && (
                  <div className="w-1.5 h-1.5 rounded-full bg-primary mt-1 shadow-sm"></div>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Overview Stats */}
        <div className="grid grid-cols-3 gap-3 mb-6">
          <div className="bg-card border border-border rounded-lg p-4 text-center shadow-md">
            <div className="flex justify-center mb-2">
              <Flame className="w-5 h-5 text-primary" />
            </div>
            <div className="text-xl font-semibold text-foreground">24</div>
            <div className="text-xs text-muted-foreground">Workouts</div>
          </div>
          <div className="bg-card border border-border rounded-lg p-4 text-center shadow-md">
            <div className="flex justify-center mb-2">
              <TrendingUp className="w-5 h-5 text-accent" />
            </div>
            <div className="text-xl font-semibold text-foreground">12.5k</div>
            <div className="text-xs text-muted-foreground">Weekly Vol</div>
          </div>
          <div className="bg-card border border-border rounded-lg p-4 text-center shadow-md">
            <div className="flex justify-center mb-2">
              <Award className="w-5 h-5 text-secondary" />
            </div>
            <div className="text-xl font-semibold text-foreground">225</div>
            <div className="text-xs text-muted-foreground">Recent PR</div>
          </div>
        </div>

        {/* Upcoming Workout */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-foreground">Today's Workout</h3>
            <Link to="/today" className="text-sm text-primary">View All</Link>
          </div>
          
          <Link to="/workout/1" className="block">
            <div className="bg-gradient-to-br from-primary to-accent rounded-xl p-6 shadow-lg">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="text-white mb-1">Push Day</h3>
                  <p className="text-sm text-white/80">Upper Body Strength</p>
                </div>
                <div className="w-12 h-12 rounded-full bg-white/20 flex items-center justify-center shadow-md">
                  <Play className="w-6 h-6 text-white" />
                </div>
              </div>
              
              <div className="space-y-2 mb-4">
                <div className="flex justify-between text-white/90 text-sm">
                  <span>6 Exercises</span>
                  <span>•</span>
                  <span>45-60 min</span>
                </div>
              </div>

              <div className="flex gap-2">
                <div className="flex-1 bg-white/20 rounded-lg p-2 text-center shadow-sm">
                  <div className="text-xs text-white/70">Sets</div>
                  <div className="text-sm font-semibold text-white">18</div>
                </div>
                <div className="flex-1 bg-white/20 rounded-lg p-2 text-center shadow-sm">
                  <div className="text-xs text-white/70">Volume</div>
                  <div className="text-sm font-semibold text-white">4,200kg</div>
                </div>
              </div>
            </div>
          </Link>
        </div>

        {/* Quick Actions */}
        <div className="mb-6">
          <h3 className="text-foreground mb-3">Quick Actions</h3>
          <div className="grid grid-cols-2 gap-3">
            <Link to="/progress" className="bg-card border border-border rounded-lg p-4 shadow-md hover:shadow-lg transition-shadow">
              <TrendingUp className="w-6 h-6 text-primary mb-2" />
              <div className="font-medium text-foreground">Progress</div>
              <div className="text-xs text-muted-foreground">View stats</div>
            </Link>
            <Link to="/programs" className="bg-card border border-border rounded-lg p-4 shadow-md hover:shadow-lg transition-shadow">
              <Award className="w-6 h-6 text-secondary mb-2" />
              <div className="font-medium text-foreground">Programs</div>
              <div className="text-xs text-muted-foreground">Browse all</div>
            </Link>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-foreground">Recent Activity</h3>
            <button className="text-sm text-primary">See All</button>
          </div>
          
          <div className="space-y-2">
            {['Yesterday - Pull Day', 'Monday - Legs', 'Saturday - Push Day'].map((activity, index) => (
              <div key={index} className="bg-card border border-border rounded-lg p-4 flex items-center justify-between shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-muted rounded-lg flex items-center justify-center shadow-sm">
                    <Flame className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <div className="font-medium text-foreground text-sm">{activity}</div>
                    <div className="text-xs text-muted-foreground">Completed</div>
                  </div>
                </div>
                <ChevronRight className="w-5 h-5 text-muted-foreground" />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}