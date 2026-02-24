import { Link } from 'react-router';
import { Dumbbell } from 'lucide-react';

export default function Onboarding01Welcome() {
  return (
    <div className="min-h-screen bg-background relative overflow-hidden">
      {/* Background Image */}
      <div className="absolute inset-0">
        <img
          src="https://images.unsplash.com/photo-1741156229623-da94e6d7977d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmaXRuZXNzJTIwZ3ltJTIwd29ya291dCUyMG1vdGl2YXRpb258ZW58MXx8fHwxNzcwNzczMTU2fDA&ixlib=rb-4.1.0&q=80&w=1080"
          alt="Fitness"
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-black/60 via-black/40 to-black/80" />
      </div>

      {/* Content */}
      <div className="relative min-h-screen flex flex-col">
        <div className="flex-1 flex flex-col justify-center px-6 max-w-md mx-auto w-full">
          {/* Logo/Brand */}
          <div className="text-center mb-8">
            <div className="w-20 h-20 bg-gradient-to-br from-primary to-accent rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-2xl">
              <Dumbbell className="w-10 h-10 text-white" />
            </div>
            <h1 className="text-5xl font-bold text-white mb-2">GymRatz</h1>
          </div>

          {/* Award Badge */}
          <div className="flex items-center justify-center gap-3 mb-8">
            <div className="flex gap-0.5">
              {[...Array(5)].map((_, i) => (
                <span key={i} className="text-secondary text-xl">★</span>
              ))}
            </div>
          </div>
          <div className="text-center text-white/90 mb-2">
            <div className="font-semibold">Best Fitness Tracking App</div>
            <div className="text-sm text-white/70">on App Store</div>
          </div>

          {/* Tagline */}
          <h2 className="text-3xl font-bold text-white text-center mb-4 mt-12">
            Transform Your Life
          </h2>
          <p className="text-white/80 text-center mb-12 text-lg">
            Track your workouts, smash PRs, and level up your fitness journey
          </p>
        </div>

        {/* CTA Button */}
        <div className="px-6 pb-12 max-w-md mx-auto w-full">
          <Link
            to="/onboarding/goal"
            className="block w-full bg-white text-foreground rounded-2xl py-4 font-semibold text-center shadow-2xl hover:shadow-xl transition-shadow"
          >
            Let's get started!
          </Link>
          <p className="text-center text-white/60 text-xs mt-4">
            By signing in, you agree to our Terms and Privacy Policy.
          </p>
        </div>
      </div>
    </div>
  );
}
