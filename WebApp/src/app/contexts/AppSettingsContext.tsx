import { createContext, useContext, useState, ReactNode, useEffect } from 'react'

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

interface AppSettingsContextType {
  themeColor: ThemeColor
  setThemeColor: (color: ThemeColor) => void
  availableColors: { value: ThemeColor; label: string; swatch: string }[]
  // Additional settings can be added here in the future
}

const AppSettingsContext = createContext<AppSettingsContextType | undefined>(undefined)

const SETTINGS_KEY_PREFIX = 'app-settings-'
const THEME_COLOR_KEY = `${SETTINGS_KEY_PREFIX}theme-color`

// Available theme colors with labels and sample swatches (Open Color palette)
const availableColors: { value: ThemeColor; label: string; swatch: string }[] = [
  { value: 'teal', label: 'Teal (Default)', swatch: '#12b886' },
  { value: 'gray', label: 'Gray', swatch: '#868e96' },
  { value: 'red', label: 'Red', swatch: '#fa5252' },
  { value: 'pink', label: 'Pink', swatch: '#e64980' },
  { value: 'grape', label: 'Grape', swatch: '#be4bdb' },
  { value: 'violet', label: 'Violet', swatch: '#7950f2' },
  { value: 'indigo', label: 'Indigo', swatch: '#4c6ef5' },
  { value: 'blue', label: 'Blue', swatch: '#228be6' },
  { value: 'cyan', label: 'Cyan', swatch: '#15aabf' },
  { value: 'green', label: 'Green', swatch: '#40c057' },
  { value: 'lime', label: 'Lime', swatch: '#82c91e' },
  { value: 'yellow', label: 'Yellow', swatch: '#fab005' },
  { value: 'orange', label: 'Orange', swatch: '#fd7e14' }
]

export function AppSettingsProvider({ children }: { children: ReactNode }) {
  // Load saved color from localStorage or default to 'teal'
  const [themeColor, setThemeColorState] = useState<ThemeColor>(() => {
    const saved = localStorage.getItem(THEME_COLOR_KEY)
    if (saved && availableColors.some(c => c.value === saved)) {
      return saved as ThemeColor
    }
    return 'teal'
  })

  // Save to localStorage when color changes
  useEffect(() => {
    localStorage.setItem(THEME_COLOR_KEY, themeColor)
  }, [themeColor])

  const setThemeColor = (color: ThemeColor) => {
    setThemeColorState(color)
  }

  return (
    <AppSettingsContext.Provider value={{ themeColor, setThemeColor, availableColors }}>
      {children}
    </AppSettingsContext.Provider>
  )
}

export function useAppSettings() {
  const context = useContext(AppSettingsContext)
  if (context === undefined) {
    throw new Error('useAppSettings must be used within an AppSettingsProvider')
  }
  return context
}