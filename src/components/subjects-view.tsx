
'use client';

import { useState } from 'react';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogTrigger,
} from '@/components/ui/dialog';
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
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion';
import { Checkbox } from '@/components/ui/checkbox';
import { Progress } from '@/components/ui/progress';
import { PlusCircle, Edit, Trash2, BookMarked, ClipboardCheck, ChevronDown } from 'lucide-react';
import type { Subject, Objective } from '@/lib/types';
import { HexColorPicker } from 'react-colorful';
import { cn } from '@/lib/utils';

interface SubjectsViewProps {
  subjects: Subject[];
  setSubjects: (subjects: Subject[]) => void;
}

const ObjectiveItem = ({
    objective,
    onToggle,
    onDelete
}: {
    objective: Objective;
    onToggle: () => void;
    onDelete: () => void;
}) => (
    <div className="flex items-center gap-2 p-2 rounded-md hover:bg-muted/50">
        <Checkbox
            id={`obj-${objective.id}`}
            checked={objective.completed}
            onCheckedChange={onToggle}
        />
        <label
            htmlFor={`obj-${objective.id}`}
            className="flex-1 text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
        >
            {objective.description}
        </label>
        <Button variant="ghost" size="icon" className="h-6 w-6 text-muted-foreground hover:text-destructive" onClick={onDelete}>
            <Trash2 className="h-4 w-4" />
        </Button>
    </div>
)


const AddObjectiveForm = ({ onAdd }: { onAdd: (description: string) => void }) => {
    const [description, setDescription] = useState('');
    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        if (description.trim()) {
            onAdd(description.trim());
            setDescription('');
        }
    };

    return (
        <form onSubmit={handleSubmit} className="flex items-center gap-2 mt-4 p-2 border rounded-md">
            <Input
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Nuevo objetivo..."
                className="h-8"
            />
            <Button type="submit" size="sm">Añadir</Button>
        </form>
    )
}

const ColorPickerPopover = ({ color, onChange, children }: { color: string, onChange: (color: string) => void, children: React.ReactNode }) => (
    <Popover>
        <PopoverTrigger asChild>
            {children}
        </PopoverTrigger>
        <PopoverContent className="w-auto p-0 border-0" align="start">
            <HexColorPicker color={color} onChange={onChange} />
        </PopoverContent>
    </Popover>
);

