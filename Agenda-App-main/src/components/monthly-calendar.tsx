
'use client';

import { useState, useEffect } from 'react';
import {
  format,
  eachDayOfInterval,
  startOfMonth,
  endOfMonth,
  startOfWeek,
  endOfWeek,
  isSameMonth,
  isToday,
  addMonths,
  subMonths,
  isSameDay,
} from 'date-fns';
import { es } from 'date-fns/locale';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from '@/components/ui/sheet';
import { useIsMobile } from '@/hooks/use-mobile';
import { cn } from '@/lib/utils';
import type { Event } from '@/lib/types';
import { getEventsForDate } from '@/lib/events';
import { EventIcon } from './icons';
import { getEventColor } from '@/lib/colors';

interface MonthlyCalendarProps {
  events: Event[];
  onDayClick: (date: Date) => void;
  onEventClick: (event: Event) => void;
}

const DayCell = ({
  day,
  isCurrentMonth,
  isSelected,
  dayEvents,
  onDayClick,
  onEventClick,
}: {
  day: Date;
  isCurrentMonth: boolean;
  isSelected: boolean;
  dayEvents: Event[];
  onDayClick: (date: Date) => void;
  onEventClick: (event: Event) => void;
}) => (
  <div
    onClick={() => onDayClick(day)}
    className={cn(
      'relative flex flex-col h-24 sm:h-32 p-2 border-t border-l border-border/50 cursor-pointer transition-colors',
      !isCurrentMonth && 'bg-muted/30 text-muted-foreground/80',
      isSelected && 'bg-accent/50',
      'hover:bg-accent/40'
    )}
  >
    <time
      dateTime={format(day, 'yyyy-MM-dd')}
      className={cn(
        'self-end text-sm font-medium h-6 w-6 flex items-center justify-center rounded-full',
        isToday(day) && 'bg-primary text-primary-foreground'
      )}
    >
      {format(day, 'd')}
    </time>
    <ScrollArea className="flex-1 -mx-2">
      <div className="px-2 space-y-1">
        {dayEvents.slice(0, 3).map((event) => (
          <button
            key={event.id}
            onClick={(e) => { e.stopPropagation(); onEventClick(event); }}
            style={{backgroundColor: event.color ? event.color : undefined}}
            className={cn(
                "w-full text-left text-xs p-1 rounded-md text-primary-foreground/90 truncate flex items-center gap-1",
                !event.color && getEventColor(event.type)
            )}
          >
            <EventIcon type={event.type} className="w-3 h-3 shrink-0" />
            <span className="truncate">{event.title}</span>
          </button>
        ))}
         {dayEvents.length > 3 && (
            <p className="text-xs text-muted-foreground text-center">...</p>
        )}
      </div>
    </ScrollArea>
  </div>
);

const DayDetailPanel = ({
  date,
  events,
  onEventClick,
  onDayClick,
  isSheet = false,
}: {
  date: Date;
  events: Event[];
  onEventClick: (event: Event) => void;
  onDayClick: (date: Date) => void;
  isSheet?: boolean;
}) => (
  <>
    {isSheet ? (
      <SheetHeader>
        <SheetTitle className="font-headline capitalize text-xl">
          {format(date, "EEEE, d 'de' MMMM", { locale: es })}
        </SheetTitle>
      </SheetHeader>
    ) : (
      <CardHeader>
        <CardTitle className="font-headline capitalize text-xl">
          {format(date, "EEEE, d 'de' MMMM", { locale: es })}
        </CardTitle>
      </CardHeader>
    )}
    <CardContent className="pt-4 flex flex-col h-full">
      <ScrollArea className="flex-1 -mx-6">
        <div className="px-6">
            {events.length > 0 ? (
            <ul className="space-y-4">
                {events.map((event) => (
                <li key={event.id} style={{backgroundColor: event.color ? event.color : undefined}} className={cn("flex items-start space-x-3 p-3 rounded-md cursor-pointer", !event.color && getEventColor(event.type))} onClick={() => onEventClick(event)}>
                    <div className="flex-shrink-0 pt-1">
                    <EventIcon type={event.type} className="text-white" />
                    </div>
                    <div>
                    <p className="font-semibold text-white">{event.title}</p>
                    {event.startDate && (
                        <p className="text-xs text-white/80 mt-1">
                        {format(event.startDate, 'p', { locale: es })}
                        {event.endDate && ` - ${format(event.endDate, 'p', { locale: es })}`}
                        </p>
                    )}
                    </div>
                </li>
                ))}
            </ul>
            ) : (
            <div className="flex items-center justify-center h-full">
                <p className="text-muted-foreground text-center">No hay eventos para este día.</p>
            </div>
            )}
        </div>
      </ScrollArea>
       <Button onClick={() => onDayClick(date)} variant="outline" className="mt-4">
         Añadir evento a este día
      </Button>
    </CardContent>
  </>
)

