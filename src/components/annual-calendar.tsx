
'use client';

import { useState } from 'react';
import {
  format,
  eachDayOfInterval,
  startOfMonth,
  endOfMonth,
  startOfWeek,
  endOfWeek,
  isSameMonth,
  isToday,
  addYears,
  subYears,
  getYear,
} from 'date-fns';
import { es } from 'date-fns/locale';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import type { Event } from '@/lib/types';
import { getEventsForDate } from '@/lib/events';

interface AnnualCalendarProps {
  events: Event[];
  onDayClick: (date: Date) => void;
}

const MiniCalendar = ({
  month,
  year,
  events,
  onDayClick,
}: {
  month: number;
  year: number;
  events: Event[];
  onDayClick: (date: Date) => void;
}) => {
  const monthDate = new Date(year, month);
  
  const monthStart = startOfMonth(monthDate);
  const monthEnd = endOfMonth(monthDate);
  const startDate = startOfWeek(monthStart, { locale: es });
  const endDate = endOfWeek(monthEnd, { locale: es });

  const days = eachDayOfInterval({ start: startDate, end: endDate });
  const weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  return (
    <Card className="flex-1 min-w-[280px] shadow-md hover:shadow-lg transition-shadow">
      <CardHeader className="p-4">
        <CardTitle className="text-center text-lg font-headline text-primary-foreground/90 capitalize">
          {format(monthDate, 'MMMM', { locale: es })}
        </CardTitle>
      </CardHeader>
      <CardContent className="p-2">
        <div className="grid grid-cols-7 gap-1 text-center text-xs text-muted-foreground">
          {weekdays.map((day, index) => (
            <div key={`${day}-${index}`}>{day}</div>
          ))}
        </div>
        <div className="grid grid-cols-7 gap-1 mt-1">
          {days.map((day) => {
            const dayEvents = getEventsForDate(day, events);
            const hasEvent = dayEvents.length > 0;
            return (
              <button
                key={day.toString()}
                onClick={() => onDayClick(day)}
                className={cn(
                  'w-8 h-8 flex items-center justify-center rounded-full text-sm',
                  'hover:bg-accent/80 hover:text-accent-foreground',
                  !isSameMonth(day, monthDate) && 'text-muted-foreground/50',
                  isToday(day) && 'bg-primary text-primary-foreground',
                  hasEvent && !isToday(day) && 'bg-accent text-accent-foreground',
                  hasEvent && isToday(day) && 'bg-primary text-primary-foreground ring-2 ring-accent',
                )}
              >
                {format(day, 'd')}
              </button>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
};

export default function AnnualCalendar({ events, onDayClick }: AnnualCalendarProps) {
  const [currentYear, setCurrentYear] = useState(getYear(new Date()));

  const months = Array.from({ length: 12 }, (_, i) => i);

  return (
    <Card className="w-full">
      <CardHeader className="flex flex-col sm:flex-row items-center justify-between gap-2">
        <Button
          variant="outline"
          size="icon"
          onClick={() => setCurrentYear(currentYear - 1)}
        >
          <ChevronLeft className="h-4 w-4" />
          <span className="sr-only">Año Anterior</span>
        </Button>
        <CardTitle className="text-2xl font-headline">
          {currentYear}
        </CardTitle>
        <Button
          variant="outline"
          size="icon"
          onClick={() => setCurrentYear(currentYear + 1)}
        >
          <ChevronRight className="h-4 w-4" />
          <span className="sr-only">Año Siguiente</span>
        </Button>
      </CardHeader>
      <CardContent className="p-2 sm:p-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {months.map((month) => (
            <MiniCalendar
              key={month}
              month={month}
              year={currentYear}
              events={events}
              onDayClick={onDayClick}
            />
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
