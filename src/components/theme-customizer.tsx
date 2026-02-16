
'use client';

import { useState } from 'react';
import { Paintbrush, ChevronLeft } from 'lucide-react';
import { useTheme } from '@/hooks/use-theme';
import { Button } from '@/components/ui/button';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import { Label } from '@/components/ui/label';
import { HexColorPicker } from 'react-colorful';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';

type PickerType = 'primary' | 'background' | null;

export function ThemeCustomizer() {
  const { theme, setTheme } = useTheme();
  const [activePicker, setActivePicker] = useState<PickerType>(null);

  const handleColorChange = (newColor: string) => {
    if (activePicker) {
      setTheme({ ...theme, [activePicker]: newColor });
    }
  };

  const pickerTitle = activePicker === 'primary' ? 'Color Primario' : 'Color de Fondo';
  const currentColor = activePicker ? theme[activePicker] : '#000000';

  return (
    <Popover onOpenChange={(isOpen) => !isOpen && setActivePicker(null)}>
      <PopoverTrigger asChild>
        <Button variant="outline" size="icon">
          <Paintbrush className="h-4 w-4" />
          <span className="sr-only">Personalizar Tema</span>
        </Button>
      </PopoverTrigger>
      <PopoverContent
        align="end"
        className="z-50 w-64 p-0"
        onCloseAutoFocus={(e) => e.preventDefault()}
      >
        <ScrollArea className="h-auto max-h-[80vh]">
          <div className="p-4">
            {activePicker ? (
              <div className="space-y-4">
                 <div className="flex items-center gap-2">
                    <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => setActivePicker(null)}>
                        <ChevronLeft className="h-4 w-4" />
                    </Button>
                    <h3 className="font-semibold text-lg">{pickerTitle}</h3>
                </div>
                <div className="flex justify-center rounded-md border p-2">
                  <HexColorPicker 
                    color={currentColor}
                    onChange={handleColorChange}
                  />
                </div>
              </div>
            ) : (
              <div className="space-y-3">
                <div className="space-y-1">
                  <h3 className="font-semibold text-lg">Personaliza tu tema</h3>
                  <p className="text-sm text-muted-foreground">
                    Elige los colores para adaptar la aplicación.
                  </p>
                </div>
                <Separator />
                <div className="space-y-2">
                   <Button variant="outline" className="w-full justify-start" onClick={() => setActivePicker('primary')}>
                       <div className="flex items-center gap-2">
                           <div className="h-4 w-4 rounded-full border" style={{backgroundColor: theme.primary}} />
                           Color Primario
                       </div>
                   </Button>
                   <Button variant="outline" className="w-full justify-start" onClick={() => setActivePicker('background')}>
                       <div className="flex items-center gap-2">
                           <div className="h-4 w-4 rounded-full border" style={{backgroundColor: theme.background}} />
                           Color de Fondo
                       </div>
                   </Button>
                </div>
              </div>
            )}
          </div>
        </ScrollArea>
      </PopoverContent>
    </Popover>
  );
}
