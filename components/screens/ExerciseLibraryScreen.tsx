import { ArrowLeft, Search, Filter, Dumbbell, Heart, Plus } from 'lucide-react';
import { Link } from 'react-router';
import { useState } from 'react';

type ExerciseCategory = 'All' | 'Chest' | 'Back' | 'Legs' | 'Shoulders' | 'Arms' | 'Core';
type ExerciseType = 'Compound' | 'Isolation' | 'Bodyweight';
type EquipmentType = 'All' | 'Dumbbell' | 'Barbell' | 'Machine' | 'Body Weight';

interface Exercise {
  id: number;
  name: string;
  category: ExerciseCategory;
  type: ExerciseType;
  muscle: string;
  equipment: EquipmentType;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  isFavorite: boolean;
}

export default function ExerciseLibraryScreen() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<ExerciseCategory>('All');
  const [selectedEquipment, setSelectedEquipment] = useState<EquipmentType>('All');
  const [favorites, setFavorites] = useState<number[]>([1, 5, 12]);

  const categories: ExerciseCategory[] = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];
  const equipmentTypes: EquipmentType[] = ['All', 'Dumbbell', 'Barbell', 'Machine', 'Body Weight'];

  const exercises: Exercise[] = [
    { id: 1, name: 'Barbell Bench Press', category: 'Chest', type: 'Compound', muscle: 'Pectorals', equipment: 'Barbell', difficulty: 'Intermediate', isFavorite: true },
    { id: 2, name: 'Incline Dumbbell Press', category: 'Chest', type: 'Compound', muscle: 'Upper Chest', equipment: 'Dumbbell', difficulty: 'Intermediate', isFavorite: false },
    { id: 3, name: 'Cable Flyes', category: 'Chest', type: 'Isolation', muscle: 'Pectorals', equipment: 'Machine', difficulty: 'Beginner', isFavorite: false },
    { id: 4, name: 'Push Ups', category: 'Chest', type: 'Bodyweight', muscle: 'Pectorals', equipment: 'Body Weight', difficulty: 'Beginner', isFavorite: false },
    { id: 5, name: 'Deadlift', category: 'Back', type: 'Compound', muscle: 'Full Back', equipment: 'Barbell', difficulty: 'Advanced', isFavorite: true },
    { id: 6, name: 'Barbell Row', category: 'Back', type: 'Compound', muscle: 'Lats', equipment: 'Barbell', difficulty: 'Intermediate', isFavorite: false },
    { id: 7, name: 'Pull Ups', category: 'Back', type: 'Bodyweight', muscle: 'Lats', equipment: 'Body Weight', difficulty: 'Intermediate', isFavorite: false },
    { id: 8, name: 'Lat Pulldown', category: 'Back', type: 'Isolation', muscle: 'Lats', equipment: 'Machine', difficulty: 'Beginner', isFavorite: false },
    { id: 9, name: 'Back Squat', category: 'Legs', type: 'Compound', muscle: 'Quads', equipment: 'Barbell', difficulty: 'Intermediate', isFavorite: false },
    { id: 10, name: 'Romanian Deadlift', category: 'Legs', type: 'Compound', muscle: 'Hamstrings', equipment: 'Barbell', difficulty: 'Intermediate', isFavorite: false },
    { id: 11, name: 'Leg Press', category: 'Legs', type: 'Compound', muscle: 'Quads', equipment: 'Machine', difficulty: 'Beginner', isFavorite: false },
    { id: 12, name: 'Walking Lunges', category: 'Legs', type: 'Compound', muscle: 'Quads', equipment: 'Dumbbell', difficulty: 'Intermediate', isFavorite: true },
    { id: 13, name: 'Overhead Press', category: 'Shoulders', type: 'Compound', muscle: 'Deltoids', equipment: 'Barbell', difficulty: 'Intermediate', isFavorite: false },
    { id: 14, name: 'Lateral Raises', category: 'Shoulders', type: 'Isolation', muscle: 'Side Delts', equipment: 'Dumbbell', difficulty: 'Beginner', isFavorite: false },
    { id: 15, name: 'Face Pulls', category: 'Shoulders', type: 'Isolation', muscle: 'Rear Delts', equipment: 'Machine', difficulty: 'Beginner', isFavorite: false },
    { id: 16, name: 'Barbell Curl', category: 'Arms', type: 'Isolation', muscle: 'Biceps', equipment: 'Barbell', difficulty: 'Beginner', isFavorite: false },
    { id: 17, name: 'Tricep Pushdown', category: 'Arms', type: 'Isolation', muscle: 'Triceps', equipment: 'Machine', difficulty: 'Beginner', isFavorite: false },
    { id: 18, name: 'Hammer Curls', category: 'Arms', type: 'Isolation', muscle: 'Biceps', equipment: 'Dumbbell', difficulty: 'Beginner', isFavorite: false },
    { id: 19, name: 'Plank', category: 'Core', type: 'Bodyweight', muscle: 'Abs', equipment: 'Body Weight', difficulty: 'Beginner', isFavorite: false },
    { id: 20, name: 'Russian Twists', category: 'Core', type: 'Bodyweight', muscle: 'Obliques', equipment: 'Body Weight', difficulty: 'Intermediate', isFavorite: false },
  ];

  const toggleFavorite = (id: number) => {
    setFavorites(prev => 
      prev.includes(id) ? prev.filter(fav => fav !== id) : [...prev, id]
    );
  };

  const filteredExercises = exercises
    .filter(ex => selectedCategory === 'All' || ex.category === selectedCategory)
    .filter(ex => selectedEquipment === 'All' || ex.equipment === selectedEquipment)
    .filter(ex => ex.name.toLowerCase().includes(searchQuery.toLowerCase()))
    .map(ex => ({ ...ex, isFavorite: favorites.includes(ex.id) }));

  const favoriteExercises = filteredExercises.filter(ex => ex.isFavorite);

  return (
    <div className="min-h-screen bg-background pb-20">
      {/* Header */}
      <div className="bg-card border-b border-border shadow-md sticky top-0 z-10">
        <div className="max-w-md mx-auto px-6 pt-12 pb-4">
          <div className="flex items-center gap-3 mb-4">
            <Link to="/home" className="p-2 -ml-2 hover:bg-muted rounded-lg transition-colors">
              <ArrowLeft className="w-5 h-5 text-foreground" />
            </Link>
            <h1 className="text-foreground">Exercise Library 💪</h1>
          </div>

          {/* Search Bar */}
          <div className="relative mb-4">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search exercises..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-muted border border-border rounded-lg text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary shadow-sm"
            />
          </div>

          {/* Category Filters */}
          <div className="flex gap-2 overflow-x-auto pb-2 -mx-6 px-6 scrollbar-hide">
            {categories.map((category) => (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-all shadow-sm ${
                  selectedCategory === category
                    ? 'bg-primary text-primary-foreground shadow-md'
                    : 'bg-muted text-muted-foreground hover:bg-muted/80'
                }`}
              >
                {category}
              </button>
            ))}
          </div>

          {/* Equipment Filters */}
          <div className="flex gap-2 overflow-x-auto pb-2 -mx-6 px-6 scrollbar-hide">
            {equipmentTypes.map((equipment) => (
              <button
                key={equipment}
                onClick={() => setSelectedEquipment(equipment)}
                className={`px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-all shadow-sm ${
                  selectedEquipment === equipment
                    ? 'bg-primary text-primary-foreground shadow-md'
                    : 'bg-muted text-muted-foreground hover:bg-muted/80'
                }`}
              >
                {equipment}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Favorites Section */}
        {favoriteExercises.length > 0 && (
          <div className="mb-6">
            <h2 className="text-foreground mb-3">Favorites</h2>
            <div className="space-y-2">
              {favoriteExercises.map((exercise) => (
                <div
                  key={exercise.id}
                  className="bg-card border border-border rounded-xl p-4 shadow-md hover:shadow-lg transition-shadow"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <Dumbbell className="w-4 h-4 text-primary" />
                        <h3 className="text-foreground font-medium">{exercise.name}</h3>
                      </div>
                      <div className="flex items-center gap-3 text-xs text-muted-foreground">
                        <span className="px-2 py-1 bg-muted rounded text-xs">{exercise.type}</span>
                        <span>{exercise.muscle}</span>
                        <span>•</span>
                        <span>{exercise.equipment}</span>
                      </div>
                    </div>
                    <button
                      onClick={() => toggleFavorite(exercise.id)}
                      className="p-2 hover:bg-muted rounded-lg transition-colors"
                    >
                      <Heart className={`w-5 h-5 ${exercise.isFavorite ? 'fill-red-500 text-red-500' : 'text-muted-foreground'}`} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* All Exercises */}
        <div>
          <h2 className="text-foreground mb-3">
            {selectedCategory === 'All' ? 'All Exercises' : `${selectedCategory} Exercises`}
          </h2>
          <div className="space-y-2">
            {filteredExercises.filter(ex => !ex.isFavorite).map((exercise) => (
              <div
                key={exercise.id}
                className="bg-card border border-border rounded-xl p-4 shadow-md hover:shadow-lg transition-shadow"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <Dumbbell className="w-4 h-4 text-primary" />
                      <h3 className="text-foreground font-medium">{exercise.name}</h3>
                    </div>
                    <div className="flex items-center gap-3 text-xs text-muted-foreground mb-2">
                      <span className="px-2 py-1 bg-muted rounded text-xs">{exercise.type}</span>
                      <span>{exercise.muscle}</span>
                      <span>•</span>
                      <span>{exercise.equipment}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className={`text-xs px-2 py-1 rounded ${
                        exercise.difficulty === 'Beginner' ? 'bg-accent/20 text-accent' :
                        exercise.difficulty === 'Intermediate' ? 'bg-primary/20 text-primary' :
                        'bg-secondary/20 text-secondary'
                      }`}>
                        {exercise.difficulty}
                      </span>
                    </div>
                  </div>
                  <button
                    onClick={() => toggleFavorite(exercise.id)}
                    className="p-2 hover:bg-muted rounded-lg transition-colors"
                  >
                    <Heart className={`w-5 h-5 ${exercise.isFavorite ? 'fill-red-500 text-red-500' : 'text-muted-foreground'}`} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {filteredExercises.length === 0 && (
          <div className="text-center py-12">
            <Dumbbell className="w-12 h-12 text-muted-foreground mx-auto mb-3 opacity-50" />
            <p className="text-muted-foreground">No exercises found</p>
          </div>
        )}
      </div>
    </div>
  );
}