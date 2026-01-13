import { ReactNode, useEffect, useState } from 'react'

import { AppSettingsContext, AppSettingsContextType, ThemeColor } from './AppSettingsContext'

const SETTINGS_KEY_PREFIX = 'app-settings-'
const THEME_COLOR_KEY = `${SETTINGS_KEY_PREFIX}theme-color`

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
  const [themeColor, setThemeColorState] = useState<ThemeColor>(() => {
    const saved = localStorage.getItem(THEME_COLOR_KEY)
    if (saved && availableColors.some(c => c.value === saved)) {
      return saved as ThemeColor
    }
    return 'teal'
  })

  useEffect(() => {
    localStorage.setItem(THEME_COLOR_KEY, themeColor)
  }, [themeColor])

  const setThemeColor = (color: ThemeColor) => {
    setThemeColorState(color)
  }

  const value: AppSettingsContextType = {
    themeColor,
    setThemeColor,
    availableColors
  }

  return (
    <AppSettingsContext.Provider value={value}>
      {children}
    </AppSettingsContext.Provider>
  )
}
