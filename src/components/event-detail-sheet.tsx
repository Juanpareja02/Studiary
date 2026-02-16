
'use client';

import { useState, useEffect } from 'react';
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
  SheetFooter,
} from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { Input } from '@/components/ui/input';
import { Separator } from '@/components/ui/separator';
import { Badge } from '@/components/ui/badge';
import { Calendar, Clock, Edit, Trash2, Book, Percent, GraduationCap, Check, X } from 'lucide-react';
import { format, isSameDay } from 'date-fns';
import { es } from 'date-fns/locale';
import type { Event, Subject } from '@/lib/types';
import { getEventColor } from '@/lib/colors';
import { EventIcon } from './icons';
import { cn } from '@/lib/utils';
import { generateGoogleCalendarLink } from '@/lib/calendar';

interface EventDetailSheetProps {
  event?: Event;
  isOpen: boolean;
  setIsOpen: (isOpen: boolean) => void;
  onEdit: (event: Event) => void;
  onDelete: (eventId: string) => void;
  onUpdate: (event: Event) => void;
  subjects: Subject[];
}

const DetailRow = ({ icon: Icon, label, value, action }: { icon: React.ElementType, label: string, value: React.ReactNode, action?: React.ReactNode }) => (
  <div className="flex items-start gap-4">
    <div className="text-muted-foreground w-6 h-6 flex-shrink-0 flex items-center justify-center">
      <Icon className="h-5 w-5" />
    </div>
    <div className="flex flex-col flex-1">
      <span className="text-sm text-muted-foreground">{label}</span>
      <div className="flex items-center justify-between">
        <div className="font-medium flex-1">{value}</div>
        {action && <div className="ml-4">{action}</div>}
      </div>
    </div>
  </div>
);


export default function EventDetailSheet({ event, isOpen, setIsOpen, onEdit, onDelete, onUpdate, subjects }: EventDetailSheetProps) {
  const [isEditingGrade, setIsEditingGrade] = useState(false);
  const [editableGrade, setEditableGrade] = useState<string | number>('');

  useEffect(() => {
      if(event?.grade !== undefined && event?.grade !== null) {
        setEditableGrade(event.grade);
      } else {
        setEditableGrade('');
      }
      setIsEditingGrade(false);
  }, [event]);


  if (!event) return null;

  const subject = event.subjectId ? subjects.find(s => s.id === event.subjectId) : null;
  const eventColorClass = event.color ? '' : getEventColor(event.type);

  const handleSaveGrade = () => {
    const newGrade = parseFloat(editableGrade as string);
    if (!isNaN(newGrade) && newGrade >= 0 && newGrade <= 10) {
        onUpdate({ ...event, grade: newGrade });
    }
    setIsEditingGrade(false);
  }

  const handleCancelEditGrade = () => {
    if(event?.grade !== undefined && event?.grade !== null) {
      setEditableGrade(event.grade);
    } else {
      setEditableGrade('');
    }
    setIsEditingGrade(false);
  }


  return (
    <Sheet open={isOpen} onOpenChange={setIsOpen}>
      <SheetContent className="flex flex-col">
        <SheetHeader className="pr-12">
          <SheetTitle
            className={cn("text-2xl font-headline flex items-center gap-3", !event.color && 'text-white')}
            style={event.color ? { color: event.color } : {}}
          >
            <span className={cn("p-2 rounded-lg", eventColorClass)} style={{ backgroundColor: event.color }}>
              <EventIcon type={event.type} className="h-6 w-6 text-white" />
            </span>
            {event.title}
          </SheetTitle>
           <SheetDescription>{event.description || "No hay descripción para este evento."}</SheetDescription>
        </SheetHeader>
        <Separator />
        <div className="flex-1 space-y-6 py-6 overflow-y-auto">
          <DetailRow 
            icon={Calendar} 
            label="Fecha"
            value={
              isSameDay(event.startDate, event.endDate || event.startDate)
                ? format(event.startDate, "EEEE, d 'de' MMMM 'de' yyyy", { locale: es })
                : `${format(event.startDate, "d MMM yyyy", { locale: es })} - ${format(event.endDate!, "d MMM yyyy", { locale: es })}`
            }
          />
           <DetailRow 
            icon={Clock} 
            label="Hora"
            value={
              event.isAllDay 
                ? 'Todo el día' 
                : `${format(event.startDate, "p", { locale: es })} - ${format(event.endDate || event.startDate, "p", { locale: es })}`
            }
          />
          {subject && (
             <DetailRow 
                icon={Book} 
                label="Asignatura"
                value={
                  <Badge style={{ backgroundColor: subject.color }} className="text-white">{subject.name}</Badge>
                }
              />
          )}
          {event.type === 'examen' && (
             <DetailRow 
                icon={GraduationCap} 
                label="Calificación"
                value={
                    isEditingGrade ? (
                        <Input 
                            type="number" 
                            step="0.1" 
                            value={editableGrade}
                            onChange={(e) => setEditableGrade(e.target.value)}
                            className="h-8 w-24"
                        />
                    ) : (
                        event.grade !== undefined && event.grade !== null 
                        ? `${event.grade.toFixed(2)} / 10`
                        : <span className="text-muted-foreground">Sin calificar</span>
                    )
                }
                action={
                    isEditingGrade ? (
                        <div className="flex items-center gap-1">
                            <Button variant="ghost" size="icon" className="h-8 w-8 text-green-500" onClick={handleSaveGrade}><Check className="h-5 w-5" /></Button>
                            <Button variant="ghost" size="icon" className="h-8 w-8 text-red-500" onClick={handleCancelEditGrade}><X className="h-5 w-5" /></Button>
                        </div>
                    ) : (
                        <Button variant="ghost" size="sm" onClick={() => setIsEditingGrade(true)}>
                            <Edit className="h-4 w-4 mr-2" />
                            {event.grade !== undefined && event.grade !== null ? 'Editar' : 'Añadir'}
                        </Button>
                    )
                }
              />
          )}
           {event.type === 'examen' && event.weight !== undefined && event.weight !== null && (
             <DetailRow 
                icon={Percent} 
                label="Ponderación"
                value={`${event.weight}%`}
              />
          )}

        </div>
        <SheetFooter className="grid grid-cols-2 gap-2 sm:flex-col-reverse sm:space-x-0">
            <AlertDialog>
                <AlertDialogTrigger asChild>
                    <Button variant="destructive">
                        <Trash2 className="mr-2 h-4 w-4" />
                        Eliminar
                    </Button>
                </AlertDialogTrigger>
                <AlertDialogContent>
                <AlertDialogHeader>
                    <AlertDialogTitle>¿Estás seguro?</AlertDialogTitle>
                    <AlertDialogDescription>
                    Esta acción no se puede deshacer. Esto eliminará permanentemente el evento.
                    </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                    <AlertDialogCancel>Cancelar</AlertDialogCancel>
                    <AlertDialogAction onClick={() => onDelete(event.id)}>Eliminar</AlertDialogAction>
                </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
            <Button onClick={() => onEdit(event)}>
                <Edit className="mr-2 h-4 w-4" />
                Editar Evento
            </Button>
             <div className="col-span-2">
                <Button variant="outline" className="w-full" asChild>
                    <a href={generateGoogleCalendarLink(event)} target="_blank" rel="noopener noreferrer">Añadir a Google Calendar</a>
                </Button>
            </div>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  );
}
