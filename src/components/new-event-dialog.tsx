
'use client';

import { useState, useEffect } from 'react';
import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import * as z from 'zod';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { Calendar as CalendarIcon, ExternalLink, Trash2, Palette } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Calendar } from '@/components/ui/calendar';
import { cn } from '@/lib/utils';
import type { Event, EventType, Subject } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
import { TimePicker } from './time-picker';
import { generateGoogleCalendarLink } from '@/lib/calendar';
import { HexColorPicker } from 'react-colorful';

interface NewEventDialogProps {
  isOpen: boolean;
  setIsOpen: (isOpen: boolean) => void;
  onAddEvent: (event: Omit<Event, 'id'>) => Event;
  onUpdateEvent: (event: Event) => Event;
  eventToEdit?: Event;
  initialDate?: Date;
  initialTime?: string;
  subjects: Subject[];
}

const eventTypes: EventType[] = ['prácticas', 'estudio', 'examen', 'personal'];

const formSchema = z.object({
  title: z.string().min(2, {
    message: 'El título debe tener al menos 2 caracteres.',
  }),
  description: z.string().optional(),
  startDate: z.date({
    required_error: 'Se requiere una fecha de inicio.',
  }),
  endDate: z.date().optional(),
  type: z.enum(eventTypes),
  grade: z.coerce.number().min(0).max(10).optional(),
  weight: z.coerce.number().min(0).max(100).optional(),
  subjectId: z.string().optional(),
  color: z.string().optional(),
}).refine(data => !data.endDate || data.endDate >= data.startDate, {
  message: 'La fecha de fin debe ser posterior o igual a la fecha de inicio.',
  path: ['endDate'],
});

