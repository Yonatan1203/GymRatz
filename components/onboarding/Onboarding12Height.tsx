import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router';
import OnboardingProgress from './OnboardingProgress';

export default function Onboarding12Height() {
  const navigate = useNavigate();
  const [height, setHeight] = useState(170);
  const scrollRef = useRef<HTMLDivElement>(null);
  const itemHeight = 60;

  // Generate height values (140-220 cm)
  const heights = Array.from({ length: 81 }, (_, i) => 140 + i);

  useEffect(() => {
    // Center the initial value
    if (scrollRef.current) {
      const index = heights.indexOf(height);
      scrollRef.current.scrollTop = index * itemHeight;
    }
  }, []);

  useEffect(() => {
    let timeoutId: NodeJS.Timeout;

    const handleScroll = () => {
      if (!scrollRef.current) return;
      
      // Clear existing timeout
      clearTimeout(timeoutId);
      
      // Update value during scroll
      const scrollTop = scrollRef.current.scrollTop;
      const index = Math.round(scrollTop / itemHeight);
      const newHeight = heights[Math.max(0, Math.min(index, heights.length - 1))];
      
      if (newHeight && newHeight !== height) {
        setHeight(newHeight);
      }

      // Snap to position after scrolling stops
      timeoutId = setTimeout(() => {
        if (scrollRef.current) {
          const finalIndex = Math.round(scrollRef.current.scrollTop / itemHeight);
          scrollRef.current.scrollTo({
            top: finalIndex * itemHeight,
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
  }, [height, heights, itemHeight]);

  const handleContinue = () => {
    navigate('/onboarding/weight');
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <OnboardingProgress currentStep={6} totalSteps={14} />

      <div className="flex-1 flex flex-col justify-center px-6 max-w-md mx-auto w-full py-8">
        <h1 className="text-foreground text-2xl sm:text-3xl font-bold mb-2 sm:mb-3 text-center">
          How tall are you?
        </h1>
        <p className="text-muted-foreground mb-12 text-sm sm:text-base text-center">
          This helps us calculate your personal metrics and celebrate your unique body.
        </p>

        {/* Picker Container */}
        <div className="relative h-96 mb-8">
          {/* Scrollable Picker */}
          <div
            ref={scrollRef}
            className="h-full overflow-y-auto scrollbar-hide relative"
            style={{ 
              WebkitOverflowScrolling: 'touch',
              overscrollBehavior: 'contain'
            }}
          >
            <div style={{ height: '50%' }} /> {/* Top padding */}
            {heights.map((h) => (
              <div
                key={h}
                className="flex items-center justify-between px-8"
                style={{ height: `${itemHeight}px` }}
              >
                {/* Left side - Value */}
                <div className="flex items-center gap-2">
                  {h === height ? (
                    <span className="text-5xl font-bold text-foreground">
                      {h} <span className="text-2xl text-muted-foreground">cm</span>
                    </span>
                  ) : (
                    <span className="text-xl text-muted-foreground/50">
                      {h}
                    </span>
                  )}
                </div>

                {/* Right side - Tick marks */}
                <div className="flex flex-col items-end gap-0.5">
                  {h % 5 === 0 ? (
                    // Major tick - longer
                    <div className="w-20 h-1 bg-muted-foreground/40 rounded-full" />
                  ) : (
                    // Minor tick - shorter
                    <div className="w-12 h-0.5 bg-muted-foreground/20 rounded-full" />
                  )}
                </div>
              </div>
            ))}
            <div style={{ height: '50%' }} /> {/* Bottom padding */}
          </div>
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