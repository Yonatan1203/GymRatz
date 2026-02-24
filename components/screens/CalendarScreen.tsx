import { ChevronLeft, ChevronRight, CheckCircle2, Circle, XCircle, Scale } from 'lucide-react';
import { useState } from 'react';

export default function CalendarScreen() {
  const [currentMonth, setCurrentMonth] = useState('February 2026');
  const [showWeightLog, setShowWeightLog] = useState(false);
  const [newWeight, setNewWeight] = useState('');
  
  const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  // Sample calendar data (0 = empty, 1 = completed, 2 = scheduled, 3 = missed)
  const calendarDays = [
    0, 0, 0, 0, 0, 1, 2, // Week 1
    1, 3, 1, 1, 2, 1, 2, // Week 2
    1, 1, 0, 0, 0, 0, 0, // Week 3
    0, 0, 0, 0, 0, 0, 0, // Week 4
    0, 0, 0, 0, 0, 0, 0, // Week 5
  ];

  const completedWorkouts = 9;
  const totalWorkouts = 12;
  const completionPercentage = Math.round((completedWorkouts / totalWorkouts) * 100);

  const getDayStyle = (status: number, index: number) => {
    const dayNumber = index - 4; // Adjust for month starting
    if (dayNumber < 1 || dayNumber > 28) return 'invisible';
    
    switch (status) {
      case 1: // completed
        return 'bg-primary text-white shadow-md';
      case 2: // scheduled
        return 'bg-secondary text-white shadow-md';
      case 3: // missed
        return 'bg-destructive/20 text-destructive dark:bg-orange-500/20 dark:text-orange-400 shadow-sm';
      default: // empty
        return 'bg-card border border-border text-muted-foreground shadow-sm';
    }
  };

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="bg-card border-b border-border shadow-md">
        <div className="max-w-md mx-auto px-6 pt-12 pb-6">
          <h1 className="text-foreground mb-6">Workout Calendar</h1>

          {/* Month Navigation */}
          <div className="flex items-center justify-between mb-6">
            <button className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center shadow-sm hover:shadow-md transition-shadow">
              <ChevronLeft className="w-5 h-5 text-foreground" />
            </button>
            <h2 className="text-foreground">{currentMonth}</h2>
            <button className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center shadow-sm hover:shadow-md transition-shadow">
              <ChevronRight className="w-5 h-5 text-foreground" />
            </button>
          </div>

          {/* Completion Ring */}
          <div className="bg-gradient-to-br from-primary to-accent rounded-xl p-6 shadow-lg mb-6">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-white/80 text-sm mb-1">Monthly Progress</div>
                <div className="text-3xl font-semibold text-white mb-1">{completionPercentage}%</div>
                <div className="text-white/70 text-sm">{completedWorkouts} of {totalWorkouts} workouts</div>
              </div>
              <div className="relative w-20 h-20">
                <svg className="w-20 h-20 transform -rotate-90" viewBox="0 0 80 80">
                  <circle
                    cx="40"
                    cy="40"
                    r="32"
                    stroke="white"
                    strokeOpacity="0.2"
                    strokeWidth="6"
                    fill="none"
                  />
                  <circle
                    cx="40"
                    cy="40"
                    r="32"
                    stroke="white"
                    strokeWidth="6"
                    fill="none"
                    strokeDasharray={`${2 * Math.PI * 32}`}
                    strokeDashoffset={`${2 * Math.PI * 32 * (1 - completionPercentage / 100)}`}
                    strokeLinecap="round"
                  />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Calendar Grid */}
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Day Headers */}
        <div className="grid grid-cols-7 gap-2 mb-3">
          {daysOfWeek.map(day => (
            <div key={day} className="text-center text-xs font-semibold text-muted-foreground">
              {day}
            </div>
          ))}
        </div>

        {/* Calendar Days */}
        <div className="grid grid-cols-7 gap-2 mb-6">
          {calendarDays.map((status, index) => {
            const dayNumber = index - 4;
            return (
              <button
                key={index}
                className={`aspect-square rounded-lg flex items-center justify-center text-sm font-medium transition-all hover:scale-105 ${getDayStyle(status, index)}`}
              >
                {dayNumber > 0 && dayNumber <= 28 ? dayNumber : ''}
              </button>
            );
          })}
        </div>

        {/* Legend */}
        <div className="bg-card border border-border rounded-xl p-4 shadow-md">
          <div className="text-sm font-semibold text-foreground mb-3">Legend</div>
          <div className="space-y-2">
            <div className="flex items-center gap-3">
              <div className="w-6 h-6 rounded bg-primary shadow-sm"></div>
              <span className="text-sm text-foreground">Completed</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-6 h-6 rounded bg-secondary shadow-sm"></div>
              <span className="text-sm text-foreground">Scheduled</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-6 h-6 rounded bg-destructive/20 border border-destructive/30 shadow-sm"></div>
              <span className="text-sm text-foreground">Missed</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="w-6 h-6 rounded bg-card border border-border shadow-sm"></div>
              <span className="text-sm text-foreground">Rest Day</span>
            </div>
          </div>
        </div>

        {/* Streak Info */}
        <div className="mt-6 grid grid-cols-2 gap-3">
          <div className="bg-card border border-border rounded-lg p-4 text-center shadow-md">
            <div className="text-2xl font-semibold text-primary mb-1">12 🔥</div>
            <div className="text-xs text-muted-foreground">Current Streak</div>
          </div>
          <div className="bg-card border border-border rounded-lg p-4 text-center shadow-md">
            <div className="text-2xl font-semibold text-secondary mb-1">18 ⚡</div>
            <div className="text-xs text-muted-foreground">Best Streak</div>
          </div>
        </div>

        {/* Weight Logging */}
        <div className="mt-6 bg-card border border-border rounded-xl p-5 shadow-md">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Scale className="w-5 h-5 text-primary" />
              <h3 className="text-foreground font-medium">Log Your Weight 📊</h3>
            </div>
          </div>
          
          {!showWeightLog ? (
            <button
              onClick={() => setShowWeightLog(true)}
              className="w-full py-3 bg-primary text-primary-foreground rounded-lg font-medium shadow-sm hover:shadow-md transition-shadow"
            >
              + Add Weight Entry
            </button>
          ) : (
            <div className="space-y-3">
              <div>
                <label className="block text-sm text-muted-foreground mb-1.5">Weight (lbs)</label>
                <input
                  type="number"
                  value={newWeight}
                  onChange={(e) => setNewWeight(e.target.value)}
                  placeholder="e.g., 175"
                  className="w-full px-4 py-2.5 bg-muted border border-border rounded-lg text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary shadow-sm"
                  step="0.1"
                />
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => {
                    // Save weight logic here
                    setNewWeight('');
                    setShowWeightLog(false);
                  }}
                  className="flex-1 py-2 bg-primary text-primary-foreground rounded-lg font-medium shadow-sm hover:shadow-md transition-shadow"
                >
                  Save
                </button>
                <button
                  onClick={() => {
                    setNewWeight('');
                    setShowWeightLog(false);
                  }}
                  className="flex-1 py-2 bg-muted text-foreground rounded-lg font-medium shadow-sm hover:shadow-md transition-shadow"
                >
                  Cancel
                </button>
              </div>
            </div>
          )}
          
          <div className="mt-4 pt-4 border-t border-border">
            <div className="text-sm text-muted-foreground mb-2">Recent Entries</div>
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="text-foreground">Feb 12, 2026</span>
                <span className="font-medium text-primary">175.2 lbs</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-foreground">Feb 5, 2026</span>
                <span className="font-medium text-foreground">176.8 lbs</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-foreground">Jan 29, 2026</span>
                <span className="font-medium text-foreground">177.5 lbs</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}