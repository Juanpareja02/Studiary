

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
  objectives?: Objective[];
}

export interface ClassScheduleEntry {
  id:string;
  dayOfWeek: number; // 0 for Sunday, 1 for Monday, etc.
  startTime: string; // "HH:mm"
  endTime: string; // "HH:mm"
  subjectId: string;
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