export default function MonthlyCalendar({ events, onDayClick, onEventClick }: MonthlyCalendarProps) {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedDate, setSelectedDate] = useState(new Date());
  const isMobile = useIsMobile();
  const [isSheetOpen, setIsSheetOpen] = useState(false);

  const monthStart = startOfMonth(currentDate);
  const monthEnd = endOfMonth(currentDate);
  const startDate = startOfWeek(monthStart, { locale: es });
  const endDate = endOfWeek(monthEnd, { locale: es });

  const days = eachDayOfInterval({ start: startDate, end: endDate });
  const weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
  
  const selectedDayEvents = getEventsForDate(selectedDate, events);

  const handleDayCellClick = (day: Date) => {
    setSelectedDate(day);
  };
  
  const handleSelectDayForDetail = (day: Date) => {
    setSelectedDate(day);
    if(isMobile){
      setIsSheetOpen(true);
    }
  };
  
  const nextMonth = () => setCurrentDate(addMonths(currentDate, 1));
  const prevMonth = () => setCurrentDate(subMonths(currentDate, 1));
  const goToToday = () => {
    const today = new Date();
    setCurrentDate(today);
    setSelectedDate(today);
    if(isMobile){
      handleSelectDayForDetail(today);
    }
  }

  const renderGrid = () => (
    <Card className="lg:col-span-3 shadow-lg">
      <CardHeader className="flex flex-col sm:flex-row items-center justify-between gap-4">
        <CardTitle className="font-headline text-2xl capitalize">
          {format(currentDate, "MMMM 'de' yyyy", { locale: es })}
        </CardTitle>
        <div className="flex items-center gap-2">
           <Button variant="outline" size="icon" onClick={prevMonth}>
            <ChevronLeft className="h-4 w-4" />
           </Button>
          <Button variant="outline" onClick={goToToday} className={cn(isToday(currentDate) && "bg-primary/30")}>
            Hoy
          </Button>
          <Button variant="outline" size="icon" onClick={nextMonth}>
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-7 border-r border-border/50">
          {weekdays.map((day) => (
            <div key={day} className="text-center font-semibold text-muted-foreground text-sm py-2 border-t border-l border-border/50 capitalize">
              <span className="hidden md:inline">{day}</span>
              <span className="md:hidden">{day.substring(0,3)}</span>
            </div>
          ))}
          {days.map((day) => (
            <DayCell
              key={day.toString()}
              day={day}
              isCurrentMonth={isSameMonth(day, currentDate)}
              isSelected={isSameDay(day, selectedDate)}
              dayEvents={getEventsForDate(day, events)}
              onDayClick={isMobile ? handleSelectDayForDetail : handleDayCellClick}
              onEventClick={onEventClick}
            />
          ))}
        </div>
      </CardContent>
    </Card>
  );

  if (isMobile) {
    return (
      <Sheet open={isSheetOpen} onOpenChange={setIsSheetOpen}>
        <SheetTrigger asChild>
          {renderGrid()}
        </SheetTrigger>
        <SheetContent side="bottom" className="h-[80%] flex flex-col">
          <DayDetailPanel date={selectedDate} events={selectedDayEvents} onEventClick={onEventClick} onDayClick={onDayClick} isSheet={true} />
        </SheetContent>
      </Sheet>
    );
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
      {renderGrid()}
      <Card className="shadow-lg lg:col-span-1 hidden lg:flex flex-col">
        <DayDetailPanel date={selectedDate} events={selectedDayEvents} onEventClick={onEventClick} onDayClick={onDayClick} />
      </Card>
    </div>
  );
}
