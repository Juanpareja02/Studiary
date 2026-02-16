
'use client';

import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { getEventColor }from '@/lib/colors';
import { cn } from '@/lib/utils';
import type { Event, EventType } from '@/lib/types';
import { format, isFuture, isPast } from 'date-fns';
import { es } from 'date-fns/locale';
import { EventIcon } from './icons';

interface SummaryViewProps {
  events: Event[];
  onEventClick: (event: Event) => void;
}

const eventTypes: EventType[] = ['prácticas', 'estudio', 'examen', 'personal'];

const getTitleForType = (type: EventType) => {
  switch (type) {
    case 'prácticas':
      return 'Prácticas';
    case 'estudio':
      return 'Sesiones de Estudio';
    case 'examen':
      return 'Exámenes';
    case 'personal':
      return 'Eventos Personales';
  }
};

export default function SummaryView({ events, onEventClick }: SummaryViewProps) {
  // Sort events: upcoming first, then past events in reverse chronological order
  const sortedEvents = [...events].sort((a, b) => {
    const aIsPast = isPast(a.endDate || a.startDate);
    const bIsPast = isPast(b.endDate || b.startDate);

    if (aIsPast && !bIsPast) return 1; // b (future) comes first
    if (!aIsPast && bIsPast) return -1; // a (future) comes first
    
    // If both are future, sort by start date ascending
    if (!aIsPast && !bIsPast) {
      return a.startDate.getTime() - b.startDate.getTime();
    }
    
    // If both are past, sort by start date descending (most recent past first)
    return b.startDate.getTime() - a.startDate.getTime();
  });

  const groupedEvents = eventTypes.reduce((acc, type) => {
    acc[type] = sortedEvents.filter(event => event.type === type);
    return acc;
  }, {} as Record<EventType, Event[]>);

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {eventTypes.map(type => {
        const groupEvents = groupedEvents[type];
        if (groupEvents.length === 0) return null;

        return (
          <Card key={type} className="shadow-lg">
            <CardHeader>
              <CardTitle className="flex items-center gap-3 font-headline text-xl capitalize">
                <span className={cn("p-2 rounded-full", getEventColor(type))}>
                    <EventIcon type={type} className="h-5 w-5 text-white" />
                </span>
                {getTitleForType(type)}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <Accordion type="single" collapsible className="w-full">
                {groupEvents.map(event => (
                  <AccordionItem value={event.id} key={event.id}>
                    <AccordionTrigger
                      onClick={() => onEventClick(event)}
                      className="hover:no-underline"
                    >
                      <div className={cn("flex items-center gap-2", isPast(event.endDate || event.startDate) && "opacity-60")}>
                        {event.color && <div className="h-4 w-4 rounded-full border" style={{backgroundColor: event.color}} />}
                        <div className="flex flex-col text-left">
                          <span className="font-semibold">{event.title}</span>
                          <span className="text-sm text-muted-foreground">
                            {format(event.startDate, "EEEE, d 'de' MMMM", {
                              locale: es,
                            })}
                          </span>
                        </div>
                      </div>
                    </AccordionTrigger>
                    <AccordionContent>
                      <div className="space-y-2 pl-2 border-l-2 border-primary/50 ml-2">
                        {event.description && (
                            <p className="text-sm text-muted-foreground">{event.description}</p>
                        )}
                        <p className="text-sm">
                            <span className="font-semibold">Inicio:</span>{' '}
                            {format(event.startDate, 'p', { locale: es })}
                        </p>
                        {event.endDate && (
                             <p className="text-sm">
                                <span className="font-semibold">Fin:</span>{' '}
                                {format(event.endDate, 'p', { locale: es })}
                            </p>
                        )}
                         <button onClick={() => onEventClick(event)} className="text-primary hover:underline text-sm font-semibold">
                            Ver detalles
                        </button>
                      </div>
                    </AccordionContent>
                  </AccordionItem>
                ))}
              </Accordion>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
}
