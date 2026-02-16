
'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Timer, Play, Pause, RotateCcw } from 'lucide-react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { cn } from '@/lib/utils';

type StudyTechnique = 'pomodoro' | 'custom';
type PomodoroPhase = 'study' | 'shortBreak' | 'longBreak';

const formatTime = (seconds: number) => {
  const minutes = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
};

const CircularProgress = ({ progress, total }: { progress: number, total: number }) => {
    const strokeWidth = 10;
    const radius = 80;
    const circumference = 2 * Math.PI * radius;
    const strokeDashoffset = circumference - (progress / total) * circumference;

    const progressPercentage = (progress / total) * 100;
    const color = progressPercentage < 25 ? 'hsl(var(--destructive))' : progressPercentage < 50 ? 'hsl(var(--primary) / 0.6)' : 'hsl(var(--primary))';

    return (
        <div className="relative w-48 h-48">
            <svg className="w-full h-full" viewBox="0 0 200 200">
                <circle
                    className="text-muted"
                    strokeWidth={strokeWidth}
                    stroke="currentColor"
                    fill="transparent"
                    r={radius}
                    cx="100"
                    cy="100"
                />
                <circle
                    stroke={color}
                    className="transition-all duration-300 ease-linear"
                    strokeWidth={strokeWidth}
                    strokeLinecap="round"
                    strokeDasharray={circumference}
                    strokeDashoffset={strokeDashoffset}
                    fill="transparent"
                    r={radius}
                    cx="100"
                    cy="100"
                    transform="rotate(-90 100 100)"
                />
            </svg>
            <div className="absolute inset-0 flex items-center justify-center">
                 <span className="text-4xl font-bold font-mono tracking-tighter" style={{color}}>{formatTime(progress)}</span>
            </div>
        </div>
    );
};


export default function StudyModeView() {
  const [technique, setTechnique] = useState<StudyTechnique>('pomodoro');
  const [pomodoroPhase, setPomodoroPhase] = useState<PomodoroPhase>('study');
  const [pomodoroCount, setPomodoroCount] = useState(0);

  const [customStudyTime, setCustomStudyTime] = useState(25);
  const [customBreakTime, setCustomBreakTime] = useState(5);

  const getPhaseTime = useCallback(() => {
    if (technique === 'pomodoro') {
      switch (pomodoroPhase) {
        case 'study': return 25 * 60;
        case 'shortBreak': return 5 * 60;
        case 'longBreak': return 15 * 60;
      }
    }
    return (pomodoroPhase === 'study' ? customStudyTime : customBreakTime) * 60;
  }, [technique, pomodoroPhase, customStudyTime, customBreakTime]);

  const [totalTime, setTotalTime] = useState(getPhaseTime());
  const [timeRemaining, setTimeRemaining] = useState(totalTime);
  const [isActive, setIsActive] = useState(false);
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    if (typeof window !== 'undefined') {
        audioRef.current = new Audio('/notification.mp3'); // Assumes a notification sound file in public folder
    }
  }, []);

  useEffect(() => {
    const newTotalTime = getPhaseTime();
    setTotalTime(newTotalTime);
    if (!isActive) {
        setTimeRemaining(newTotalTime);
    }
  }, [technique, pomodoroPhase, customStudyTime, customBreakTime, isActive, getPhaseTime]);

  const nextPhase = useCallback(() => {
    audioRef.current?.play();
    setIsActive(false);

    if (technique === 'pomodoro') {
        if (pomodoroPhase === 'study') {
            const newCount = pomodoroCount + 1;
            setPomodoroCount(newCount);
            if (newCount % 4 === 0) {
                setPomodoroPhase('longBreak');
            } else {
                setPomodoroPhase('shortBreak');
            }
        } else {
            setPomodoroPhase('study');
        }
    } else { // Custom
        setPomodoroPhase(pomodoroPhase === 'study' ? 'shortBreak' : 'study');
    }
  }, [pomodoroCount, pomodoroPhase, technique]);


  useEffect(() => {
    if (isActive && timeRemaining > 0) {
      timerRef.current = setInterval(() => {
        setTimeRemaining(time => time - 1);
      }, 1000);
    } else if (isActive && timeRemaining === 0) {
      nextPhase();
    }
    
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [isActive, timeRemaining, nextPhase]);

  const handleToggle = () => {
    setIsActive(!isActive);
  };

  const handleReset = () => {
    if (timerRef.current) clearInterval(timerRef.current);
    setIsActive(false);
    setTimeRemaining(getPhaseTime());
  };

  const getPhaseLabel = () => {
      if (pomodoroPhase === 'study') return 'Estudio';
      if (pomodoroPhase === 'shortBreak') return 'Descanso Corto';
      if (pomodoroPhase === 'longBreak') return 'Descanso Largo';
      return 'Descanso';
  }

  return (
    <Card className="shadow-lg">
        <CardHeader>
            <CardTitle className="flex items-center gap-3 font-headline text-xl capitalize">
                <Timer className="h-6 w-6 text-primary" />
                Modo Estudio
            </CardTitle>
            <CardDescription>
                Utiliza técnicas de estudio como el Pomodoro para mantener la concentración.
            </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col items-center gap-8 py-10">
            <div className="flex flex-col items-center gap-2">
                 <p className="text-lg font-semibold text-primary">{getPhaseLabel()}</p>
                 {technique === 'pomodoro' && <p className="text-sm text-muted-foreground">Pomodoros completados: {pomodoroCount}</p>}
            </div>

            <CircularProgress progress={timeRemaining} total={totalTime} />
            
            <div className="flex items-center gap-4">
                <Button onClick={handleReset} variant="outline" size="icon" className="w-16 h-16 rounded-full shadow-md">
                    <RotateCcw className="h-8 w-8" />
                </Button>
                <Button onClick={handleToggle} size="icon" className="w-20 h-20 rounded-full shadow-lg">
                    {isActive ? <Pause className="h-10 w-10" /> : <Play className="h-10 w-10" />}
                </Button>
            </div>
            
            <Card className="w-full max-w-sm p-4">
                 <div className="space-y-4">
                    <div>
                        <Label htmlFor="technique-select">Técnica de Estudio</Label>
                        <Select value={technique} onValueChange={(v) => setTechnique(v as StudyTechnique)}>
                            <SelectTrigger id="technique-select">
                                <SelectValue placeholder="Selecciona una técnica" />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem value="pomodoro">Pomodoro (25/5)</SelectItem>
                                <SelectItem value="custom">Personalizado</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>

                    {technique === 'custom' && (
                        <div className="grid grid-cols-2 gap-4">
                             <div>
                                <Label htmlFor="custom-study">Tiempo de Estudio (min)</Label>
                                <Input
                                    id="custom-study"
                                    type="number"
                                    value={customStudyTime}
                                    onChange={(e) => setCustomStudyTime(parseInt(e.target.value, 10))}
                                    disabled={isActive}
                                />
                            </div>
                            <div>
                                <Label htmlFor="custom-break">Tiempo de Descanso (min)</Label>
                                <Input
                                    id="custom-break"
                                    type="number"
                                    value={customBreakTime}
                                    onChange={(e) => setCustomBreakTime(parseInt(e.target.value, 10))}
                                    disabled={isActive}
                                />
                            </div>
                        </div>
                    )}
                 </div>
            </Card>

        </CardContent>
    </Card>
  );
}
