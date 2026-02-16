
import {
  startOfWeek,
  endOfWeek,
  eachDayOfInterval,
  startOfDay,
  endOfDay,
  addDays,
  subDays,
  isSameDay,
  startOfMonth,
  endOfMonth,
  areIntervalsOverlapping
} from 'date-fns';
import { es } from 'date-fns/locale';
import type { Event, Subject, ClassScheduleEntry } from './types';

const today = new Date();
const todayStart = startOfDay(today);

export const MOCK_SUBJECTS: Subject[] = [];

export const MOCK_EVENTS: Event[] = [];


export const MOCK_SCHEDULE: ClassScheduleEntry[] = [];


export const getEventsForDate = (date: Date, events: Event[]): Event[] => {
  return events
    .filter((event) => {
      const eventStart = event.startDate;
      const eventEnd = event.endDate || event.startDate;
      const dayStart = startOfDay(date);
      const dayEnd = endOfDay(date);
      
      return areIntervalsOverlapping(
        { start: eventStart, end: eventEnd },
        { start: dayStart, end: dayEnd }
      );
    })
    .sort((a, b) => a.startDate.getTime() - b.startDate.getTime());
};

export const getEventsForWeek = (
  date: Date,
  events: Event[]
): { day: Date; events: Event[] }[] => {
  const weekStart = startOfWeek(date, { locale: es });
  const weekEnd = endOfWeek(date, { locale: es });
  const weekDays = eachDayOfInterval({ start: weekStart, end: weekEnd });

  return weekDays.map((day) => ({
    day,
    events: getEventsForDate(day, events),
  }));
};

export const getEventsForMonth = (date: Date, events: Event[]) => {
  const monthStart = startOfMonth(date);
  const monthEnd = endOfMonth(date);

  return events.filter(event => 
    areIntervalsOverlapping(
      { start: event.startDate, end: event.endDate || event.startDate },
      { start: monthStart, end: monthEnd }
    )
  );
};


export const addEvent = (eventData: Omit<Event, 'id'>, currentEvents: Event[]): { newEvent: Event, updatedEvents: Event[] } => {
  const newEvent: Event = {
    id: new Date().toISOString(),
    ...eventData,
  };
  const updatedEvents = [...currentEvents, newEvent];
  return { newEvent, updatedEvents };
};

export const updateEvent = (updatedEvent: Event, currentEvents: Event[]): Event[] => {
  return currentEvents.map(event => 
    event.id === updatedEvent.id ? updatedEvent : event
  );
};

export const deleteEvent = (eventId: string, currentEvents: Event[]): Event[] => {
  return currentEvents.filter(event => event.id !== eventId);
};
