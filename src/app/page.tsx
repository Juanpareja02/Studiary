
'use client';

import { useState, useEffect, useCallback } from 'react';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
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
import type { Event, Subject, ClassScheduleEntry, Note, ScheduleProfile } from '@/lib/types';
import { Logo } from '@/components/logo';
import { ThemeCustomizer } from '@/components/theme-customizer';
import { useTheme } from '@/hooks/use-theme';
import { useNotifications } from '@/hooks/use-notifications';
import { ScrollArea } from '@/components/ui/scroll-area';
import { useAuth } from '@/lib/auth-context';
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { LogOut } from 'lucide-react';
import { syncToFirestore, loadFromFirestore } from '@/lib/sync';
import { useRouter } from 'next/navigation';
import { initializeAdMob, showBanner } from '@/lib/admob';

const getEventsKey = (uid: string) => `studiary-events-${uid}-v3`;
const getSubjectsKey = (uid: string) => `studiary-subjects-${uid}-v3`;
const getScheduleKey = (uid: string) => `studiary-schedule-${uid}-v3`;
const getProfilesKey = (uid: string) => `studiary-profiles-${uid}-v1`;
const getNotesKey = (uid: string) => `studiary-notes-${uid}-v1`;
const DEFAULT_PROFILE_ID = 'default';


