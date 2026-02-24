import { ArrowLeft, Plus, Trash2, GripVertical, Save, Dumbbell, Calendar } from 'lucide-react';
import { Link, useNavigate } from 'react-router';
import { useState } from 'react';

interface Exercise {
  id: string;
  name: string;
  sets: number;
  repMin: number;
  repMax: number;
  targetRir: number;
  restSeconds: number;
  progressionType: 'LoadFirst' | 'RepsFirst' | 'Mixed';
  category: string;
  equipment?: string;
  isCustom?: boolean;
}

interface WorkoutDay {
  id: string;
  name: string;
  dayOfWeek: string;
  exercises: Exercise[];
}

export default function CreateProgramScreen() {
  const navigate = useNavigate();
  const [programName, setProgramName] = useState('');
  const [programWeeks, setProgramWeeks] = useState('8');
  const [workoutDays, setWorkoutDays] = useState<WorkoutDay[]>([
    { id: '1', name: 'Push Day', dayOfWeek: 'Monday', exercises: [] },
  ]);
  const [showExercisePicker, setShowExercisePicker] = useState<string | null>(null);
  const [showCustomExercise, setShowCustomExercise] = useState<string | null>(null);
  const [customExercise, setCustomExercise] = useState({
    name: '',
    category: 'Chest',
    equipment: 'Dumbbell',
    sets: 3,
    repMin: 8,
    repMax: 12,
    rir: 2,
  });

  const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  const availableExercises = [
    { name: 'Barbell Bench Press', category: 'Chest', equipment: 'Barbell', defaultSets: 4, defaultReps: [6, 12], defaultRir: 2 },
    { name: 'Incline Dumbbell Press', category: 'Chest', equipment: 'Dumbbell', defaultSets: 3, defaultReps: [8, 12], defaultRir: 2 },
    { name: 'Cable Flyes', category: 'Chest', equipment: 'Machine', defaultSets: 3, defaultReps: [12, 15], defaultRir: 1 },
    { name: 'Deadlift', category: 'Back', equipment: 'Barbell', defaultSets: 4, defaultReps: [5, 8], defaultRir: 3 },
    { name: 'Barbell Row', category: 'Back', equipment: 'Barbell', defaultSets: 4, defaultReps: [8, 12], defaultRir: 2 },
    { name: 'Pull Ups', category: 'Back', equipment: 'Body Weight', defaultSets: 3, defaultReps: [6, 10], defaultRir: 2 },
    { name: 'Lat Pulldown', category: 'Back', equipment: 'Machine', defaultSets: 3, defaultReps: [10, 12], defaultRir: 1 },
    { name: 'Back Squat', category: 'Legs', equipment: 'Barbell', defaultSets: 4, defaultReps: [6, 10], defaultRir: 2 },
    { name: 'Romanian Deadlift', category: 'Legs', equipment: 'Barbell', defaultSets: 3, defaultReps: [8, 12], defaultRir: 2 },
    { name: 'Leg Press', category: 'Legs', equipment: 'Machine', defaultSets: 3, defaultReps: [10, 15], defaultRir: 1 },
    { name: 'Walking Lunges', category: 'Legs', equipment: 'Dumbbell', defaultSets: 3, defaultReps: [10, 12], defaultRir: 2 },
    { name: 'Overhead Press', category: 'Shoulders', equipment: 'Barbell', defaultSets: 4, defaultReps: [6, 10], defaultRir: 2 },
    { name: 'Lateral Raises', category: 'Shoulders', equipment: 'Dumbbell', defaultSets: 3, defaultReps: [12, 15], defaultRir: 1 },
    { name: 'Face Pulls', category: 'Shoulders', equipment: 'Machine', defaultSets: 3, defaultReps: [15, 20], defaultRir: 1 },
  ];

  const addWorkoutDay = () => {
    const newDay: WorkoutDay = {
      id: Date.now().toString(),
      name: `Day ${workoutDays.length + 1}`,
      dayOfWeek: 'Monday',
      exercises: [],
    };
    setWorkoutDays([...workoutDays, newDay]);
  };

  const removeWorkoutDay = (id: string) => {
    setWorkoutDays(workoutDays.filter(day => day.id !== id));
  };

  const updateDayName = (id: string, name: string) => {
    setWorkoutDays(workoutDays.map(day =>
      day.id === id ? { ...day, name } : day
    ));
  };

  const addExerciseToDay = (dayId: string, exerciseTemplate: any) => {
    const newExercise: Exercise = {
      id: Date.now().toString(),
      name: exerciseTemplate.name,
      sets: exerciseTemplate.defaultSets,
      repMin: exerciseTemplate.defaultReps[0],
      repMax: exerciseTemplate.defaultReps[1],
      targetRir: exerciseTemplate.defaultRir,
      restSeconds: 120,
      progressionType: 'LoadFirst',
      category: exerciseTemplate.category,
      equipment: exerciseTemplate.equipment,
      isCustom: exerciseTemplate.isCustom || false,
    };

    setWorkoutDays(workoutDays.map(day =>
      day.id === dayId
        ? { ...day, exercises: [...day.exercises, newExercise] }
        : day
    ));
    setShowExercisePicker(null);
  };

  const addCustomExercise = (dayId: string) => {
    if (!customExercise.name.trim()) {
      alert('Please enter an exercise name');
      return;
    }

    addExerciseToDay(dayId, {
      name: customExercise.name,
      category: customExercise.category,
      equipment: customExercise.equipment,
      defaultSets: customExercise.sets,
      defaultReps: [customExercise.repMin, customExercise.repMax],
      defaultRir: customExercise.rir,
      isCustom: true,
    });

    setCustomExercise({
      name: '',
      category: 'Chest',
      equipment: 'Dumbbell',
      sets: 3,
      repMin: 8,
      repMax: 12,
      rir: 2,
    });
    setShowCustomExercise(null);
  };

  const removeExercise = (dayId: string, exerciseId: string) => {
    setWorkoutDays(workoutDays.map(day =>
      day.id === dayId
        ? { ...day, exercises: day.exercises.filter(ex => ex.id !== exerciseId) }
        : day
    ));
  };

  const updateExercise = (dayId: string, exerciseId: string, updates: Partial<Exercise>) => {
    setWorkoutDays(workoutDays.map(day =>
      day.id === dayId
        ? {
            ...day,
            exercises: day.exercises.map(ex =>
              ex.id === exerciseId ? { ...ex, ...updates } : ex
            ),
          }
        : day
    ));
  };

  const saveProgram = () => {
    // Validate
    if (!programName.trim()) {
      alert('Please enter a program name');
      return;
    }

    if (workoutDays.length === 0) {
      alert('Please add at least one workout day');
      return;
    }

    if (workoutDays.some(day => day.exercises.length === 0)) {
      alert('Each workout day must have at least one exercise');
      return;
    }

    // Save logic would go here (localStorage, API, etc.)
    console.log('Saving program:', { programName, programWeeks, workoutDays });
    
    // Navigate back
    navigate('/programs');
  };

  return (
    <div className="min-h-screen bg-background pb-20">
      {/* Header */}
      <div className="bg-card border-b border-border shadow-md sticky top-0 z-20">
        <div className="max-w-3xl mx-auto px-6 pt-12 pb-4">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <Link to="/programs" className="p-2 -ml-2 hover:bg-muted rounded-lg transition-colors">
                <ArrowLeft className="w-5 h-5 text-foreground" />
              </Link>
              <h1 className="text-foreground">Create Program</h1>
            </div>
            <button
              onClick={saveProgram}
              className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg font-medium shadow-md hover:shadow-lg transition-shadow"
            >
              <Save className="w-4 h-4" />
              Save
            </button>
          </div>

          {/* Program Info */}
          <div className="space-y-3">
            <div>
              <label className="block text-sm text-muted-foreground mb-1.5">Program Name</label>
              <input
                type="text"
                value={programName}
                onChange={(e) => setProgramName(e.target.value)}
                placeholder="e.g., Push Pull Legs"
                className="w-full px-4 py-2.5 bg-muted border border-border rounded-lg text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary shadow-sm"
              />
            </div>

            <div>
              <label className="block text-sm text-muted-foreground mb-1.5">Program Duration (weeks)</label>
              <input
                type="number"
                value={programWeeks}
                onChange={(e) => setProgramWeeks(e.target.value)}
                min="1"
                max="52"
                className="w-full px-4 py-2.5 bg-muted border border-border rounded-lg text-foreground focus:outline-none focus:ring-2 focus:ring-primary shadow-sm"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-3xl mx-auto px-6 py-6">
        {/* Workout Days */}
        <div className="space-y-4">
          {workoutDays.map((day, dayIndex) => (
            <div key={day.id} className="bg-card border border-border rounded-xl shadow-md overflow-hidden">
              {/* Day Header */}
              <div className="bg-gradient-to-br from-primary to-accent p-4">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-start gap-2 flex-1">
                    <GripVertical className="w-5 h-5 text-white/50 mt-2" />
                    <div className="flex-1 space-y-2">
                      <input
                        type="text"
                        value={day.name}
                        onChange={(e) => updateDayName(day.id, e.target.value)}
                        className="w-full bg-white/10 border border-white/20 text-white placeholder:text-white/50 px-3 py-2 rounded-lg focus:outline-none focus:ring-2 focus:ring-white/30"
                        placeholder="Workout name"
                      />
                      <div className="flex items-center gap-2 pl-0">
                        <Calendar className="w-4 h-4 text-white/70 flex-shrink-0 ml-0" />
                        <select
                          value={day.dayOfWeek}
                          onChange={(e) => setWorkoutDays(workoutDays.map(d => d.id === day.id ? { ...d, dayOfWeek: e.target.value } : d))}
                          className="flex-1 bg-white/10 border border-white/20 text-white px-3 py-2 rounded-lg focus:outline-none focus:ring-2 focus:ring-white/30 text-sm max-w-[60%]"
                        >
                          {daysOfWeek.map(dayName => (
                            <option key={dayName} value={dayName} className="bg-card text-foreground">{dayName}</option>
                          ))}
                        </select>
                      </div>
                    </div>
                  </div>
                  {workoutDays.length > 1 && (
                    <button
                      onClick={() => removeWorkoutDay(day.id)}
                      className="p-2 hover:bg-white/10 rounded-lg transition-colors mt-2"
                    >
                      <Trash2 className="w-6 h-6 text-white dark:text-red-300" />
                    </button>
                  )}
                </div>
              </div>

              {/* Exercises */}
              <div className="p-4 space-y-3">
                {day.exercises.length === 0 ? (
                  <div className="text-center py-8 text-muted-foreground">
                    <Dumbbell className="w-8 h-8 mx-auto mb-2 opacity-50" />
                    <p className="text-sm">No exercises added yet</p>
                  </div>
                ) : (
                  day.exercises.map((exercise, exIndex) => (
                    <div key={exercise.id} className="bg-muted rounded-lg p-3 border border-border">
                      <div className="flex items-start justify-between mb-3">
                        <div className="flex items-center gap-2 flex-wrap">
                          <GripVertical className="w-4 h-4 text-muted-foreground" />
                          <span className="font-medium text-foreground">{exercise.name}</span>
                          <span className="text-xs px-2 py-0.5 bg-primary/20 text-primary rounded">
                            {exercise.category}
                          </span>
                          {exercise.equipment && (
                            <span className="text-xs px-2 py-0.5 bg-secondary/20 text-secondary rounded">
                              {exercise.equipment}
                            </span>
                          )}
                        </div>
                        <button
                          onClick={() => removeExercise(day.id, exercise.id)}
                          className="p-1.5 hover:bg-destructive/10 rounded transition-colors flex-shrink-0"
                        >
                          <Trash2 className="w-5 h-5 text-destructive" />
                        </button>
                      </div>

                      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                        <div>
                          <label className="block text-xs text-muted-foreground mb-1">Sets</label>
                          <input
                            type="number"
                            value={exercise.sets}
                            onChange={(e) => updateExercise(day.id, exercise.id, { sets: parseInt(e.target.value) })}
                            min="1"
                            max="10"
                            className="w-full px-2 py-1.5 bg-card border border-border rounded text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                          />
                        </div>
                        <div>
                          <label className="block text-xs text-muted-foreground mb-1">Rep Range</label>
                          <div className="flex items-center gap-1">
                            <input
                              type="number"
                              value={exercise.repMin}
                              onChange={(e) => updateExercise(day.id, exercise.id, { repMin: parseInt(e.target.value) })}
                              min="1"
                              className="w-full px-2 py-1.5 bg-card border border-border rounded text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                            />
                            <span className="text-muted-foreground">-</span>
                            <input
                              type="number"
                              value={exercise.repMax}
                              onChange={(e) => updateExercise(day.id, exercise.id, { repMax: parseInt(e.target.value) })}
                              min="1"
                              className="w-full px-2 py-1.5 bg-card border border-border rounded text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                            />
                          </div>
                        </div>
                        <div>
                          <label className="block text-xs text-muted-foreground mb-1">Target RIR</label>
                          <input
                            type="number"
                            value={exercise.targetRir}
                            onChange={(e) => updateExercise(day.id, exercise.id, { targetRir: parseInt(e.target.value) })}
                            min="0"
                            max="10"
                            className="w-full px-2 py-1.5 bg-card border border-border rounded text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                          />
                        </div>
                        <div>
                          <label className="block text-xs text-muted-foreground mb-1">Rest (sec)</label>
                          <input
                            type="number"
                            value={exercise.restSeconds}
                            onChange={(e) => updateExercise(day.id, exercise.id, { restSeconds: parseInt(e.target.value) })}
                            min="30"
                            step="15"
                            className="w-full px-2 py-1.5 bg-card border border-border rounded text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                          />
                        </div>
                      </div>

                      <div className="mt-3">
                        <label className="block text-xs text-muted-foreground mb-1">Progression Type</label>
                        <select
                          value={exercise.progressionType}
                          onChange={(e) => updateExercise(day.id, exercise.id, { progressionType: e.target.value as Exercise['progressionType'] })}
                          className="w-full px-2 py-1.5 bg-card border border-border rounded text-sm text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
                        >
                          <option value="LoadFirst">Load First (Strength)</option>
                          <option value="RepsFirst">Reps First (Hypertrophy)</option>
                          <option value="Mixed">Mixed</option>
                        </select>
                      </div>
                    </div>
                  ))
                )}

                {/* Add Exercise Button */}
                {showCustomExercise === day.id ? (
                  <div className="bg-card border border-border rounded-lg p-4">
                    <div className="flex items-center justify-between mb-4">
                      <h4 className="font-medium text-foreground">Create Custom Exercise</h4>
                      <button
                        onClick={() => {
                          setShowCustomExercise(null);
                          setCustomExercise({ name: '', category: 'Chest', equipment: 'Dumbbell', sets: 3, repMin: 8, repMax: 12, rir: 2 });
                        }}
                        className="text-sm text-muted-foreground hover:text-foreground"
                      >
                        Cancel
                      </button>
                    </div>
                    
                    <div className="space-y-3">
                      <div>
                        <label className="block text-xs text-muted-foreground mb-1">Exercise Name</label>
                        <input
                          type="text"
                          value={customExercise.name}
                          onChange={(e) => setCustomExercise({ ...customExercise, name: e.target.value })}
                          placeholder="e.g., Dumbbell Press"
                          className="w-full px-2.5 py-1.5 bg-background border border-border rounded-lg text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary shadow-sm"
                        />
                      </div>
                      
                      <div className="grid grid-cols-2 gap-2">
                        <div>
                          <label className="block text-xs text-muted-foreground mb-1">Category</label>
                          <select
                            value={customExercise.category}
                            onChange={(e) => setCustomExercise({ ...customExercise, category: e.target.value })}
                            className="w-full px-2.5 py-1.5 bg-background border border-border rounded-lg text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary shadow-sm"
                          >
                            <option>Chest</option>
                            <option>Back</option>
                            <option>Legs</option>
                            <option>Shoulders</option>
                            <option>Arms</option>
                            <option>Core</option>
                          </select>
                        </div>
                        
                        <div>
                          <label className="block text-xs text-muted-foreground mb-1">Equipment</label>
                          <select
                            value={customExercise.equipment}
                            onChange={(e) => setCustomExercise({ ...customExercise, equipment: e.target.value })}
                            className="w-full px-2.5 py-1.5 bg-background border border-border rounded-lg text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary shadow-sm"
                          >
                            <option value="Dumbbell">Dumbbell</option>
                            <option value="Barbell">Barbell</option>
                            <option value="Machine">Machine</option>
                            <option value="Body Weight">Body Weight</option>
                          </select>
                        </div>
                      </div>
                      
                      <button
                        onClick={() => addCustomExercise(day.id)}
                        className="w-full py-2 bg-primary text-primary-foreground rounded-lg font-medium shadow-sm hover:shadow-md transition-shadow"
                      >
                        Add Custom Exercise
                      </button>
                    </div>
                  </div>
                ) : showExercisePicker === day.id ? (
                  <div className="bg-card border border-border rounded-lg p-3">
                    <div className="flex items-center justify-between mb-3">
                      <h4 className="font-medium text-foreground">Select Exercise</h4>
                      <button
                        onClick={() => setShowExercisePicker(null)}
                        className="text-sm text-muted-foreground hover:text-foreground"
                      >
                        Cancel
                      </button>
                    </div>
                    
                    <div className="space-y-1 max-h-48 overflow-y-auto">
                      {availableExercises.map((exercise) => (
                        <button
                          key={exercise.name}
                          onClick={() => addExerciseToDay(day.id, exercise)}
                          className="w-full text-left px-3 py-2 hover:bg-muted rounded-lg transition-colors"
                        >
                          <div className="flex items-center justify-between">
                            <span className="text-foreground">{exercise.name}</span>
                            <span className="text-xs px-2 py-1 bg-primary/20 text-primary rounded">
                              {exercise.category}
                            </span>
                          </div>
                        </button>
                      ))}
                    </div>
                    
                    <button
                      onClick={() => {
                        setShowExercisePicker(null);
                        setShowCustomExercise(day.id);
                      }}
                      className="w-full mt-3 py-2 border border-border rounded-lg text-sm text-foreground hover:bg-muted transition-colors flex items-center justify-center gap-2"
                    >
                      <Plus className="w-4 h-4" />
                      Create Custom Exercise
                    </button>
                  </div>
                ) : (
                  <button
                    onClick={() => setShowExercisePicker(day.id)}
                    className="w-full flex items-center justify-center gap-2 py-3 border-2 border-dashed border-border rounded-lg text-muted-foreground hover:border-primary hover:text-primary transition-colors"
                  >
                    <Plus className="w-5 h-5" />
                    Add Exercise
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Add Workout Day Button */}
        <button
          onClick={addWorkoutDay}
          className="w-full mt-4 flex items-center justify-center gap-2 py-4 bg-card border-2 border-dashed border-border rounded-xl text-primary hover:border-primary hover:bg-primary/5 transition-colors shadow-sm"
        >
          <Plus className="w-5 h-5" />
          Add Workout Day
        </button>
      </div>
    </div>
  );
}