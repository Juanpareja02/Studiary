'use client';

import * as React from 'react';
import { Clock } from 'lucide-react';

import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';

interface TimePickerProps {
  date: Date | undefined;
  setDate: (date: Date | undefined) => void;
}

export function TimePicker({ date, setDate }: TimePickerProps) {
  const minuteRef = React.useRef<HTMLInputElement>(null);
  const hourRef = React.useRef<HTMLInputElement>(null);

  const handleHourChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const hour = parseInt(e.target.value, 10);
    if (!isNaN(hour) && hour >= 0 && hour <= 23) {
      const newDate = date ? new Date(date) : new Date();
      newDate.setHours(hour);
      setDate(newDate);
    }
  };

  const handleMinuteChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const minute = parseInt(e.target.value, 10);
    if (!isNaN(minute) && minute >= 0 && minute <= 59) {
      const newDate = date ? new Date(date) : new Date();
      newDate.setMinutes(minute);
      setDate(newDate);
    }
  };


  return (
    <div className="flex items-end gap-2">
      <div className="grid gap-1 text-center">
        <Label htmlFor="hours" className="text-xs">
          Horas
        </Label>
        <Input
          ref={hourRef}
          id="hours"
          type="number"
          min="0"
          max="23"
          value={date ? date.getHours().toString().padStart(2, '0') : ''}
          onChange={handleHourChange}
          className="w-[48px] p-1 text-center"
        />
      </div>
      <div className="px-1 text-xl font-bold self-center pb-1">:</div>
      <div className="grid gap-1 text-center">
        <Label htmlFor="minutes" className="text-xs">
          Minutos
        </Label>
        <Input
          ref={minuteRef}
          id="minutes"
          type="number"
          min="0"
          max="59"
          value={date ? date.getMinutes().toString().padStart(2, '0') : ''}
          onChange={handleMinuteChange}
          className="w-[48px] p-1 text-center"
        />
      </div>
    </div>
  );
}
