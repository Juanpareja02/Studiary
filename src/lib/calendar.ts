import type { Event } from './types';

// Formats a date for Google Calendar links.
// The format is YYYYMMDDTHHMMSSZ, and the time is in UTC.
const formatGoogleCalendarDate = (date: Date): string => {
  return date.toISOString().replace(/-|:|\.\d{3}/g, '');
};

export const generateGoogleCalendarLink = (event: Event): string => {
  const baseUrl = 'https://www.google.com/calendar/render?action=TEMPLATE';
  
  const title = encodeURIComponent(event.title);
  const startDate = formatGoogleCalendarDate(event.startDate);
  
  // Use end date if available, otherwise add 1 hour to start date
  const endDate = event.endDate 
    ? formatGoogleCalendarDate(event.endDate)
    : formatGoogleCalendarDate(new Date(event.startDate.getTime() + 60 * 60 * 1000));
  
  const details = event.description ? encodeURIComponent(event.description) : '';

  return `${baseUrl}&text=${title}&dates=${startDate}/${endDate}&details=${details}`;
};
