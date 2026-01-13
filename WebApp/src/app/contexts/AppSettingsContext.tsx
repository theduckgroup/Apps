import { createContext, useContext } from 'react'

export type ThemeColor = 
  | 'teal' 
  | 'gray' 
  | 'red' 
  | 'pink' 
  | 'grape' 
  | 'violet' 
  | 'indigo' 
  | 'blue' 
  | 'cyan' 
  | 'green' 
  | 'lime' 
  | 'yellow' 
  | 'orange'

export interface AppSettingsContextType {
  themeColor: ThemeColor
  setThemeColor: (color: ThemeColor) => void
  availableColors: { value: ThemeColor; label: string; swatch: string }[]
}

export const AppSettingsContext = createContext<AppSettingsContextType | undefined>(undefined);

export function useAppSettings() {
  return useContext(AppSettingsContext)!
}