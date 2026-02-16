import type { EventType } from './types';

export const getEventColor = (type: EventType): string => {
  switch (type) {
    case 'prácticas':
      return 'bg-purple-300/80 hover:bg-purple-300 dark:bg-purple-800/80 dark:hover:bg-purple-700 text-purple-900 dark:text-purple-100';
    case 'estudio':
      return 'bg-pink-300/80 hover:bg-pink-300 dark:bg-pink-800/80 dark:hover:bg-pink-700 text-pink-900 dark:text-pink-100';
    case 'examen':
      return 'bg-orange-300/80 hover:bg-orange-300 dark:bg-orange-800/80 dark:hover:bg-orange-700 text-orange-900 dark:text-orange-100';
    case 'personal':
    default:
      return 'bg-teal-300/80 hover:bg-teal-300 dark:bg-teal-800/80 dark:hover:bg-teal-700 text-teal-900 dark:text-teal-100';
  }
};
