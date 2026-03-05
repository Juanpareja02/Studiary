

export type EventType = 'prácticas' | 'estudio' | 'examen' | 'personal';

export type Event = {
  id: string;
  title: string;
  startDate: Date;
  endDate?: Date;
  type: EventType;
  description?: string;
  isAllDay?: boolean;
  grade?: number;
  subjectId?: string;
  weight?: number; // Porcentaje sobre la nota final (ej: 20 para 20%)
  color?: string;
};

export interface Objective {
  id: string;
  description: string;
  completed: boolean;
}

export interface Subject {
  id: string;
  name: string;
  color: string;
  classroom?: string; // Nuevo campo aula
  objectives?: Objective[];
}

export interface ScheduleProfile {
  id: string;
  name: string;
}

export interface ClassScheduleEntry {
  id: string;
  profileId: string; // IDs para distinguir entre distintos horarios
  dayOfWeek: number; // 0 for Sunday, 1 for Monday, etc.
  startTime: string; // "HH:mm"
  endTime: string; // "HH:mm"
  subjectId: string;
  note?: string; // Notas adicionales para cada celda
}

export type NoteType = 'text' | 'pdf' | 'image';

export interface Note {
  id: string;
  title: string;
  content?: string; // For text notes
  fileDataUri?: string; // For PDF/image notes
  fileName?: string;
  type: NoteType;
  subjectId: string;
  createdAt: Date;
  updatedAt: Date;
  archived: boolean;
}

