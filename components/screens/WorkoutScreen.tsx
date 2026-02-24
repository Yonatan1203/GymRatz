import { Play, Clock, ChevronRight, Dumbbell } from 'lucide-react';
import { Link } from 'react-router';

export default function WorkoutScreen() {
  const workouts = [
    {
      id: 1,
      name: 'Push Day',
      type: 'Upper Body',
      exercises: 6,
      duration: '45-60 min',
      sets: 18,
      status: 'ready'
    },
    {
      id: 2,
      name: 'Pull Day',
      type: 'Back & Biceps',
      exercises: 5,
      duration: '40-50 min',
      sets: 15,
      status: 'scheduled'
    },
    {
      id: 3,
      name: 'Leg Day',
      type: 'Lower Body',
      exercises: 7,
      duration: '60-75 min',
      sets: 21,
      status: 'scheduled'
    }
  ];

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="bg-gradient-to-br from-primary to-accent text-white shadow-lg">
        <div className="max-w-md mx-auto px-6 pt-12 pb-6">
          <h1 className="text-white mb-2">Today's Workouts</h1>
          <p className="text-white/80 text-sm">Wednesday, Feb 12, 2026</p>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Workouts List */}
        <div className="space-y-4">
          {workouts.map((workout) => (
            <Link
              key={workout.id}
              to={`/workout/${workout.id}`}
              className="block"
            >
              <div className="bg-card border border-border rounded-xl overflow-hidden shadow-lg hover:shadow-xl transition-shadow">
                <div className="p-5">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1">
                      <h3 className="text-foreground mb-1">{workout.name}</h3>
                      <p className="text-sm text-muted-foreground">{workout.type}</p>
                    </div>
                    <div className={`px-3 py-1 rounded-full text-xs font-semibold shadow-sm ${
                      workout.status === 'ready' 
                        ? 'bg-primary/10 text-primary' 
                        : 'bg-muted text-muted-foreground'
                    }`}>
                      {workout.status === 'ready' ? 'Start Now' : 'Scheduled'}
                    </div>
                  </div>

                  <div className="flex items-center gap-4 text-sm text-muted-foreground mb-4">
                    <div className="flex items-center gap-1">
                      <Dumbbell className="w-4 h-4" />
                      <span>{workout.exercises} exercises</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Clock className="w-4 h-4" />
                      <span>{workout.duration}</span>
                    </div>
                  </div>

                  <div className="flex gap-2">
                    <div className="flex-1 bg-muted rounded-lg p-3 text-center shadow-sm">
                      <div className="text-xs text-muted-foreground mb-1">Total Sets</div>
                      <div className="text-lg font-semibold text-foreground">{workout.sets}</div>
                    </div>
                    <div className="flex-1 bg-muted rounded-lg p-3 text-center shadow-sm">
                      <div className="text-xs text-muted-foreground mb-1">Est. Volume</div>
                      <div className="text-lg font-semibold text-foreground">4.2k kg</div>
                    </div>
                  </div>
                </div>

                <div className="bg-gradient-to-r from-primary to-accent px-5 py-3 flex items-center justify-between">
                  <span className="text-white font-medium text-sm">Start Workout</span>
                  <Play className="w-5 h-5 text-white" />
                </div>
              </div>
            </Link>
          ))}
        </div>

        {/* Quick Stats */}
        <div className="mt-6 bg-card border border-border rounded-xl p-5 shadow-md">
          <h3 className="text-foreground mb-4">This Week 📅</h3>
          <div className="grid grid-cols-3 gap-3">
            <div className="text-center">
              <div className="text-2xl font-semibold text-primary mb-1">3 ✅</div>
              <div className="text-xs text-muted-foreground">Completed</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-semibold text-secondary mb-1">2 ⏳</div>
              <div className="text-xs text-muted-foreground">Remaining</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-semibold text-accent mb-1">60% 💯</div>
              <div className="text-xs text-muted-foreground">Complete</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}