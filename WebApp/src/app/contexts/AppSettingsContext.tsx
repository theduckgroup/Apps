import { createContext, useContext, useState, ReactNode, useEffect } from 'react'

export type ThemeColor = 'teal' | 'nd' | 'temp' | 'ocean-blue' | 'bright-pink'

interface AppSettingsContextType {
  themeColor: ThemeColor
  setThemeColor: (color: ThemeColor) => void
  availableColors: { value: ThemeColor; label: string; swatch: string }[]
  // Additional settings can be added here in the future
}

const AppSettingsContext = createContext<AppSettingsContextType | undefined>(undefined)

const SETTINGS_KEY_PREFIX = 'app-settings-'
const THEME_COLOR_KEY = `${SETTINGS_KEY_PREFIX}theme-color`

// Available theme colors with labels and sample swatches
const availableColors: { value: ThemeColor; label: string; swatch: string }[] = [
  { value: 'teal', label: 'Teal (Default)', swatch: '#12b886' },
  { value: 'nd', label: 'Naked Duck Blue', swatch: '#4f92c4' },
  { value: 'temp', label: 'Temp Blue', swatch: '#43a4e0' },
  { value: 'ocean-blue', label: 'Ocean Blue', swatch: '#2AC9DE' },
  { value: 'bright-pink', label: 'Bright Pink', swatch: '#F13EAF' }
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