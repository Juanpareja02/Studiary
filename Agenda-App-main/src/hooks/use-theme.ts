
'use client';

import { useEffect, useState } from 'react';

const THEME_STORAGE_KEY = 'studiary-theme';

type Theme = {
  primary: string;
  background: string;
};

const defaultTheme: Theme = {
  primary: '#3B82F6', // blue-500
  background: '#F8FAFC', // slate-50
};

// Function to convert hex to HSL values [h, s, l]
const hexToHslArray = (hex: string): [number, number, number] => {
  let r = 0, g = 0, b = 0;
  if (hex.length === 4) {
    r = parseInt(hex[1] + hex[1], 16);
    g = parseInt(hex[2] + hex[2], 16);
    b = parseInt(hex[3] + hex[3], 16);
  } else if (hex.length === 7) {
    r = parseInt(hex.substring(1, 3), 16);
    g = parseInt(hex.substring(3, 5), 16);
    b = parseInt(hex.substring(5, 7), 16);
  }

  r /= 255; g /= 255; b /= 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  let h = 0, s = 0, l = (max + min) / 2;

  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = (g - b) / d + (g < b ? 6 : 0); break;
      case g: h = (b - r) / d + 2; break;
      case b: h = (r - g) / d + 4; break;
    }
    h /= 6;
  }

  return [Math.round(h * 360), Math.round(s * 100), Math.round(l * 100)];
};

// Function to convert hex to HSL CSS string "H S% L%"
const hexToHslString = (hex: string): string => {
  const [h, s, l] = hexToHslArray(hex);
  return `${h} ${s}% ${l}%`;
};

// Calculates luminance of a color
const getLuminance = (hex: string): number => {
    const rgb = parseInt(hex.substring(1), 16);
    const r = (rgb >> 16) & 0xff;
    const g = (rgb >>  8) & 0xff;
    const b = (rgb >>  0) & 0xff;
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255;
};


export function useTheme() {
  const [theme, setThemeState] = useState<Theme>(() => {
    if (typeof window === 'undefined') {
      return defaultTheme;
    }
    try {
      const savedTheme = window.localStorage.getItem(THEME_STORAGE_KEY);
      return savedTheme ? JSON.parse(savedTheme) : defaultTheme;
    } catch (error) {
      console.error('Error loading theme from localStorage:', error);
      return defaultTheme;
    }
  });

  const applyTheme = (themeToApply: Theme) => {
    const root = document.documentElement;

    const primaryHsl = hexToHslArray(themeToApply.primary);
    const backgroundHsl = hexToHslArray(themeToApply.background);
    
    // Set base colors
    root.style.setProperty('--primary', `${primaryHsl[0]} ${primaryHsl[1]}% ${primaryHsl[2]}%`);
    root.style.setProperty('--background', `${backgroundHsl[0]} ${backgroundHsl[1]}% ${backgroundHsl[2]}%`);
    
    // Auto-set foregrounds based on luminance for optimal contrast
    const primaryLuminance = getLuminance(themeToApply.primary);
    const backgroundLuminance = getLuminance(themeToApply.background);
    
    const primaryForeground = primaryLuminance > 0.5 ? '0 0% 0%' : '0 0% 100%'; // Black or White
    const foreground = backgroundLuminance > 0.5 ? '222.2 84% 4.9%' : '210 40% 98%'; // Dark Gray or White
    const cardForeground = foreground;
    const mutedForeground = backgroundLuminance > 0.5 ? '215.4 16.3% 46.9%' : '215 20.2% 65.1%'; // Gray
    
    root.style.setProperty('--primary-foreground', primaryForeground);
    root.style.setProperty('--foreground', foreground);
    root.style.setProperty('--card-foreground', cardForeground);
    root.style.setProperty('--popover-foreground', cardForeground);
    root.style.setProperty('--secondary-foreground', foreground);
    root.style.setProperty('--muted-foreground', mutedForeground);
    root.style.setProperty('--accent-foreground', foreground);
    
    // Derive other colors from background for consistency
    const isDarkBg = backgroundLuminance < 0.5;

    const cardL = isDarkBg ? Math.min(100, backgroundHsl[2] + 3) : Math.max(0, backgroundHsl[2] - 3);
    const popoverL = isDarkBg ? Math.min(100, backgroundHsl[2] + 2) : Math.max(0, backgroundHsl[2] - 2);
    const secondaryL = isDarkBg ? Math.min(100, backgroundHsl[2] + 5) : Math.max(0, backgroundHsl[2] - 5);
    const mutedL = secondaryL;
    const accentL = isDarkBg ? Math.min(100, backgroundHsl[2] + 8) : Math.max(0, backgroundHsl[2] - 8);
    const borderL = isDarkBg ? Math.min(100, backgroundHsl[2] + 10) : Math.max(0, backgroundHsl[2] - 10);
    const inputL = borderL;

    root.style.setProperty('--card', `${backgroundHsl[0]} ${backgroundHsl[1]}% ${cardL}%`);
    root.style.setProperty('--popover', `${backgroundHsl[0]} ${backgroundHsl[1]}% ${popoverL}%`);
    root.style.setProperty('--secondary', `${backgroundHsl[0]} ${backgroundHsl[1]}% ${secondaryL}%`);
    root.style.setProperty('--muted', `${backgroundHsl[0]} ${backgroundHsl[1]}% ${mutedL}%`);
    root.style.setProperty('--accent', `${backgroundHsl[0]} ${backgroundHsl[1]}% ${accentL}%`);
    root.style.setProperty('--border', `${backgroundHsl[0]} ${backgroundHsl[1]}% ${borderL}%`);
    root.style.setProperty('--input', `${backgroundHsl[0]} ${backgroundHsl[1]}% ${inputL}%`);

    // Keep destructive colors fixed for now as they have semantic meaning
    if (isDarkBg) {
      root.style.setProperty('--destructive', '0 62.8% 30.6%');
      root.style.setProperty('--destructive-foreground', '210 40% 98%');
    } else {
      root.style.setProperty('--destructive', '0 84.2% 60.2%');
      root.style.setProperty('--destructive-foreground', '210 40% 98%');
    }
  };

  useEffect(() => {
    if (typeof window !== 'undefined') {
      applyTheme(theme);
    }
  }, [theme]);
  
  const setTheme = (newTheme: Theme) => {
    try {
      window.localStorage.setItem(THEME_STORAGE_KEY, JSON.stringify(newTheme));
      setThemeState(newTheme);
    } catch (error) {
      console.error('Error saving theme to localStorage:', error);
    }
  };

  return { theme, setTheme };
}
