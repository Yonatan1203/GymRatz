import { ArrowLeft, Play, Clock, Dumbbell, ChevronDown, Moon, Sun } from 'lucide-react';
import { Link, useParams } from 'react-router';
import { useState } from 'react';
import { useTheme } from '../ThemeContext';

export default function ProgramDetailScreen() {
  const { id } = useParams();
  const [expandedWeek, setExpandedWeek] = useState(1);
  const { theme, toggleTheme } = useTheme();

  const program = {
    name: 'Push Pull Legs',
    description: 'A comprehensive 6-day training split focusing on push, pull, and leg movements',
    weeks: 8,
    workouts: 48,
    difficulty: 'Intermediate',
    progress: 65,
  };

  const weeks = [
    {
      week: 1,
      workouts: [
        { day: 'Monday', name: 'Push - Chest Focus', exercises: 6, duration: '60 min' },
        { day: 'Tuesday', name: 'Pull - Back Width', exercises: 6, duration: '55 min' },
        { day: 'Wednesday', name: 'Legs - Quad Focus', exercises: 7, duration: '70 min' },
        { day: 'Thursday', name: 'Push - Shoulder Focus', exercises: 5, duration: '50 min' },
        { day: 'Friday', name: 'Pull - Back Thickness', exercises: 6, duration: '55 min' },
        { day: 'Saturday', name: 'Legs - Hamstring Focus', exercises: 6, duration: '65 min' },
      ]
    },
    {
      week: 2,
      workouts: [
        { day: 'Monday', name: 'Push - Volume Day', exercises: 7, duration: '65 min' },
        { day: 'Tuesday', name: 'Pull - Heavy Day', exercises: 5, duration: '60 min' },
        { day: 'Wednesday', name: 'Legs - Power Day', exercises: 6, duration: '75 min' },
      ]
    }
  ];

  return (
    <div className="min-h-screen bg-background pb-6">
      {/* Header */}
      <div className="bg-gradient-to-br from-primary to-accent text-white shadow-lg">
        <div className="max-w-md mx-auto px-6 pt-12 pb-6">
          <Link to="/programs" className="inline-flex items-center gap-2 mb-6 text-white/90 hover:text-white">
            <ArrowLeft className="w-5 h-5" />
            <span>Back</span>
          </Link>

          <h1 className="text-white mb-2">{program.name}</h1>
          <p className="text-white/80 text-sm mb-4">{program.description}</p>

          <div className="flex items-center gap-4 text-sm text-white/90 mb-4">
            <div className="flex items-center gap-1">
              <Clock className="w-4 h-4" />
              <span>{program.weeks} weeks</span>
            </div>
            <div className="flex items-center gap-1">
              <Dumbbell className="w-4 h-4" />
              <span>{program.workouts} workouts</span>
            </div>
            <div className="px-2 py-1 bg-white/20 rounded-full text-xs font-medium shadow-sm">
              {program.difficulty}
            </div>
          </div>

          {/* Progress */}
          <div className="bg-white/10 rounded-lg p-3 shadow-md">
            <div className="flex items-center justify-between text-xs mb-2">
              <span className="text-white/80">Overall Progress</span>
              <span className="text-white font-semibold">{program.progress}%</span>
            </div>
            <div className="h-2 bg-white/20 rounded-full overflow-hidden">
              <div
                className="h-full bg-white rounded-full shadow-sm"
                style={{ width: `${program.progress}%` }}
              ></div>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-md mx-auto px-6 py-6">
        {/* Action Buttons */}
        <div className="grid grid-cols-2 gap-3 mb-6">
          <Link to="/workout/1" className="bg-primary text-primary-foreground rounded-lg py-3 px-4 flex items-center justify-center gap-2 font-medium shadow-md hover:shadow-lg transition-shadow">
            <Play className="w-5 h-5" />
            <span>Continue</span>
          </Link>
          <button className="bg-card border border-border text-foreground rounded-lg py-3 px-4 font-medium shadow-md hover:shadow-lg transition-shadow">
            Restart Program
          </button>
        </div>

        {/* Weekly Breakdown */}
        <div className="mb-4">
          <h2 className="text-foreground mb-4">Weekly Breakdown</h2>
          
          <div className="space-y-3">
            {weeks.map((weekData) => (
              <div key={weekData.week} className="bg-card border border-border rounded-xl overflow-hidden shadow-lg">
                <button
                  onClick={() => setExpandedWeek(expandedWeek === weekData.week ? 0 : weekData.week)}
                  className="w-full flex items-center justify-between p-4 hover:bg-muted/50 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-gradient-to-br from-primary to-accent rounded-lg flex items-center justify-center text-white font-semibold shadow-md">
                      {weekData.week}
                    </div>
                    <div className="text-left">
                      <div className="font-medium text-foreground">Week {weekData.week}</div>
                      <div className="text-xs text-muted-foreground">{weekData.workouts.length} workouts</div>
                    </div>
                  </div>
                  <ChevronDown
                    className={`w-5 h-5 text-muted-foreground transition-transform ${
                      expandedWeek === weekData.week ? 'rotate-180' : ''
                    }`}
                  />
                </button>

                {expandedWeek === weekData.week && (
                  <div className="border-t border-border">
                    {weekData.workouts.map((workout, index) => (
                      <Link
                        key={index}
                        to={`/workout/${weekData.week}-${index + 1}`}
                        className={`flex items-center justify-between p-4 hover:bg-muted/50 transition-colors ${
                          index < weekData.workouts.length - 1 ? 'border-b border-border' : ''
                        }`}
                      >
                        <div>
                          <div className="text-sm font-medium text-foreground mb-1">{workout.name}</div>
                          <div className="text-xs text-muted-foreground">{workout.day}</div>
                        </div>
                        <div className="text-right text-xs text-muted-foreground">
                          <div>{workout.exercises} exercises</div>
                          <div>{workout.duration}</div>
                        </div>
                      </Link>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Program Info */}
        <div className="bg-card border border-border rounded-xl p-5 shadow-md">
          <h3 className="text-foreground mb-3">About This Program</h3>
          <p className="text-sm text-muted-foreground leading-relaxed mb-4">
            This push-pull-legs routine is designed for intermediate to advanced lifters looking to maximize muscle growth 
            and strength. Each muscle group is trained twice per week with optimal volume and intensity.
          </p>
          <div className="space-y-2 text-sm">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-primary"></div>
              <span className="text-foreground">Progressive overload principles</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-primary"></div>
              <span className="text-foreground">Balanced muscle development</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-primary"></div>
              <span className="text-foreground">Built-in deload weeks</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}