const getInitialState = <T,>(key: string): T | [] => {
  if (typeof window === 'undefined') {
    return [];
  }
  try {
    const saved = window.localStorage.getItem(key);
    if (saved) {
      const parsed = JSON.parse(saved);
      // Date hydration
      if (key.includes('events')) {
        return (parsed as any[]).map(event => ({
          ...event,
          startDate: new Date(event.startDate),
          endDate: event.endDate ? new Date(event.endDate) : undefined,
        })) as T;
      }
      if (key.includes('notes')) {
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
  const [profiles, setProfiles] = useState<ScheduleProfile[]>([]);
  const [notes, setNotes] = useState<Note[]>([]);

  const [isClient, setIsClient] = useState(false);
  const [isNewEventDialogOpen, setIsNewEventDialogOpen] = useState(false);
  const [isDetailSheetOpen, setIsDetailSheetOpen] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<Event | undefined>(undefined);
  const [editingEvent, setEditingEvent] = useState<Event | undefined>(undefined);
  const [initialDate, setInitialDate] = useState<Date | undefined>(undefined);
  const [initialTime, setInitialTime] = useState<string | undefined>(undefined);
  const [activeTab, setActiveTab] = useState("summary");

  const { user, loading: authLoading, signInWithGoogle, signOut } = useAuth();
  const router = useRouter();

  useTheme(); // Initialize and apply the theme
  useNotifications(events); // Initialize and manage notifications

  useEffect(() => {
    if (!authLoading && !user) {
      router.push('/login');
    }
  }, [user, authLoading, router]);

  useEffect(() => {
    setIsClient(true);
    // Inicializar AdMob
    const setupAds = async () => {
      await initializeAdMob();
      await showBanner();
    };
    setupAds();
  }, []);

  // Sync from Cloud and local storage when user logs in
  useEffect(() => {
    if (user && !authLoading) {
      const uid = user.uid;

      // Load from namespaced localStorage first for immediate UI
      const localEvents = getInitialState<Event[]>(getEventsKey(uid));
      const localSubjects = getInitialState<Subject[]>(getSubjectsKey(uid));
      const localProfiles = getInitialState<ScheduleProfile[]>(getProfilesKey(uid)) || [{ id: DEFAULT_PROFILE_ID, name: 'Horario Principal' }];
      const localSchedule = (getInitialState<ClassScheduleEntry[]>(getScheduleKey(uid)) || []).map(entry => ({
        ...entry,
        profileId: entry.profileId || DEFAULT_PROFILE_ID
      }));
      const localNotes = getInitialState<Note[]>(getNotesKey(uid));

      setEvents(localEvents);
      setSubjects(localSubjects);
      setProfiles(localProfiles);
      setSchedule(localSchedule);
      setNotes(localNotes);

      const syncData = async () => {
        const cloudData = await loadFromFirestore(user);
        if (cloudData) {
          if (cloudData[getEventsKey(uid)]) {
            const parsedEvents = (cloudData[getEventsKey(uid)] as any[]).map(event => ({
              ...event,
              startDate: new Date(event.startDate),
              endDate: event.endDate ? new Date(event.endDate) : undefined,
            })) as Event[];
            setEvents(parsedEvents);
            window.localStorage.setItem(getEventsKey(uid), JSON.stringify(parsedEvents));
          }
          if (cloudData[getSubjectsKey(uid)]) {
            setSubjects(cloudData[getSubjectsKey(uid)]);
            window.localStorage.setItem(getSubjectsKey(uid), JSON.stringify(cloudData[getSubjectsKey(uid)]));
          }
          if (cloudData[getScheduleKey(uid)]) {
            setSchedule(cloudData[getScheduleKey(uid)]);
            window.localStorage.setItem(getScheduleKey(uid), JSON.stringify(cloudData[getScheduleKey(uid)]));
          }
          if (cloudData[getProfilesKey(uid)]) {
            setProfiles(cloudData[getProfilesKey(uid)]);
            window.localStorage.setItem(getProfilesKey(uid), JSON.stringify(cloudData[getProfilesKey(uid)]));
          }
          if (cloudData[getNotesKey(uid)]) {
            const parsedNotes = (cloudData[getNotesKey(uid)] as any[]).map(note => ({
              ...note,
              createdAt: new Date(note.createdAt),
              updatedAt: new Date(note.updatedAt),
            })) as Note[];
            setNotes(parsedNotes);
            window.localStorage.setItem(getNotesKey(uid), JSON.stringify(cloudData[getNotesKey(uid)]));
          }
        }
      };
      syncData();
    } else if (!authLoading && !user) {
      // Clear state on logout
      setEvents([]);
      setSubjects([]);
      setSchedule([]);
      setProfiles([]);
      setNotes([]);
    }
  }, [user, authLoading]);

  const setAndSaveEvents = useCallback((data: Event[]) => {
    setEvents(data);
    if (user) {
      const key = getEventsKey(user.uid);
      window.localStorage.setItem(key, JSON.stringify(data));
      syncToFirestore(user, key, data);
    }
  }, [user]);

  const setAndSaveSubjects = useCallback((data: Subject[]) => {
    setSubjects(data);
    if (user) {
      const key = getSubjectsKey(user.uid);
      window.localStorage.setItem(key, JSON.stringify(data));
      syncToFirestore(user, key, data);
    }
  }, [user]);

  const setAndSaveSchedule = useCallback((data: ClassScheduleEntry[]) => {
    setSchedule(data);
    if (user) {
      const key = getScheduleKey(user.uid);
      window.localStorage.setItem(key, JSON.stringify(data));
      syncToFirestore(user, key, data);
    }
  }, [user]);

  const setAndSaveProfiles = useCallback((data: ScheduleProfile[]) => {
    setProfiles(data);
    if (user) {
      const key = getProfilesKey(user.uid);
      window.localStorage.setItem(key, JSON.stringify(data));
      syncToFirestore(user, key, data);
    }
  }, [user]);

  const setAndSaveNotes = useCallback((data: Note[]) => {
    setNotes(data);
    if (user) {
      const key = getNotesKey(user.uid);
      const dataToSave = data.map(n => {
        const { fileDataUri, ...rest } = n;
        return rest;
      });
      window.localStorage.setItem(key, JSON.stringify(dataToSave));
      syncToFirestore(user, key, dataToSave);
    }
  }, [user]);


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
    if (!isNewEventDialogOpen) {
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

  if (!isClient || authLoading || !user) {
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
            {!authLoading && user ? (
              <div className="flex items-center gap-2 mr-2">
                <Avatar className="h-8 w-8 border border-primary/20">
                  <AvatarImage src={user.photoURL || undefined} />
                  <AvatarFallback>{user.displayName?.charAt(0) || user.email?.charAt(0) || 'U'}</AvatarFallback>
                </Avatar>
                <Button onClick={signOut} variant="ghost" size="icon" className="h-8 w-8 text-muted-foreground hover:text-destructive transition-colors">
                  <LogOut className="h-4 w-4" />
                </Button>
              </div>
            ) : null}
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
              <Select value={activeTab} onValueChange={setActiveTab}>
                <SelectTrigger className="w-full">
                  <div className="flex items-center">
                    <SlidersHorizontal className="mr-2 h-4 w-4" />
                    <span>Vista: {tabs.find(t => t.value === activeTab)?.label}</span>
                  </div>
                </SelectTrigger>
                <SelectContent>
                  {tabs.map(tab => (
                    <SelectItem key={tab.value} value={tab.value}>
                      {tab.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
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
              <ScheduleView schedule={schedule} setSchedule={setAndSaveSchedule} subjects={subjects} profiles={profiles} setProfiles={setAndSaveProfiles} />
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