export default function NewEventDialog({
  isOpen,
  setIsOpen,
  onAddEvent,
  onUpdateEvent,
  eventToEdit,
  initialDate,
  initialTime,
  subjects
}: NewEventDialogProps) {
  const { toast } = useToast();
  const [color, setColor] = useState('#aabbcc');

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
        title: '',
        description: '',
        startDate: new Date(),
        endDate: undefined,
        type: 'personal',
        grade: undefined,
        weight: undefined,
        subjectId: undefined,
        color: undefined,
    }
  });
  
  const eventType = form.watch('type');

  useEffect(() => {
    if (isOpen) {
      if (eventToEdit) {
        form.reset({
            ...eventToEdit,
            endDate: eventToEdit.endDate || undefined,
            grade: eventToEdit.grade ?? undefined,
            weight: eventToEdit.weight ?? undefined,
            subjectId: eventToEdit.subjectId || undefined,
            color: eventToEdit.color || undefined,
        });
        setColor(eventToEdit.color || '#' + Math.floor(Math.random()*16777215).toString(16).padStart(6, '0'))
      } else {
          let date = initialDate ? new Date(initialDate) : new Date();
          
          if (initialTime) {
              const [hours, minutes] = initialTime.split(':');
              date.setHours(parseInt(hours, 10));
              date.setMinutes(parseInt(minutes, 10));
          } else if (initialDate) {
              // Default to 9am for a passed date without time, but keep existing time if it's today
              if (initialDate.getHours() === 0 && initialDate.getMinutes() === 0) {
                 date.setHours(9, 0, 0, 0);
              }
          } else {
             // For brand new event via button, default to current time
             const now = new Date();
             date.setHours(now.getHours(), now.getMinutes());
          }

          const newColor = '#' + Math.floor(Math.random()*16777215).toString(16).padStart(6, '0');
          form.reset({
              title: '',
              description: '',
              startDate: date,
              endDate: undefined,
              type: 'personal',
              grade: undefined,
              weight: undefined,
              subjectId: undefined,
              color: newColor,
          });
          setColor(newColor);
      }
    }
  }, [isOpen, eventToEdit, initialDate, initialTime, form]);

  useEffect(() => {
    form.setValue('color', color);
  }, [color, form]);

  const closeDialog = () => {
    setIsOpen(false);
  }

  async function onSubmit(values: z.infer<typeof formSchema>) {
    const isEditing = !!eventToEdit;
    
    const eventData: Partial<Event> = {
      ...values,
      endDate: values.endDate || undefined,
      grade: values.grade,
      weight: values.weight,
      subjectId: values.subjectId,
      color: values.color,
    };
    
    if (values.type !== 'examen') {
      eventData.grade = undefined;
      eventData.subjectId = undefined;
      eventData.weight = undefined;
    }

    let savedEvent: Event;

    if (isEditing) {
      savedEvent = onUpdateEvent({ ...eventToEdit, ...eventData } as Event);
    } else {
      savedEvent = onAddEvent(eventData as Omit<Event, 'id'>);
    }
    
    toast({
      title: isEditing ? "Evento Actualizado" : "Evento Creado",
      description: `Se ha guardado "${values.title}" correctamente.`,
      action: (
        <a 
          href={generateGoogleCalendarLink(savedEvent)} 
          target="_blank" 
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2"
        >
          <Button variant="outline" size="sm">
            <ExternalLink className="h-4 w-4 mr-2" />
            Añadir a Google
          </Button>
        </a>
      ),
    });
    closeDialog();
  }
  
  const handleDateChange = (newDate: Date | undefined, field: 'startDate' | 'endDate') => {
      if (!newDate) {
          form.setValue(field, undefined);
          return;
      }
      
      const currentFieldValue = form.getValues(field);
      const currentDate = currentFieldValue ? new Date(currentFieldValue) : new Date();

      newDate.setHours(currentDate.getHours());
      newDate.setMinutes(currentDate.getMinutes());
      
      form.setValue(field, newDate);
  }

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogContent className="max-h-screen overflow-y-auto sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>{eventToEdit ? 'Editar Evento' : 'Añadir Nuevo Evento'}</DialogTitle>
          <DialogDescription>
            {eventToEdit ? 'Modifica los detalles de tu evento.' : 'Rellena los detalles de tu nuevo evento.'}
          </DialogDescription>
        </DialogHeader>
        <ScrollArea className="max-h-[70vh] w-full pr-6">
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              <FormField
                control={form.control}
                name="title"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Título</FormLabel>
                    <FormControl>
                      <Input placeholder="Ej: Repaso de farmacología" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              
              <FormField
                control={form.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Descripción</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Ej: Temas 5 al 7. Hospital de día."
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="startDate"
                  render={({ field }) => (
                    <FormItem className="flex flex-col">
                      <FormLabel>Fecha de inicio</FormLabel>
                      <Popover>
                        <PopoverTrigger asChild>
                          <FormControl>
                            <Button
                              variant={'outline'}
                              className={cn(
                                'w-full justify-start text-left font-normal',
                                !field.value && 'text-muted-foreground'
                              )}
                            >
                              <CalendarIcon className="mr-2 h-4 w-4" />
                              {field.value ? (
                                format(field.value, 'PPP p', { locale: es })
                              ) : (
                                <span>Elige una fecha</span>
                              )}
                            </Button>
                          </FormControl>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0" align="start">
                          <Calendar
                            mode="single"
                            selected={field.value}
                            onSelect={(date) => handleDateChange(date, 'startDate')}
                            initialFocus
                            locale={es}
                          />
                          <div className="p-3 border-t border-border">
                            <TimePicker setDate={field.onChange} date={field.value} />
                          </div>
                        </PopoverContent>
                      </Popover>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="endDate"
                  render={({ field }) => (
                    <FormItem className="flex flex-col">
                      <FormLabel>Fecha de fin (opcional)</FormLabel>
                      <Popover>
                        <PopoverTrigger asChild>
                          <FormControl>
                            <Button
                              variant={'outline'}
                              className={cn(
                                'w-full justify-start text-left font-normal',
                                !field.value && 'text-muted-foreground'
                              )}
                            >
                              <CalendarIcon className="mr-2 h-4 w-4" />
                              {field.value ? (
                                format(field.value, 'PPP p', { locale: es })
                              ) : (
                                <span>Elige una fecha</span>
                              )}
                            </Button>
                          </FormControl>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0" align="start">
                          <Calendar
                            mode="single"
                            selected={field.value}
                            onSelect={(date) => handleDateChange(date, 'endDate')}
                            initialFocus
                            locale={es}
                            disabled={{ before: form.getValues('startDate') }}
                          />
                          <div className="p-3 border-t border-border">
                            <TimePicker setDate={field.onChange} date={field.value} />
                          </div>
                        </PopoverContent>
                      </Popover>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
              
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <FormField
                  control={form.control}
                  name="type"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Tipo</FormLabel>
                      <Select
                        onValueChange={field.onChange}
                        value={field.value}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Selecciona un tipo de evento" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="prácticas">Prácticas</SelectItem>
                          <SelectItem value="estudio">Estudio</SelectItem>
                          <SelectItem value="examen">Examen</SelectItem>
                          <SelectItem value="personal">Personal</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                {eventType === 'examen' ? (
                    <FormField
                      control={form.control}
                      name="subjectId"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Asignatura</FormLabel>
                          <Select onValueChange={field.onChange} value={field.value}>
                            <FormControl>
                              <SelectTrigger>
                                <SelectValue placeholder="Selecciona una asignatura" />
                              </SelectTrigger>
                            </FormControl>
                            <SelectContent>
                              {subjects.map(subject => (
                                <SelectItem key={subject.id} value={subject.id}>{subject.name}</SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                ) : (
                  <FormItem>
                    <FormLabel>Color</FormLabel>
                      <Popover>
                        <PopoverTrigger asChild>
                           <Button variant="outline" className="w-full justify-start">
                              <div className="flex items-center gap-2">
                                <div className="h-4 w-4 rounded-full border" style={{backgroundColor: color}} />
                                {color}
                              </div>
                           </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0 border-0" align="start">
                            <HexColorPicker color={color} onChange={setColor} />
                        </PopoverContent>
                      </Popover>
                  </FormItem>
                )}
              </div>
              {eventType === 'examen' && (
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <FormField
                      control={form.control}
                      name="grade"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Calificación (opcional)</FormLabel>
                          <FormControl>
                            <Input type="number" step="0.1" placeholder="Ej: 8.5" {...field} value={field.value ?? ''} onChange={event => field.onChange(event.target.value === '' ? undefined : +event.target.value)} />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                    <FormField
                      control={form.control}
                      name="weight"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Porcentaje (%)</FormLabel>
                          <FormControl>
                            <Input type="number" step="1" placeholder="Ej: 40" {...field} value={field.value ?? ''} onChange={event => field.onChange(event.target.value === '' ? undefined : +event.target.value)} />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                  </div>
                )}

              <DialogFooter className="sm:justify-end pt-4">
                <Button type="submit">{eventToEdit ? 'Guardar Cambios' : 'Añadir Evento'}</Button>
              </DialogFooter>
            </form>
          </Form>
        </ScrollArea>
      </DialogContent>
    </Dialog>
  );
}
