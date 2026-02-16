
'use client';

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import type { Event, Subject } from '@/lib/types';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { ClipboardList, GraduationCap, Percent } from 'lucide-react';
import { cn } from '@/lib/utils';
import React from 'react';

interface GradesViewProps {
  events: Event[];
  onEventClick: (event: Event) => void;
  subjects: Subject[];
}

const getGradeColor = (grade: number) => {
  if (grade < 5) return 'bg-red-200 text-red-800 border-red-300';
  if (grade < 7) return 'bg-yellow-200 text-yellow-800 border-yellow-300';
  if (grade < 9) return 'bg-green-200 text-green-800 border-green-300';
  return 'bg-blue-200 text-blue-800 border-blue-300';
};

const calculateWeightedAverage = (events: Event[]): number | null => {
  const gradedEvents = events.filter(e => 
    e.grade !== undefined && e.grade !== null &&
    e.weight !== undefined && e.weight !== null && e.weight > 0
  );

  if (gradedEvents.length === 0) {
     const nonWeightedEvents = events.filter(e => e.grade !== undefined && e.grade !== null);
     if (nonWeightedEvents.length === 0) return null;
     const sum = nonWeightedEvents.reduce((acc, event) => acc + (event.grade || 0), 0);
     return sum / nonWeightedEvents.length;
  }
  
  const totalWeight = gradedEvents.reduce((acc, event) => acc + (event.weight || 0), 0);
  if (totalWeight === 0) return null; // Avoid division by zero

  const weightedSum = gradedEvents.reduce((acc, event) => acc + (event.grade || 0) * (event.weight || 0), 0);
  
  return weightedSum / totalWeight;
}

export default function GradesView({ events, onEventClick, subjects }: GradesViewProps) {
  const gradedExams = events
    .filter(event => event.type === 'examen' && event.grade !== undefined && event.grade !== null)
    .sort((a, b) => b.startDate.getTime() - a.startDate.getTime());
  
  const subjectsWithGrades = subjects.map(subject => {
      const subjectExams = gradedExams.filter(e => e.subjectId === subject.id);
      const average = calculateWeightedAverage(subjectExams);
      return {
          ...subject,
          exams: subjectExams,
          averageGrade: average,
          totalWeight: subjectExams.reduce((acc, e) => acc + (e.weight || 0), 0),
      }
  }).filter(s => s.exams.length > 0);

  const overallAverage = calculateWeightedAverage(subjectsWithGrades.map(s => ({
      grade: s.averageGrade,
      weight: s.totalWeight,
  } as any)));

  return (
    <div className="grid grid-cols-1 gap-6">
      <Card className="shadow-lg">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-3 font-headline text-xl capitalize">
              <GraduationCap className="h-6 w-6 text-primary" />
              Resumen de Calificaciones
            </CardTitle>
            <CardDescription>
              Aquí puedes ver tus notas y la media ponderada por asignatura.
            </CardDescription>
          </div>
          <div className="text-right">
             <p className="text-sm text-muted-foreground">Nota Media General</p>
             <p className="text-2xl font-bold text-primary">{overallAverage !== null ? overallAverage.toFixed(2) : 'N/A'}</p>
          </div>
        </CardHeader>
        <CardContent>
          {gradedExams.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-48 text-center border-2 border-dashed rounded-lg">
                <ClipboardList className="h-12 w-12 text-muted-foreground/50" />
                <p className="mt-4 text-muted-foreground">
                    Aún no has añadido ninguna calificación.
                </p>
                 <p className="text-sm text-muted-foreground/80">
                    Edita un evento de tipo "Examen" para añadirle una nota.
                </p>
            </div>
          ) : (
            <div className="space-y-6">
                {subjectsWithGrades.map(subject => (
                     <Card key={subject.id} className="overflow-hidden">
                        <CardHeader className="flex flex-row items-center justify-between p-4" style={{backgroundColor: `${subject.color}20`}}>
                             <CardTitle className="text-lg font-semibold flex items-center gap-2" style={{color: subject.color}}>
                                {subject.name}
                             </CardTitle>
                             <div className="text-right">
                                <p className="text-sm" style={{color: `${subject.color}B3`}}>Nota Media</p>
                                <p className="text-xl font-bold" style={{color: subject.color}}>
                                    {subject.averageGrade !== null ? subject.averageGrade.toFixed(2) : 'N/A'}
                                </p>
                             </div>
                        </CardHeader>
                        <CardContent className="p-0">
                            <Table>
                                <TableHeader>
                                    <TableRow>
                                    <TableHead>Examen</TableHead>
                                    <TableHead className="hidden md:table-cell text-center">Fecha</TableHead>
                                    <TableHead className="hidden sm:table-cell text-center">Peso (%)</TableHead>
                                    <TableHead className="text-right">Nota</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {subject.exams.map(event => (
                                    <TableRow key={event.id} onClick={() => onEventClick(event)} className="cursor-pointer">
                                        <TableCell className="font-medium">{event.title}</TableCell>
                                        <TableCell className="hidden md:table-cell text-muted-foreground text-center">
                                            {format(event.startDate, "dd/MM/yy", { locale: es })}
                                        </TableCell>
                                        <TableCell className="hidden sm:table-cell text-muted-foreground text-center">
                                            {event.weight !== undefined ? `${event.weight}%` : '-'}
                                        </TableCell>
                                        <TableCell className="text-right">
                                            <Badge variant="outline" className={cn("text-base font-semibold", getGradeColor(event.grade!))}>
                                                {event.grade!.toFixed(2)}
                                            </Badge>
                                        </TableCell>
                                    </TableRow>
                                    ))}
                                </TableBody>
                            </Table>
                        </CardContent>
                     </Card>
                ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
