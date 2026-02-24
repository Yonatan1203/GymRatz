import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router';
import OnboardingProgress from './OnboardingProgress';

export default function Onboarding12Weight() {
  const navigate = useNavigate();
  const [weight, setWeight] = useState(70);
  const scrollRef = useRef<HTMLDivElement>(null);
  const itemWidth = 80;

  // Generate weight values (30-200 kg)
  const weights = Array.from({ length: 171 }, (_, i) => 30 + i);

  // Calculate BMI (using default height of 170cm for now)
  const height = 170; // In a real app, get this from state/context
  const bmi = ((weight / (height / 100) ** 2)).toFixed(1);
  
  const getBMICategory = (bmi: number) => {
    if (bmi < 18.5) return { label: 'Underweight', color: 'text-yellow-500' };
    if (bmi < 25) return { label: 'Healthy', color: 'text-green-500' };
    if (bmi < 30) return { label: 'Overweight', color: 'text-orange-500' };
    return { label: 'Obese', color: 'text-red-500' };
  };

  const category = getBMICategory(parseFloat(bmi));

  useEffect(() => {
    // Center the initial value
    if (scrollRef.current) {
      const index = weights.indexOf(weight);
      scrollRef.current.scrollLeft = index * itemWidth;
    }
  }, []);

  useEffect(() => {
    let timeoutId: NodeJS.Timeout;

    const handleScroll = () => {
      if (!scrollRef.current) return;
      
      // Clear existing timeout
      clearTimeout(timeoutId);
      
      // Update value during scroll
      const scrollLeft = scrollRef.current.scrollLeft;
      const index = Math.round(scrollLeft / itemWidth);
      const newWeight = weights[Math.max(0, Math.min(index, weights.length - 1))];
      
      if (newWeight && newWeight !== weight) {
        setWeight(newWeight);
      }

      // Snap to position after scrolling stops
      timeoutId = setTimeout(() => {
        if (scrollRef.current) {
          const finalIndex = Math.round(scrollRef.current.scrollLeft / itemWidth);
          scrollRef.current.scrollTo({
            left: finalIndex * itemWidth,
            behavior: 'smooth'
          });
        }
      }, 100);
    };

    const scrollElement = scrollRef.current;
    if (scrollElement) {
      scrollElement.addEventListener('scroll', handleScroll);
    }

    return () => {
      if (scrollElement) {
        scrollElement.removeEventListener('scroll', handleScroll);
      }
      clearTimeout(timeoutId);
    };
  }, [weight, weights, itemWidth]);

  const handleContinue = () => {
    navigate('/onboarding/summary');
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <OnboardingProgress currentStep={7} totalSteps={14} />

      <div className="flex-1 flex flex-col justify-center px-6 max-w-md mx-auto w-full py-8">
        <h1 className="text-foreground text-2xl sm:text-3xl font-bold mb-2 sm:mb-3 text-center">
          What's your current weight?
        </h1>
        <p className="text-muted-foreground mb-12 text-sm sm:text-base text-center">
          Remember, this is just a starting point - your worth isn't defined by a number!
        </p>

        {/* Picker Container */}
        <div className="relative mb-8">
          {/* Horizontal Scrollable Picker */}
          <div className="relative">
            <div
              ref={scrollRef}
              className="overflow-x-auto scrollbar-hide relative"
              style={{ 
                WebkitOverflowScrolling: 'touch',
                overscrollBehavior: 'contain'
              }}
            >
              <div className="flex">
                <div style={{ width: '50%' }} /> {/* Left padding */}
                {weights.map((w) => (
                  <div
                    key={w}
                    className="flex flex-col items-center flex-shrink-0"
                    style={{ width: `${itemWidth}px` }}
                  >
                    {/* Value at top */}
                    <div className="h-12 flex items-center justify-center">
                      {w === weight ? (
                        <span className="text-4xl font-bold text-foreground whitespace-nowrap">
                          {w} <span className="text-xl text-muted-foreground">kg</span>
                        </span>
                      ) : (
                        <span className="text-lg text-muted-foreground/50">
                          {w}
                        </span>
                      )}
                    </div>

                    {/* Tick marks below */}
                    <div className="flex flex-col items-center">
                      {w % 5 === 0 ? (
                        // Major tick - longer
                        <div className="w-0.5 h-12 bg-muted-foreground/40" />
                      ) : (
                        // Minor tick - shorter
                        <div className="w-0.5 h-6 bg-muted-foreground/20" />
                      )}
                    </div>
                  </div>
                ))}
                <div style={{ width: '50%' }} /> {/* Right padding */}
              </div>
            </div>

            {/* Center indicator line */}
            <div className="absolute left-1/2 -translate-x-1/2 top-12 pointer-events-none">
              <div className="w-0.5 h-16 bg-primary" />
            </div>
          </div>
        </div>

        {/* BMI Display */}
        <div className="bg-card border-2 border-border rounded-2xl p-4 sm:p-6 shadow-md mt-32">
          <div className="flex flex-wrap items-center gap-2 sm:gap-3 mb-2">
            <span className="text-foreground font-semibold text-sm sm:text-base">
              Your BMI: {bmi}
            </span>
            <span className={`px-2 sm:px-3 py-1 bg-card border border-border rounded-full text-xs sm:text-sm font-medium ${category.color}`}>
              {category.label}
            </span>
          </div>
          <p className="text-xs sm:text-sm text-muted-foreground">
            We'll help you find the perfect plan to feel amazing in your own skin.
          </p>
        </div>
      </div>

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 p-6 bg-background border-t border-border">
        <div className="max-w-md mx-auto">
          <button
            onClick={handleContinue}
            className="w-full bg-primary text-primary-foreground rounded-2xl py-4 font-semibold shadow-md hover:shadow-lg transition-all"
          >
            Next
          </button>
        </div>
      </div>
    </div>
  );
}