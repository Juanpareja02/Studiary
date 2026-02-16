
'use client';

import { useState, useEffect, useCallback } from 'react';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { PlusCircle, SlidersHorizontal } from 'lucide-react';
import NewEventDialog from '@/components/new-event-dialog';
import EventDetailSheet from '@/components/event-detail-sheet';
import AnnualCalendar from '@/components/annual-calendar';
import MonthlyCalendar from '@/components/monthly-calendar';
import WeeklyCalendar from '@/components/weekly-calendar';
import SummaryView from '@/components/summary-view';
import GradesView from '@/components/grades-view';
import ScheduleView from '@/components/schedule-view';
import SubjectsView from '@/components/subjects-view';
import NotesView from '@/components/notes-view';
import StudyModeView from '@/components/study-mode-view';
import { addEvent as addEventUtil, updateEvent as updateEventUtil, deleteEvent as deleteEventUtil } from '@/lib/events';
import type { Event, Subject, ClassScheduleEntry, Note } from '@/lib/types';
import { Logo } from '@/components/logo';
import { ThemeCustomizer } from '@/components/theme-customizer';
import { useTheme } from '@/hooks/use-theme';
import { useNotifications } from '@/hooks/use-notifications';
import { ScrollArea } from '@/components/ui/scroll-area';

const EVENTS_STORAGE_KEY = 'moflets-app-events-v3';
const SUBJECTS_STORAGE_KEY = 'moflets-app-subjects-v3';
const SCHEDULE_STORAGE_KEY = 'moflets-app-schedule-v3';
const NOTES_STORAGE_KEY = 'moflets-app-notes-v1';


const getInitialState = <T,>(key: string): T | [] => {
  if (typeof window === 'undefined') {
    return [];
  }
  try {
    const saved = window.localStorage.getItem(key);
    if (saved) {
      const parsed = JSON.parse(saved);
      // Date hydration
      if (key === EVENTS_STORAGE_KEY) {
        return (parsed as any[]).map(event => ({
          ...event,
          startDate: new Date(event.startDate),
          endDate: event.endDate ? new Date(event.endDate) : undefined,
        })) as T;
      }
       if (key === NOTES_STORAGE_KEY) {
        return (parsed as any[]).map(note => ({
          ...note,
          createdAt: new Date(note.createdAt),
          updatedAt: new Date(note.updatedAt),
        })) as T;
      }
      return parsed;
    }
  } catch (error) {
    console.error(`Error loading ${key} from localStorage:`, error);
  }
  return [];
};


