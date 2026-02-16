
'use client';

import { useState } from 'react';
import {
  format,
  addWeeks,
  subWeeks,
  isToday,
  isSameMonth,
  startOfWeek,
  endOfWeek,
} from 'date-fns';
import { es } from 'date-fns/locale';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { ScrollArea } from '@/components/ui/scroll-area';
import { cn } from '@/lib/utils';
import type { Event } from '@/lib/types';
import { getEventsForWeek } from '@/lib/events';
import { EventIcon } from './icons';
import { getEventColor } from '@/lib/colors';

interface WeeklyCalendarProps {
  events: Event[];
  onDayClick: (date: Date) => void;
  onEventClick: (event: Event) => void;
}

export default function WeeklyCalendar({ events, onDayClick, onEventClick }: WeeklyCalendarProps) {
  const [currentDate, setCurrentDate] = useState(new Date());

  const weekStart = startOfWeek(currentDate, { locale: es });
  const weekEnd = endOfWeek(currentDate, { locale: es });
  const week = getEventsForWeek(currentDate, events);

  const prevWeek = () => setCurrentDate(subWeeks(currentDate, 1));
  const nextWeek = () => setCurrentDate(addWeeks(currentDate, 1));
  const goToToday = () => setCurrentDate(new Date());

  const monthDisplay =
    format(weekStart, 'MMMM', { locale: es }) === format(weekEnd, 'MMMM', { locale: es })
      ? format(weekStart, 'MMMM yyyy', { locale: es })
      : `${format(weekStart, 'MMM', { locale: es })} - ${format(weekEnd, 'MMM yyyy', { locale: es })}`;

  return (
    <Card className="shadow-lg">
      <CardHeader className="flex flex-col sm:flex-row items-center justify-between gap-4">
        <CardTitle className="font-headline text-xl sm:text-2xl capitalize text-center sm:text-left">{monthDisplay}</CardTitle>
        <div className="flex items-center gap-2">
          <Button variant="outline" onClick={prevWeek}>
            <ChevronLeft className="h-4 w-4 md:mr-2" />
            <span className="hidden md:inline">Ant</span>
          </Button>
          <Button variant="outline" onClick={goToToday}>
            Hoy
          </Button>
          <Button variant="outline" onClick={nextWeek}>
            <span className="hidden md:inline">Sig</span>
            <ChevronRight className="h-4 w-4 md:ml-2" />
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-2">
          {week.map(({ day, events: dayEvents }) => (
            <Card
              key={day.toString()}
              onClick={() => onDayClick(day)}
              className={cn(
                'flex flex-col cursor-pointer hover:bg-accent/40',
                isToday(day) && 'border-primary ring-2 ring-primary'
              )}
            >
              <CardHeader className="p-3">
                <div
                  className={cn(
                    'flex items-center justify-between text-sm capitalize',
                    !isSameMonth(day, currentDate) && 'text-muted-foreground'
                  )}
                >
                  <span>{format(day, 'eee', { locale: es })}</span>
                  <span
                    className={cn(
                      'font-bold',
                      isToday(day) && 'text-primary'
                    )}
                  >
                    {format(day, 'd')}
                  </span>
                </div>
              </CardHeader>
              <CardContent className="flex-grow p-3 pt-0">
                <ScrollArea className="h-[120px]">
                  <div className="space-y-2 pr-3">
                    {dayEvents.length > 0 ? (
                      dayEvents.map((event) => (
                        <button
                          key={event.id}
                          onClick={(e) => { e.stopPropagation(); onEventClick(event); }}
                          style={{backgroundColor: event.color ? event.color : undefined}}
                          className={cn(
                            "w-full text-left text-xs p-2 rounded-md text-primary-foreground/90",
                            !event.color && getEventColor(event.type)
                          )}
                        >
                          <div className="flex items-start space-x-2">
                            <div className="pt-0.5">
                             <EventIcon type={event.type} className="h-3 w-3" />
                            </div>
                            <span className="font-medium truncate">{event.title}</span>
                          </div>
                        </button>
                      ))
                    ) : (
                      <div className="text-xs text-muted-foreground text-center pt-4 h-[120px] flex items-center justify-center">
                        Sin eventos
                      </div>
                    )}
                  </div>
                </ScrollArea>
              </CardContent>
            </Card>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
