
'use client';

import { useEffect, useCallback, useRef } from 'react';
import { Event } from '@/lib/types';
import { isToday, isTomorrow, format } from 'date-fns';
import { es } from 'date-fns/locale';

const NOTIFICATION_INTERVAL = 15 * 60 * 1000; // 15 minutes

export function useNotifications(events: Event[]) {
  const lastCheckedRef = useRef<Date>(new Date());

  const checkAndRequestPermission = useCallback(async () => {
    if (!('Notification' in window)) {
      console.log('Este navegador no soporta notificaciones de escritorio.');
      return false;
    }
    if (Notification.permission === 'granted') {
      return true;
    }
    if (Notification.permission !== 'denied') {
      const permission = await Notification.requestPermission();
      return permission === 'granted';
    }
    return false;
  }, []);

  const sendNotification = useCallback((title: string, options: NotificationOptions) => {
    new Notification(title, {
      ...options,
      icon: '/favicon.ico', // Puedes cambiar esto a un icono más específico
    });
  }, []);

  const scheduleNotifications = useCallback(async () => {
    const hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return;

    const now = new Date();
    // Previene múltiples notificaciones en un corto período de tiempo
    if (now.getTime() - lastCheckedRef.current.getTime() < 60000) { // 1 minuto
        return;
    }
    lastCheckedRef.current = now;

    events.forEach(event => {
        let notify = false;
        let body = '';

        if (isToday(event.startDate)) {
            notify = true;
            body = `Hoy a las ${format(event.startDate, 'p', { locale: es })}.`;
        } else if ((event.type === 'examen' || event.type === 'prácticas') && isTomorrow(event.startDate)) {
            notify = true;
            body = `Mañana a las ${format(event.startDate, 'p', { locale: es })}.`;
        }
        
        if (notify) {
            sendNotification(event.title, {
                body: `${event.description || ''}\n${body}`,
                tag: event.id, // Usar el ID del evento como tag para evitar duplicados
            });
        }
    });

  }, [events, checkAndRequestPermission, sendNotification]);

  useEffect(() => {
    scheduleNotifications(); // Comprobar al cargar y cada vez que los eventos cambien

    const intervalId = setInterval(scheduleNotifications, NOTIFICATION_INTERVAL);

    return () => {
      clearInterval(intervalId);
    };
  }, [scheduleNotifications]);
}