export default function PlannerPage() {
  const [events, setEvents] = useState<Event[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [schedule, setSchedule] = useState<ClassScheduleEntry[]>([]);
  const [notes, setNotes] = useState<Note[]>([]);
  
  const [isClient, setIsClient] = useState(false);
  const [isNewEventDialogOpen, setIsNewEventDialogOpen] = useState(false);
  const [isDetailSheetOpen, setIsDetailSheetOpen] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<Event | undefined>(undefined);
  const [editingEvent, setEditingEvent] = useState<Event | undefined>(undefined);
  const [initialDate, setInitialDate] = useState<Date | undefined>(undefined);
  const [initialTime, setInitialTime] = useState<string | undefined>(undefined);
  const [activeTab, setActiveTab] = useState("summary");
  
  useTheme(); // Initialize and apply the theme
  useNotifications(events); // Initialize and manage notifications

  useEffect(() => {
    setEvents(getInitialState<Event[]>(EVENTS_STORAGE_KEY));
    setSubjects(getInitialState<Subject[]>(SUBJECTS_STORAGE_KEY));
    setSchedule(getInitialState<ClassScheduleEntry[]>(SCHEDULE_STORAGE_KEY));
    setNotes(getInitialState<Note[]>(NOTES_STORAGE_KEY));
    setIsClient(true);
  }, []);

  const updateAndSave = useCallback(<T,>(setter: React.Dispatch<React.SetStateAction<T[]>>, key: string) => {
    return (data: T[]) => {
      setter(data);
      try {
        if (typeof window !== 'undefined') {
            let dataToSave = data;
            if (key === NOTES_STORAGE_KEY) {
                 dataToSave = (data as Note[]).map(note => {
                    const { fileDataUri, ...rest } = note;
                    return rest;
                }) as T[];
            }
          window.localStorage.setItem(key, JSON.stringify(dataToSave));
        }
      } catch (error) {
        console.error(`Error saving ${key} to localStorage:`, error);
      }
    };
  }, []);

  const setAndSaveEvents = useCallback(updateAndSave(setEvents, EVENTS_STORAGE_KEY), [updateAndSave]);
  const setAndSaveSubjects = useCallback(updateAndSave(setSubjects, SUBJECTS_STORAGE_KEY), [updateAndSave]);
  const setAndSaveSchedule = useCallback(updateAndSave(setSchedule, SCHEDULE_STORAGE_KEY), [updateAndSave]);
  const setAndSaveNotes = useCallback(updateAndSave(setNotes, NOTES_STORAGE_KEY), [updateAndSave]);


  const handleAddEvent = (eventData: Omit<Event, 'id'>): Event => {
    const { newEvent, updatedEvents } = addEventUtil(eventData, events);
    setAndSaveEvents(updatedEvents);
    return newEvent;
  };
  
  const handleUpdateEvent = (eventData: Event): Event => {
    const newEvents = updateEventUtil(eventData, events);
    setAndSaveEvents(newEvents);
    setSelectedEvent(eventData); // Also update the selected event if it's being viewed
    return eventData;
  }

  const handleDeleteEvent = (eventId: string) => {
    const newEvents = deleteEventUtil(eventId, events);
    setAndSaveEvents(newEvents);
    setIsDetailSheetOpen(false); // Close detail view on delete
    setSelectedEvent(undefined);
  }
  
  const handleDayClick = (date: Date) => {
    setInitialDate(date);
    setInitialTime(undefined);
    setEditingEvent(undefined);
    setIsNewEventDialogOpen(true);
  };
  
  const handleEventClick = (event: Event) => {
    setSelectedEvent(event);
    setIsDetailSheetOpen(true);
  }

  const handleEditRequest = (event: Event) => {
    setEditingEvent(event);
    setIsDetailSheetOpen(false); // Close detail sheet
    setIsNewEventDialogOpen(true); // Open edit dialog
  }

  const handleOpenNewEventDialog = () => {
    setInitialDate(undefined);
    setInitialTime(undefined);
    setEditingEvent(undefined);
    setIsNewEventDialogOpen(true);
  };
  
  useEffect(() => {
    // If the edit dialog is closed, clear the editing event
    if(!isNewEventDialogOpen) {
        setEditingEvent(undefined);
    }
  }, [isNewEventDialogOpen]);

  const tabs = [
    { value: 'summary', label: 'Resumen' },
    { value: 'annual', label: 'Anual' },
    { value: 'monthly', label: 'Mensual' },
    { value: 'weekly', label: 'Semanal' },
    { value: 'schedule', label: 'Mi Horario' },
    { value: 'subjects', label: 'Asignaturas' },
    { value: 'notes', label: 'Mis Apuntes' },
    { value: 'grades', label: 'Calificaciones' },
    { value: 'study-mode', label: 'Modo Estudio' },
  ]

  if (!isClient) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-background">
        <Logo className="h-16 w-16 text-primary animate-pulse" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background text-foreground">
      <div className="container mx-auto p-4 sm:p-6 lg:p-8">
        <header className="flex flex-col sm:flex-row items-center justify-between gap-4 mb-6">
          <div className="flex items-center gap-3">
             <Logo className="h-10 w-10 text-primary" />
             <h1 className="text-2xl sm:text-3xl font-headline font-bold text-foreground">
              Studiary
            </h1>
          </div>
          <div className="flex items-center gap-2">
            <ThemeCustomizer />
            <Button onClick={handleOpenNewEventDialog} className="bg-primary text-primary-foreground hover:bg-primary/90 w-full sm:w-auto shadow-sm">
              <PlusCircle className="mr-2 h-4 w-4" />
              Nuevo Evento
            </Button>
          </div>
        </header>

        <NewEventDialog
          isOpen={isNewEventDialogOpen}
          setIsOpen={setIsNewEventDialogOpen}
          onAddEvent={handleAddEvent}
          onUpdateEvent={handleUpdateEvent}
          eventToEdit={editingEvent}
          initialDate={initialDate}
          initialTime={initialTime}
          subjects={subjects}
        />
        
        <EventDetailSheet
          event={selectedEvent}
          isOpen={isDetailSheetOpen}
          setIsOpen={setIsDetailSheetOpen}
          onEdit={handleEditRequest}
          onDelete={handleDeleteEvent}
          onUpdate={handleUpdateEvent}
          subjects={subjects}
        />

        <main>
          <Tabs defaultValue="summary" className="w-full" value={activeTab} onValueChange={setActiveTab}>
             <div className="sm:hidden mb-4">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" className="w-full">
                    <SlidersHorizontal className="mr-2 h-4 w-4" />
                    Vista: {tabs.find(t => t.value === activeTab)?.label}
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="start" className="w-full">
                  {tabs.map(tab => (
                    <DropdownMenuItem key={tab.value} onClick={() => setActiveTab(tab.value)}>
                      {tab.label}
                    </DropdownMenuItem>
                  ))}
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
            <ScrollArea className="hidden sm:block whitespace-nowrap rounded-lg mb-4">
              <TabsList className="inline-flex w-max p-1 space-x-1 bg-muted rounded-xl">
                {tabs.map(tab => (
                   <TabsTrigger key={tab.value} value={tab.value}
                     className="px-3 py-1.5 text-sm font-medium transition-all rounded-lg data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
                   >{tab.label}</TabsTrigger>
                ))}
              </TabsList>
            </ScrollArea>
            <TabsContent value="summary">
              <SummaryView events={events} onEventClick={handleEventClick} />
            </TabsContent>
            <TabsContent value="annual">
              <AnnualCalendar events={events} onDayClick={handleDayClick} />
            </TabsContent>
            <TabsContent value="monthly">
              <MonthlyCalendar events={events} onDayClick={handleDayClick} onEventClick={handleEventClick} />
            </TabsContent>
            <TabsContent value="weekly">
              <WeeklyCalendar events={events} onDayClick={handleDayClick} onEventClick={handleEventClick} />
            </TabsContent>
             <TabsContent value="schedule">
              <ScheduleView schedule={schedule} setSchedule={setAndSaveSchedule} subjects={subjects} />
            </TabsContent>
            <TabsContent value="subjects">
              <SubjectsView subjects={subjects} setSubjects={setAndSaveSubjects} />
            </TabsContent>
            <TabsContent value="notes">
              <NotesView subjects={subjects} notes={notes} setNotes={setAndSaveNotes} />
            </TabsContent>
            <TabsContent value="grades">
              <GradesView events={events} onEventClick={handleEventClick} subjects={subjects} />
            </TabsContent>
             <TabsContent value="study-mode">
              <StudyModeView />
            </TabsContent>
          </Tabs>
        </main>
      </div>
    </div>
  );
}
