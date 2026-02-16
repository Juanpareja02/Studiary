
import type { LucideProps } from 'lucide-react';
import { Stethoscope, BookOpen, FilePenLine, Star, ClipboardList, Notebook, Timer, GraduationCap } from 'lucide-react';
import type { EventType } from '@/lib/types';

export const EventIcon = ({
  type,
  ...props
}: { type: EventType } & LucideProps) => {
  const commonProps = {
    className: 'h-4 w-4 text-accent-foreground/80 shrink-0',
    ...props,
  };

  switch (type) {
    case 'prácticas':
      return <Stethoscope {...commonProps} />;
    case 'estudio':
      return <BookOpen {...commonProps} />;
    case 'examen':
      return <FilePenLine {...commonProps} />;
    case 'personal':
    default:
      return <Star {...commonProps} />;
  }
};
