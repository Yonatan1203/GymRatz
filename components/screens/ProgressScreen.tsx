import { ArrowLeft, TrendingUp, Dumbbell, Award, ChevronDown, Moon, Sun } from 'lucide-react';
import { Link } from 'react-router';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { useState } from 'react';
import { useTheme } from '../ThemeContext';

export default function ProgressScreen() {
  const [selectedMetric, setSelectedMetric] = useState('volume');
  const [selectedExercise, setSelectedExercise] = useState('all');
  const [selectedView, setSelectedView] = useState<'exercise' | 'weight'>('exercise');
  const { theme, toggleTheme } = useTheme();

  const exercises = [
    { id: 'all', name: 'All Exercises' },
    { id: 'bench', name: 'Bench Press' },
    { id: 'squat', name: 'Squat' },
    { id: 'deadlift', name: 'Deadlift' },
    { id: 'ohp', name: 'Overhead Press' },
  ];

  const volumeData = [
    { date: 'Jan 15', value: 8500 },
    { date: 'Jan 22', value: 9200 },
    { date: 'Jan 29', value: 9800 },
    { date: 'Feb 5', value: 10500 },
    { date: 'Feb 12', value: 11200 },
  ];

  const benchData = [
    { date: 'Jan 15', value: 185 },
    { date: 'Jan 22', value: 195 },
    { date: 'Jan 29', value: 205 },
    { date: 'Feb 5', value: 215 },
    { date: 'Feb 12', value: 225 },
  ];

  const weightData = [
    { date: 'Jan 15', value: 177.5 },
    { date: 'Jan 22', value: 177.0 },
    { date: 'Jan 29', value: 176.5 },
    { date: 'Feb 5', value: 176.0 },
    { date: 'Feb 12', value: 175.2 },
  ];

  const currentData = selectedView === 'weight' ? weightData : (selectedExercise === 'bench' ? benchData : volumeData);

  const personalRecords = [
    { exercise: 'Barbell Bench Press', weight: 225, unit: 'lbs', date: 'Feb 10, 2026', improvement: '+10 lbs' },
    { exercise: 'Barbell Squat', weight: 315, unit: 'lbs', date: 'Feb 8, 2026', improvement: '+15 lbs' },
    { exercise: 'Deadlift', weight: 405, unit: 'lbs', date: 'Feb 5, 2026', improvement: '+20 lbs' },
    { exercise: 'Overhead Press', weight: 145, unit: 'lbs', date: 'Feb 3, 2026', improvement: '+5 lbs' },
  ];

  return (
    <div className="min-h-screen bg-background pb-6">
      {/* Header */}
      <div className="bg-gradient-to-br from-primary to-accent text-white shadow-lg">
        <div className="max-w-md mx-auto px-6 pt-12 pb-6">
          <Link to="/home" className="inline-flex items-center gap-2 mb-6 text-white/90 hover:text-white">
            <ArrowLeft className="w-5 h-5" />
            <span>Back</span>
          </Link>

          <h1 className="text-white mb-6">Progress Tracking</h1>

          {/* Quick Stats */}
          <div className="grid grid-cols-3 gap-3">
            <div className="bg-white/10 rounded-lg p-3 text-center shadow-md">
              <div className="text-2xl font-semibold text-white mb-1">24</div>
              <div className="text-xs text-white/70">Total Workouts</div>
            </div>
            <div className="bg-white/10 rounded-lg p-3 text-center shadow-md">
              <div className="text-2xl font-semibold text-white mb-1">12</div>
              <div className="text-xs text-white/70">Day Streak</div>
            </div>
            <div className="bg-white/10 rounded-lg p-3 text-center shadow-md">
              <div className="text-2xl font-semibold text-white mb-1">4</div>
              <div className="text-xs text-white/70">New PRs</div>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Chart Section */}
        <div className="bg-card border border-border rounded-xl p-5 mb-6 shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-foreground">Progress 📈</h2>
            <button className="flex items-center gap-1 text-sm text-primary">
              <span>Last 5 weeks</span>
              <ChevronDown className="w-4 h-4" />
            </button>
          </div>

          {/* View Toggle */}
          <div className="mb-4 flex gap-2">
            <button
              onClick={() => setSelectedView('exercise')}
              className={`flex-1 py-2 px-3 rounded-lg text-sm font-medium transition-colors ${
                selectedView === 'exercise'
                  ? 'bg-primary text-primary-foreground shadow-sm'
                  : 'bg-muted text-foreground hover:bg-muted/80'
              }`}
            >
              Exercise Progress
            </button>
            <button
              onClick={() => setSelectedView('weight')}
              className={`flex-1 py-2 px-3 rounded-lg text-sm font-medium transition-colors ${
                selectedView === 'weight'
                  ? 'bg-primary text-primary-foreground shadow-sm'
                  : 'bg-muted text-foreground hover:bg-muted/80'
              }`}
            >
              Body Weight
            </button>
          </div>

          {/* Exercise Selector */}
          {selectedView === 'exercise' && (
            <div className="mb-4 flex gap-2 overflow-x-auto pb-2">
              {exercises.map((exercise) => (
                <button
                  key={exercise.id}
                  onClick={() => setSelectedExercise(exercise.id)}
                  className={`px-3 py-1.5 rounded-lg text-sm font-medium whitespace-nowrap transition-colors ${
                    selectedExercise === exercise.id
                      ? 'bg-primary text-primary-foreground shadow-sm'
                      : 'bg-muted text-foreground hover:bg-muted/80'
                  }`}
                >
                  {exercise.name}
                </button>
              ))}
            </div>
          )}

          <div className="h-64 mb-4 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={currentData} margin={{ top: 5, right: 5, left: -20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E8E8EA" />
                <XAxis 
                  dataKey="date" 
                  stroke="#6E6E73" 
                  style={{ fontSize: '12px' }}
                />
                <YAxis 
                  stroke="#6E6E73" 
                  style={{ fontSize: '12px' }}
                />
                <Tooltip 
                  contentStyle={{
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #E8E8EA',
                    borderRadius: '8px',
                    boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
                  }}
                />
                <Line 
                  type="monotone" 
                  dataKey="value" 
                  stroke="#8B3A3A" 
                  strokeWidth={3}
                  dot={{ fill: '#8B3A3A', r: 5 }}
                  activeDot={{ r: 7 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          <div className="flex gap-2">
            <button className="flex-1 py-2 px-3 rounded-lg bg-primary text-primary-foreground text-sm font-medium shadow-sm">
              Volume
            </button>
            <button className="flex-1 py-2 px-3 rounded-lg bg-muted text-foreground text-sm font-medium shadow-sm">
              Frequency
            </button>
            <button className="flex-1 py-2 px-3 rounded-lg bg-muted text-foreground text-sm font-medium shadow-sm">
              Intensity
            </button>
          </div>
        </div>

        {/* Personal Records */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-foreground">Personal Records 🏆</h2>
            <button className="text-sm text-primary">View All</button>
          </div>

          <div className="space-y-3">
            {personalRecords.map((record, index) => (
              <div key={index} className="bg-card border border-border rounded-xl p-4 shadow-md hover:shadow-lg transition-shadow">
                <div className="flex items-start justify-between mb-2">
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 bg-gradient-to-br from-primary to-accent rounded-lg flex items-center justify-center flex-shrink-0 shadow-sm">
                      <Award className="w-5 h-5 text-white" />
                    </div>
                    <div>
                      <h3 className="text-foreground font-medium text-sm mb-1">{record.exercise}</h3>
                      <p className="text-xs text-muted-foreground">{record.date}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-xl font-semibold text-primary">{record.weight}</div>
                    <div className="text-xs text-muted-foreground">{record.unit}</div>
                  </div>
                </div>
                <div className="flex items-center justify-end">
                  <div className="inline-flex items-center gap-1 px-2 py-1 bg-primary/10 rounded-full">
                    <TrendingUp className="w-3 h-3 text-primary" />
                    <span className="text-xs font-medium text-primary">{record.improvement}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Body Metrics */}
        <div className="bg-card border border-border rounded-xl p-5 shadow-lg">
          <h3 className="text-foreground mb-4">Body Metrics</h3>
          
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 bg-muted rounded-lg shadow-sm">
              <span className="text-sm text-foreground">Body Weight</span>
              <div className="text-right">
                <div className="font-semibold text-foreground">185 lbs</div>
                <div className="text-xs text-primary">+2 lbs</div>
              </div>
            </div>
            
            <div className="flex items-center justify-between p-3 bg-muted rounded-lg shadow-sm">
              <span className="text-sm text-foreground">Body Fat %</span>
              <div className="text-right">
                <div className="font-semibold text-foreground">15.2%</div>
                <div className="text-xs text-primary">-0.8%</div>
              </div>
            </div>

            <div className="flex items-center justify-between p-3 bg-muted rounded-lg shadow-sm">
              <span className="text-sm text-foreground">Muscle Mass</span>
              <div className="text-right">
                <div className="font-semibold text-foreground">157 lbs</div>
                <div className="text-xs text-primary">+3 lbs</div>
              </div>
            </div>
          </div>

          <button className="w-full mt-4 py-2 border border-border rounded-lg text-sm text-foreground font-medium hover:bg-muted transition-colors shadow-sm">
            Update Metrics
          </button>
        </div>
      </div>
    </div>
  );
}