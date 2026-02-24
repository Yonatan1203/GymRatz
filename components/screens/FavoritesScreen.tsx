import { ArrowLeft, Heart, Dumbbell, Play } from 'lucide-react';
import { Link } from 'react-router';
import { useState } from 'react';

export default function FavoritesScreen() {
  const [favorites, setFavorites] = useState([
    { id: 1, name: 'Push Pull Legs', type: 'program', workouts: 6, weeks: 8 },
    { id: 2, name: 'Barbell Bench Press', type: 'exercise', muscle: 'Chest', sets: '4x8-12' },
    { id: 3, name: 'Deadlift', type: 'exercise', muscle: 'Back', sets: '4x5-8' },
    { id: 4, name: 'Pull Day', type: 'workout', exercises: 6, duration: '55 min' },
    { id: 5, name: 'Back Squat', type: 'exercise', muscle: 'Legs', sets: '4x6-10' },
  ]);

  const removeFavorite = (id: number) => {
    setFavorites(favorites.filter(fav => fav.id !== id));
  };

  const programs = favorites.filter(f => f.type === 'program');
  const workouts = favorites.filter(f => f.type === 'workout');
  const exercises = favorites.filter(f => f.type === 'exercise');

  return (
    <div className="min-h-screen bg-background pb-20">
      {/* Header */}
      <div className="bg-card border-b border-border shadow-md">
        <div className="max-w-md mx-auto px-6 pt-12 pb-6">
          <div className="flex items-center gap-3">
            <Link to="/profile" className="p-2 -ml-2 hover:bg-muted rounded-lg transition-colors">
              <ArrowLeft className="w-5 h-5 text-foreground" />
            </Link>
            <h1 className="text-foreground">Favorites</h1>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-md mx-auto px-6 py-6">
        {favorites.length === 0 ? (
          <div className="text-center py-12">
            <Heart className="w-12 h-12 text-muted-foreground mx-auto mb-3 opacity-50" />
            <p className="text-muted-foreground">No favorites yet</p>
            <p className="text-sm text-muted-foreground mt-1">Start adding your favorite programs and exercises</p>
          </div>
        ) : (
          <>
            {/* Programs */}
            {programs.length > 0 && (
              <div className="mb-6">
                <h2 className="text-foreground mb-3">Programs</h2>
                <div className="space-y-2">
                  {programs.map((program) => (
                    <div key={program.id} className="bg-card border border-border rounded-xl p-4 shadow-md">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <h3 className="text-foreground font-medium mb-1">{program.name}</h3>
                          <div className="flex items-center gap-3 text-xs text-muted-foreground">
                            <span>{program.workouts} workouts</span>
                            <span>•</span>
                            <span>{program.weeks} weeks</span>
                          </div>
                        </div>
                        <button
                          onClick={() => removeFavorite(program.id)}
                          className="p-2 hover:bg-muted rounded-lg transition-colors"
                        >
                          <Heart className="w-5 h-5 fill-red-500 text-red-500" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Workouts */}
            {workouts.length > 0 && (
              <div className="mb-6">
                <h2 className="text-foreground mb-3">Workouts</h2>
                <div className="space-y-2">
                  {workouts.map((workout) => (
                    <div key={workout.id} className="bg-card border border-border rounded-xl p-4 shadow-md">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <h3 className="text-foreground font-medium mb-1">{workout.name}</h3>
                          <div className="flex items-center gap-3 text-xs text-muted-foreground">
                            <span>{workout.exercises} exercises</span>
                            <span>•</span>
                            <span>{workout.duration}</span>
                          </div>
                        </div>
                        <button
                          onClick={() => removeFavorite(workout.id)}
                          className="p-2 hover:bg-muted rounded-lg transition-colors"
                        >
                          <Heart className="w-5 h-5 fill-red-500 text-red-500" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Exercises */}
            {exercises.length > 0 && (
              <div className="mb-6">
                <h2 className="text-foreground mb-3">Exercises</h2>
                <div className="space-y-2">
                  {exercises.map((exercise) => (
                    <div key={exercise.id} className="bg-card border border-border rounded-xl p-4 shadow-md">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1">
                            <Dumbbell className="w-4 h-4 text-primary" />
                            <h3 className="text-foreground font-medium">{exercise.name}</h3>
                          </div>
                          <div className="flex items-center gap-3 text-xs text-muted-foreground">
                            <span>{exercise.muscle}</span>
                            <span>•</span>
                            <span>{exercise.sets}</span>
                          </div>
                        </div>
                        <button
                          onClick={() => removeFavorite(exercise.id)}
                          className="p-2 hover:bg-muted rounded-lg transition-colors"
                        >
                          <Heart className="w-5 h-5 fill-red-500 text-red-500" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
