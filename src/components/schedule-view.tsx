
'use client';
import React from 'react';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { BookCopy, Trash2, Edit3, Plus, MoreVertical } from 'lucide-react';
import type { ClassScheduleEntry, Subject, ScheduleProfile } from '@/lib/types';
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Input } from '@/components/ui/input';

interface ScheduleViewProps {
  schedule: ClassScheduleEntry[];
  setSchedule: (schedule: ClassScheduleEntry[]) => void;
  subjects: Subject[];
  profiles: ScheduleProfile[];
  setProfiles: (profiles: ScheduleProfile[]) => void;
}

const weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
const timeSlots = Array.from({ length: 17 }, (_, i) => `${(i + 7).toString().padStart(2, '0')}:00`);
const ROW_HEIGHT_PX = 80;

const timeToMinutes = (time: string): number => {
  const [hours, minutes] = time.split(':').map(Number);
  return hours * 60 + minutes;
};

const NewScheduleEntryDialog = ({
  isOpen,
  setIsOpen,
  onSave,
  onDelete,
  subjects,
  entry,
  slot,
}: {
  isOpen: boolean;
  setIsOpen: (isOpen: boolean) => void;
  onSave: (entry: Omit<ClassScheduleEntry, 'id'> | ClassScheduleEntry) => void;
  onDelete: (id: string) => void;
  subjects: Subject[];
  entry: ClassScheduleEntry | null;
  slot: { day: number; time: string } | null;
}) => {
  const [subjectId, setSubjectId] = React.useState('');
  const [startTime, setStartTime] = React.useState('');
  const [endTime, setEndTime] = React.useState('');
  const [note, setNote] = React.useState('');

  React.useEffect(() => {
    if (entry) {
      setSubjectId(entry.subjectId);
      setStartTime(entry.startTime);
      setEndTime(entry.endTime);
      setNote(entry.note || '');
    } else if (slot) {
      const startMinutes = timeToMinutes(slot.time);
      const endMinutes = startMinutes + 60;
      const formatTime = (minutes: number) => {
        const h = Math.floor(minutes / 60).toString().padStart(2, '0');
        const m = (minutes % 60).toString().padStart(2, '0');
        return `${h}:${m}`;
      };
      setStartTime(formatTime(startMinutes));
      setEndTime(formatTime(endMinutes));
      setSubjectId('');
      setNote('');
    }
  }, [entry, slot, isOpen]);

  const handleSaveClick = () => {
    const dayOfWeek = entry ? entry.dayOfWeek : slot!.day;
    if (subjectId && startTime && endTime && timeToMinutes(startTime) < timeToMinutes(endTime)) {
      if (entry) {
        onSave({ id: entry.id, profileId: entry.profileId, dayOfWeek, startTime, endTime, subjectId, note });
      } else {
        onSave({ dayOfWeek, startTime, endTime, subjectId, note } as any); // cast temporary until passed to parent
      }
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{entry ? 'Editar Clase' : 'Añadir Clase'}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="subject">Asignatura</Label>
            <Select value={subjectId} onValueChange={setSubjectId}>
              <SelectTrigger id="subject">
                <SelectValue placeholder="Selecciona una asignatura" />
              </SelectTrigger>
              <SelectContent>
                {subjects.map((s) => (
                  <SelectItem key={s.id} value={s.id}>
                    {s.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="start-time">Hora de inicio</Label>
              <Input
                id="start-time"
                type="time"
                step="900"
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="end-time">Hora de fin</Label>
              <Input
                id="end-time"
                type="time"
                step="900"
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
              />
            </div>
          </div>
          <div className="space-y-2 flex flex-col pt-2">
            <Label htmlFor="note">Notas (Opcional)</Label>
            <Input
              id="note"
              value={note}
              onChange={e => setNote(e.target.value)}
              placeholder="Ej: Traer la bata"
            />
          </div>
        </div>
        <DialogFooter className="justify-between">
          {entry ? (
            <Button variant="destructive" onClick={() => onDelete(entry.id)}>
              <Trash2 className="mr-2 h-4 w-4" />
              Eliminar
            </Button>
          ) : (
            <div />
          )}
          <Button onClick={handleSaveClick}>Guardar</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};


export default function ScheduleView({ schedule, setSchedule, subjects, profiles, setProfiles }: ScheduleViewProps) {
  const [dialogOpen, setDialogOpen] = React.useState(false);
  const [selectedSlot, setSelectedSlot] = React.useState<{ day: number; time: string } | null>(null);
  const [editingEntry, setEditingEntry] = React.useState<ClassScheduleEntry | null>(null);
  const gridRef = React.useRef<HTMLDivElement>(null);
  const [currentProfileId, setCurrentProfileId] = React.useState<string>(profiles[0]?.id || 'default');

  React.useEffect(() => {
    if (profiles.length > 0 && !profiles.find(p => p.id === currentProfileId)) {
      setCurrentProfileId(profiles[0].id);
    }
  }, [profiles, currentProfileId]);

  const currentSchedule = schedule.filter(e => e.profileId === currentProfileId);

  const handleGridClick = (event: React.MouseEvent<HTMLDivElement>) => {
    if (!gridRef.current) return;
    const rect = gridRef.current.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;

    const dayIndex = Math.floor(x / (gridRef.current.offsetWidth / 7));
    const hour = Math.floor(y / ROW_HEIGHT_PX) + 7;

    if (dayIndex < 0 || dayIndex >= 7) return;

    const time = `${hour.toString().padStart(2, '0')}:00`;

    const clickedEntry = currentSchedule.find(entry => {
      const startMinutes = timeToMinutes(entry.startTime);
      const endMinutes = timeToMinutes(entry.endTime);
      const clickMinutes = (hour * 60);
      return entry.dayOfWeek === dayIndex + 1 &&
        clickMinutes >= startMinutes &&
        clickMinutes < endMinutes;
    });

    if (clickedEntry) {
      setEditingEntry(clickedEntry);
      setSelectedSlot(null);
    } else {
      setEditingEntry(null);
      setSelectedSlot({ day: dayIndex + 1, time });
    }
    setDialogOpen(true);
  };

  const handleEntryClick = (entry: ClassScheduleEntry, event: React.MouseEvent) => {
    event.stopPropagation();
    setEditingEntry(entry);
    setSelectedSlot(null);
    setDialogOpen(true);
  };

  const handleSave = (entryData: Omit<ClassScheduleEntry, 'id'> | ClassScheduleEntry) => {
    if ('id' in entryData) {
      // Update
      setSchedule(schedule.map((entry) => (entry.id === entryData.id ? { ...entryData, profileId: currentProfileId } : entry)));
    } else {
      // Add
      const newEntry: ClassScheduleEntry = {
        id: new Date().toISOString(),
        ...entryData,
        profileId: currentProfileId,
      };
      setSchedule([...schedule, newEntry]);
    }
    setDialogOpen(false);
  };

  const handleDelete = (entryId: string) => {
    setSchedule(schedule.filter((entry) => entry.id !== entryId));
    setDialogOpen(false);
  };


  return (
    <>
      <Card className="shadow-lg">
        <CardHeader className="flex flex-col sm:flex-row items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-3 font-headline text-xl capitalize">
              <BookCopy className="h-6 w-6 text-primary" />
              Mi Horario de Clases
            </CardTitle>
            <CardDescription>
              Define tu horario semanal. Haz clic en una celda para añadir o editar una clase.
            </CardDescription>
          </div>
          <div className="flex items-center gap-2 mt-4 sm:mt-0">
            <Select value={currentProfileId} onValueChange={setCurrentProfileId}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Seleccionar Horario" />
              </SelectTrigger>
              <SelectContent>
                {profiles.map(p => (
                  <SelectItem key={p.id} value={p.id}>{p.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Button variant="outline" size="icon" onClick={() => {
              const name = prompt("Nombre del nuevo horario:");
              if (name) {
                const id = new Date().toISOString();
                setProfiles([...profiles, { id, name }]);
                setCurrentProfileId(id);
              }
            }}>
              <Plus className="h-4 w-4" />
            </Button>
          </div>
        </CardHeader>
        <CardContent className="p-2 sm:p-4">
          <div className="overflow-x-auto bg-card p-4">
            <div className="relative flex" style={{ minWidth: '800px' }}>
              {/* Time Column */}
              <div className="flex flex-col border-r" style={{ width: '60px' }}>
                <div className="h-10"></div> {/* Spacer for day headers */}
                {timeSlots.map(time => (
                  <div key={time} style={{ height: `${ROW_HEIGHT_PX}px` }} className="flex items-center justify-center text-sm text-muted-foreground border-t">
                    {time}
                  </div>
                ))}
              </div>

              {/* Schedule Grid */}
              <div className="flex-1 grid grid-cols-7">
                {/* Day Headers */}
                {weekdays.map(day => (
                  <div key={day} className="h-10 text-center font-semibold p-2 border-b border-l">
                    {day}
                  </div>
                ))}
                {/* Grid background & click handler */}
                <div
                  ref={gridRef}
                  className="col-span-7 grid grid-cols-7 relative"
                  onClick={handleGridClick}
                  style={{ height: `${timeSlots.length * ROW_HEIGHT_PX}px` }}
                >
                  {Array.from({ length: 7 * timeSlots.length }).map((_, i) => (
                    <div key={i} className="border-t border-l"></div>
                  ))}

                  {/* Render schedule entries */}
                  {currentSchedule.map(entry => {
                    const subject = subjects.find(s => s.id === entry.subjectId);
                    if (!subject) return null;

                    const startMinutes = timeToMinutes(entry.startTime) - 7 * 60;
                    const endMinutes = timeToMinutes(entry.endTime) - 7 * 60;

                    // Overlapping resolution
                    const dayEntries = currentSchedule.filter(e => e.dayOfWeek === entry.dayOfWeek).sort((a, b) => timeToMinutes(a.startTime) - timeToMinutes(b.startTime));
                    const columns: (ClassScheduleEntry[])[] = [];
                    let myColIndex = 0;
                    for (const e of dayEntries) {
                      let placed = false;
                      for (let c = 0; c < columns.length; c++) {
                        const last = columns[c][columns[c].length - 1];
                        if (timeToMinutes(last.endTime) <= timeToMinutes(e.startTime)) {
                          columns[c].push(e);
                          if (e.id === entry.id) myColIndex = c;
                          placed = true;
                          break;
                        }
                      }
                      if (!placed) {
                        columns.push([e]);
                        if (e.id === entry.id) myColIndex = columns.length - 1;
                      }
                    }
                    const maxCols = columns.length;

                    const top = (startMinutes / (15 * 60)) * (timeSlots.length * ROW_HEIGHT_PX);
                    const height = ((endMinutes - startMinutes) / (15 * 60)) * (timeSlots.length * ROW_HEIGHT_PX);
                    const dayWidthPct = 100 / 7;

                    const left = `calc(${((entry.dayOfWeek - 1) / 7) * 100}% + ${(dayWidthPct / maxCols) * myColIndex}%)`;
                    const width = `calc(${dayWidthPct / maxCols}% - 4px)`;

                    return (
                      <div
                        key={entry.id}
                        className="absolute rounded-lg p-2 text-white shadow-md overflow-hidden flex flex-col cursor-pointer transition-transform hover:scale-[1.02] hover:z-20 ring-1 ring-white/20"
                        style={{
                          top: `${top}px`,
                          height: `${height}px`,
                          left: left,
                          width: width,
                          marginLeft: '2px',
                          marginRight: '2px',
                          backgroundColor: subject.color,
                          zIndex: 10 + myColIndex,
                        }}
                        onClick={(e) => handleEntryClick(entry, e)}
                      >
                        <p className="font-bold text-xs sm:text-sm truncate leading-tight">
                          {subject.name}
                          {entry.note && ' 📝'}
                        </p>
                        {subject.classroom && <p className="text-[10px] sm:text-xs opacity-90 truncate">{subject.classroom}</p>}
                        <p className="text-[10px] sm:text-xs mt-auto opacity-80">{entry.startTime} - {entry.endTime}</p>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
      <NewScheduleEntryDialog
        isOpen={dialogOpen}
        setIsOpen={setDialogOpen}
        onSave={handleSave}
        onDelete={handleDelete}
        subjects={subjects}
        entry={editingEntry}
        slot={selectedSlot}
      />
    </>
  );
}
