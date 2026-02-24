import { ArrowLeft, Check, Plus, Timer, Trophy, Moon, Sun, TrendingUp, ArrowUp, Minus, ChevronDown, ChevronUp, Clock } from 'lucide-react';
import { Link, useParams, useNavigate } from 'react-router';
import { useState } from 'react';
import { useTheme } from '../ThemeContext';

export default function WorkoutLoggingScreen() {
  const { dayId } = useParams();
  const navigate = useNavigate();
  const [isCompleted, setIsCompleted] = useState(false);
  const [restTimer, setRestTimer] = useState(60);
  const [showRestTimer, setShowRestTimer] = useState(false);
  const [expandedExercise, setExpandedExercise] = useState(0);
  const [workoutNotes, setWorkoutNotes] = useState('');
  const { theme, toggleTheme } = useTheme();

  const [exercises, setExercises] = useState([
    {
      name: 'Barbell Bench Press',
      equipment: 'Barbell',
      repRange: '6-12',
      targetRir: 2,
      sets: [
        { reps: 12, weight: 135, rir: 2, completed: true },
        { reps: 10, weight: 155, rir: 1, completed: true },
        { reps: 8, weight: 185, rir: 1, completed: true },
        { reps: 6, weight: 205, rir: 0, completed: false },
      ],
    },
    {
      name: 'Incline Dumbbell Press',
      equipment: 'Dumbbell',
      repRange: '8-12',
      targetRir: 2,
      sets: [
        { reps: 12, weight: 70, rir: 3, completed: true },
        { reps: 10, weight: 75, rir: 2, completed: false },
        { reps: 8, weight: 80, rir: 1, completed: false },
      ],
    },
    {
      name: 'Cable Flyes',
      equipment: 'Machine',
      repRange: '12-15',
      targetRir: 1,
      sets: [
        { reps: 15, weight: 40, rir: 2, completed: false },
        { reps: 15, weight: 40, rir: 1, completed: false },
        { reps: 15, weight: 40, rir: 0, completed: false },
      ],
    },
  ]);

  const updateSet = (exerciseIndex: number, setIndex: number, field: 'reps' | 'weight' | 'rir', value: number) => {
    const newExercises = [...exercises];
    newExercises[exerciseIndex].sets[setIndex][field] = value;
    setExercises(newExercises);
  };

  const toggleSetCompletion = (exerciseIndex: number, setIndex: number) => {
    const newExercises = [...exercises];
    newExercises[exerciseIndex].sets[setIndex].completed = !newExercises[exerciseIndex].sets[setIndex].completed;
    setExercises(newExercises);
  };

  if (isCompleted) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center p-6">
        <div className="max-w-md w-full">
          <div className="bg-card border border-border rounded-2xl p-8 text-center shadow-2xl">
            <div className="w-24 h-24 bg-gradient-to-br from-primary to-accent rounded-full flex items-center justify-center mx-auto mb-6 shadow-lg">
              <Trophy className="w-12 h-12 text-white" />
            </div>
            <h1 className="text-foreground mb-2">Great Job!</h1>
            <p className="text-muted-foreground mb-6">You've completed your workout</p>
            
            <div className="grid grid-cols-3 gap-3 mb-6">
              <div className="bg-muted rounded-lg p-3 shadow-sm">
                <div className="text-2xl font-semibold text-primary">18</div>
                <div className="text-xs text-muted-foreground">Sets</div>
              </div>
              <div className="bg-muted rounded-lg p-3 shadow-sm">
                <div className="text-2xl font-semibold text-accent">4.2k</div>
                <div className="text-xs text-muted-foreground">Volume</div>
              </div>
              <div className="bg-muted rounded-lg p-3 shadow-sm">
                <div className="text-2xl font-semibold text-secondary">52</div>
                <div className="text-xs text-muted-foreground">Minutes</div>
              </div>
            </div>

            <Link
              to="/home"
              className="block w-full bg-primary text-primary-foreground rounded-lg py-3 font-medium shadow-md hover:shadow-lg transition-shadow"
            >
              Back to Home
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background pb-6">
      {/* Header */}
      <div className="bg-gradient-to-br from-primary to-accent text-white shadow-lg sticky top-0 z-10">
        <div className="max-w-md mx-auto px-6 py-4">
          <div className="flex items-center justify-between mb-3">
            <Link to="/today" className="p-2 -ml-2 hover:bg-white/10 rounded-lg transition-colors">
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <div className="text-center">
              <h2 className="text-white text-lg">Push Day</h2>
              <p className="text-white/70 text-xs">Upper Body Strength</p>
            </div>
            <button
              onClick={() => setIsCompleted(true)}
              className="px-3 py-1.5 bg-white/20 rounded-lg text-sm font-medium shadow-sm hover:bg-white/30 transition-colors"
            >
              Finish
            </button>
          </div>

          {/* Timer */}
          <div className="flex items-center justify-end gap-2">
            <button
              onClick={() => setShowRestTimer(!showRestTimer)}
              className="p-2 bg-white/20 rounded-lg hover:bg-white/30 transition-colors"
            >
              <Clock className="w-5 h-5" />
            </button>
          </div>

          {showRestTimer && (
            <div className="mt-3 bg-white/10 rounded-lg p-4 shadow-md">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-white/80">Rest Timer</span>
              </div>
              <div className="flex items-center justify-between gap-4">
                <button 
                  onClick={() => setRestTimer(Math.max(10, restTimer - 10))}
                  className="w-10 h-10 bg-white/20 rounded-lg hover:bg-white/30 transition-colors flex items-center justify-center"
                >
                  <Minus className="w-5 h-5 text-white" />
                </button>
                <span className="text-5xl font-bold tabular-nums text-white">{restTimer}s</span>
                <button 
                  onClick={() => setRestTimer(restTimer + 10)}
                  className="w-10 h-10 bg-white/20 rounded-lg hover:bg-white/30 transition-colors flex items-center justify-center"
                >
                  <Plus className="w-5 h-5 text-white" />
                </button>
              </div>
              <button className="w-full mt-3 px-4 py-2 bg-white text-primary rounded-lg font-medium shadow-sm hover:shadow-md transition-shadow">
                Start
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Exercises */}
      <div className="max-w-md mx-auto px-6 py-6 space-y-4">
        {exercises.map((exercise, exerciseIndex) => {
          const isExpanded = expandedExercise === exerciseIndex;
          
          return (
            <div key={exerciseIndex} className="bg-card border border-border rounded-xl overflow-hidden shadow-lg">
              {/* Exercise Header - Always Visible */}
              <button
                onClick={() => setExpandedExercise(isExpanded ? -1 : exerciseIndex)}
                className="w-full bg-gradient-to-r from-primary/10 to-accent/10 p-4 border-b border-border text-left"
              >
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="text-foreground font-medium">{exercise.name}</h3>
                      <span className="text-xs px-2 py-0.5 bg-muted text-muted-foreground rounded">
                        {exercise.equipment}
                      </span>
                    </div>
                    <p className="text-sm text-muted-foreground">
                      {exercise.sets.filter(s => s.completed).length} of {exercise.sets.length} sets completed
                    </p>
                  </div>
                  {isExpanded ? (
                    <ChevronUp className="w-5 h-5 text-muted-foreground" />
                  ) : (
                    <ChevronDown className="w-5 h-5 text-muted-foreground" />
                  )}
                </div>
              </button>

              {/* Exercise Details - Collapsible */}
              {isExpanded && (
                <div className="p-4">
                  {/* Exercise Info */}
                  <div className="flex items-center gap-2 mb-3 text-xs">
                    <span className="px-2 py-1 bg-primary/20 text-primary rounded font-medium">
                      {exercise.repRange} reps
                    </span>
                    <span className="px-2 py-1 bg-accent/20 text-accent rounded font-medium">
                      Target RIR: {exercise.targetRir}
                    </span>
                  </div>

                  {/* Sets Header */}
                  <div className="grid grid-cols-5 gap-2 mb-3 text-xs font-semibold text-muted-foreground">
                    <div>SET</div>
                    <div className="text-center">REPS</div>
                    <div className="text-center">WEIGHT</div>
                    <div className="text-center">RIR</div>
                    <div className="text-center">✓</div>
                  </div>

                  {/* Sets */}
                  <div className="space-y-2">
                    {exercise.sets.map((set, setIndex) => (
                      <div
                        key={setIndex}
                        className={`grid grid-cols-5 gap-2 items-center p-2.5 rounded-lg shadow-sm ${
                          set.completed ? 'bg-primary/10 border border-primary/20' : 'bg-muted'
                        }`}
                      >
                        <div className="font-semibold text-foreground text-sm">{setIndex + 1}</div>
                        <input
                          type="number"
                          value={set.reps}
                          onChange={(e) => updateSet(exerciseIndex, setIndex, 'reps', parseInt(e.target.value))}
                          className="text-center bg-background border border-border rounded px-1.5 py-1 text-sm font-medium text-foreground"
                        />
                        <input
                          type="number"
                          value={set.weight}
                          onChange={(e) => updateSet(exerciseIndex, setIndex, 'weight', parseInt(e.target.value))}
                          className="text-center bg-background border border-border rounded px-1.5 py-1 text-sm font-medium text-foreground"
                        />
                        <input
                          type="number"
                          value={set.rir}
                          min="0"
                          max="10"
                          onChange={(e) => updateSet(exerciseIndex, setIndex, 'rir', parseInt(e.target.value))}
                          className={`text-center border rounded px-1.5 py-1 text-sm font-medium ${
                            set.rir <= exercise.targetRir
                              ? 'bg-primary/10 border-primary/30 text-primary'
                              : 'bg-background border-border text-foreground'
                          }`}
                        />
                        <button
                          onClick={() => toggleSetCompletion(exerciseIndex, setIndex)}
                          className={`w-7 h-7 rounded-full flex items-center justify-center mx-auto shadow-sm ${
                            set.completed
                              ? 'bg-primary text-white'
                              : 'bg-background border border-border text-muted-foreground'
                          }`}
                        >
                          {set.completed && <Check className="w-4 h-4" />}
                        </button>
                      </div>
                    ))}
                  </div>

                  {/* Add Set */}
                  <button className="w-full mt-3 py-2 border-2 border-dashed border-border rounded-lg text-sm text-muted-foreground hover:border-primary hover:text-primary transition-colors flex items-center justify-center gap-2">
                    <Plus className="w-4 h-4" />
                    Add Set
                  </button>
                </div>
              )}
            </div>
          );
        })}

        {/* Workout Notes */}
        <div className="bg-card border border-border rounded-xl p-4 shadow-lg">
          <h3 className="text-foreground font-medium mb-3">Workout Notes</h3>
          <textarea
            value={workoutNotes}
            onChange={(e) => setWorkoutNotes(e.target.value)}
            placeholder="How did the workout feel? Any observations or adjustments for next time..."
            className="w-full min-h-[100px] px-3 py-2 bg-muted border border-border rounded-lg text-foreground placeholder:text-muted-foreground resize-none focus:outline-none focus:ring-2 focus:ring-primary"
          />
        </div>

        {/* Add Exercise */}
        <button className="w-full bg-card border-2 border-dashed border-border rounded-xl p-6 text-muted-foreground hover:border-primary hover:text-primary transition-colors flex items-center justify-center gap-2 shadow-md">
          <Plus className="w-5 h-5" />
          <span className="font-medium">Add Exercise</span>
        </button>
      </div>
    </div>
  );
}