export default function SubjectsView({ subjects, setSubjects }: SubjectsViewProps) {
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingSubject, setEditingSubject] = useState<Subject | null>(null);
  const [subjectName, setSubjectName] = useState('');
  const [subjectColor, setSubjectColor] = useState('#aabbcc');

  const openNewDialog = () => {
    setEditingSubject(null);
    setSubjectName('');
    setSubjectColor('#' + Math.floor(Math.random()*16777215).toString(16).padStart(6, '0'));
    setIsDialogOpen(true);
  };

  const openEditDialog = (subject: Subject) => {
    setEditingSubject(subject);
    setSubjectName(subject.name);
    setSubjectColor(subject.color);
    setIsDialogOpen(true);
  };

  const handleSave = () => {
    if (editingSubject) {
      handleUpdateSubject(editingSubject.id, { name: subjectName, color: subjectColor });
    } else {
      setSubjects([
        ...subjects,
        { id: new Date().toISOString(), name: subjectName, color: subjectColor, objectives: [] },
      ]);
    }
    setIsDialogOpen(false);
  };

  const handleUpdateSubject = (subjectId: string, data: Partial<Subject>) => {
    setSubjects(
      subjects.map(s =>
        s.id === subjectId ? { ...s, ...data } : s
      )
    );
  };
  
  const handleDeleteSubject = (subjectId: string) => {
    setSubjects(subjects.filter(s => s.id !== subjectId));
  }
  
  const handleToggleObjective = (subjectId: string, objectiveId: string) => {
    setSubjects(subjects.map(s => {
        if (s.id === subjectId) {
            return {
                ...s,
                objectives: (s.objectives || []).map(o => 
                    o.id === objectiveId ? { ...o, completed: !o.completed } : o
                )
            };
        }
        return s;
    }));
  }

  const handleAddObjective = (subjectId: string, description: string) => {
    const newObjective: Objective = {
        id: new Date().toISOString(),
        description,
        completed: false,
    };
    setSubjects(subjects.map(s => {
        if (s.id === subjectId) {
            return {
                ...s,
                objectives: [...(s.objectives || []), newObjective]
            };
        }
        return s;
    }));
  }

  const handleDeleteObjective = (subjectId: string, objectiveId: string) => {
    setSubjects(subjects.map(s => {
        if (s.id === subjectId) {
            return {
                ...s,
                objectives: (s.objectives || []).filter(o => o.id !== objectiveId)
            };
        }
        return s;
    }));
  };
  
  const calculateProgress = (subject: Subject) => {
    const total = subject.objectives?.length || 0;
    if (total === 0) return 0;
    const completed = subject.objectives?.filter(o => o.completed).length || 0;
    return (completed / total) * 100;
  }

  return (
    <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
      <Card className="shadow-lg">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
              <CardTitle className="flex items-center gap-3 font-headline text-xl capitalize">
                <BookMarked className="h-6 w-6 text-primary" />
                Mis Asignaturas
            </CardTitle>
            <CardDescription>Añade, edita o elimina las asignaturas y sus objetivos de progreso.</CardDescription>
          </div>
          <DialogTrigger asChild>
            <Button onClick={openNewDialog}>
              <PlusCircle className="mr-2 h-4 w-4" />
              Nueva Asignatura
            </Button>
          </DialogTrigger>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {subjects.length > 0 ? (
                <Accordion type="multiple" className="w-full space-y-4">
                    {subjects.map(subject => (
                      <Card key={subject.id} className="overflow-hidden">
                         <AccordionItem value={subject.id} className="border-none">
                            <div className="p-4 flex items-center justify-between">
                                <div className="flex items-center gap-4 flex-1">
                                    <ColorPickerPopover color={subject.color} onChange={(color) => handleUpdateSubject(subject.id, { color })}>
                                        <button
                                            className="h-8 w-8 rounded-full flex-shrink-0 border-2 border-white/50 shadow-md"
                                            style={{ backgroundColor: subject.color }}
                                            aria-label={`Cambiar color de ${subject.name}`}
                                        />
                                    </ColorPickerPopover>
                                    <AccordionTrigger className="w-full flex hover:no-underline p-0">
                                        <div className="flex-1 text-left">
                                            <span className="font-medium">{subject.name}</span>
                                            <Progress value={calculateProgress(subject)} className="h-2 mt-1" />
                                        </div>
                                        <ChevronDown className="h-4 w-4 shrink-0 transition-transform duration-200 ml-4" />
                                    </AccordionTrigger>
                                </div>
                                <div className="flex items-center gap-1 ml-4">
                                    <Button variant="ghost" size="icon" onClick={() => openEditDialog(subject)}>
                                        <Edit className="h-4 w-4" />
                                    </Button>
                                    <AlertDialog>
                                        <AlertDialogTrigger asChild>
                                        <Button variant="ghost" size="icon" className="text-destructive hover:text-destructive">
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                        </AlertDialogTrigger>
                                        <AlertDialogContent>
                                        <AlertDialogHeader>
                                            <AlertDialogTitle>¿Estás seguro?</AlertDialogTitle>
                                            <AlertDialogDescription>
                                            Esta acción no se puede deshacer. Se eliminará la asignatura y todos sus objetivos.
                                            </AlertDialogDescription>
                                        </AlertDialogHeader>
                                        <AlertDialogFooter>
                                            <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                            <AlertDialogAction onClick={() => handleDeleteSubject(subject.id)}>Eliminar</AlertDialogAction>
                                        </AlertDialogFooter>
                                        </AlertDialogContent>
                                    </AlertDialog>
                                </div>
                            </div>
                            <AccordionContent className="p-4 pt-0">
                               <h4 className="font-semibold mb-2">Objetivos</h4>
                                <div className="space-y-1">
                                {(subject.objectives || []).map(obj => (
                                    <ObjectiveItem
                                        key={obj.id}
                                        objective={obj}
                                        onToggle={() => handleToggleObjective(subject.id, obj.id)}
                                        onDelete={() => handleDeleteObjective(subject.id, obj.id)}
                                    />
                                ))}
                                </div>
                                {(!subject.objectives || subject.objectives.length === 0) && (
                                     <p className="text-sm text-muted-foreground text-center py-4">No hay objetivos para esta asignatura.</p>
                                )}
                                <AddObjectiveForm onAdd={(desc) => handleAddObjective(subject.id, desc)} />
                            </AccordionContent>
                        </AccordionItem>
                      </Card>
                    ))}
                </Accordion>
            ) : (
                 <div className="flex flex-col items-center justify-center h-48 text-center border-2 border-dashed rounded-lg">
                    <BookMarked className="h-12 w-12 text-muted-foreground/50" />
                    <p className="mt-4 text-muted-foreground">
                        No has añadido ninguna asignatura todavía.
                    </p>
                </div>
            )}
          </div>
        </CardContent>
      </Card>

      <DialogContent>
        <DialogHeader>
          <DialogTitle>{editingSubject ? 'Editar Asignatura' : 'Nueva Asignatura'}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="name">Nombre de la Asignatura</Label>
            <Input
              id="name"
              value={subjectName}
              onChange={e => setSubjectName(e.target.value)}
              placeholder="Ej: Farmacología"
            />
          </div>
          <div className="space-y-2">
            <Label>Color</Label>
            <div className="flex justify-center">
               <HexColorPicker color={subjectColor} onChange={setSubjectColor} />
            </div>
            <Input
              value={subjectColor}
              onChange={e => setSubjectColor(e.target.value)}
              className="mt-2"
              aria-label="Código de color hexadecimal"
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => setIsDialogOpen(false)}>Cancelar</Button>
          <Button onClick={handleSave}>Guardar</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
