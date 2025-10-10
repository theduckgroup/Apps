import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import '@mantine/core/styles.css';
import { createTheme, MantineProvider } from '@mantine/core';
import { enableMapSet } from 'immer'

import './main.css'
import App from './app/App'
import { AuthProvider } from './app/providers/AuthProvider'

enableMapSet()

console.info('Create query client')
const queryClient = new QueryClient()

const theme = createTheme({
  colors: {
    // 'nd': colorsTuple('#153850'),
    // 'nd': [ // ND brand
    //   "#eff6fb",
    //   "#dfe9f0",
    //   "#b9d1e3",
    //   "#90b9d6",
    //   "#70a4cb",
    //   "#5b97c5",
    //   "#4f91c3",
    //   "#407dac",
    //   "#356f9b",
    //   "#246089"
    // ],
    // 'nd': [ // Tailwind cyan
    //   "#e0feff",
    //   "#ccf8ff",
    //   "#9cefff",
    //   "#68e6fe",
    //   "#43defd",
    //   "#2fdafd",
    //   "#1dd7fe",
    //   "#00bfe3",
    //   "#00aacb",
    //   "#0093b3"
    // ],
    // 'nd': [ // Brightened ND brand
    //   "#e7f7ff",
    //   "#d7ebf8",
    //   "#b0d3ea",
    //   "#86bbde",
    //   "#64a6d3",
    //   "#4d99cd",
    //   "#3f93cb",
    //   "#2f7fb4",
    //   "#2271a2",
    //   "#026291"
    // ],
    'nd': [ // Brightened #2
      "#eff6fb",
      "#dfe9f0",
      "#b9d2e3",
      "#90bad7",
      "#6fa5cc",
      "#5b99c6",
      "#4f92c4",
      "#407fad",
      "#35719b",
      "#23628a"
    ],
    'temp': [
      "#ecf8fd",
      "#daedf6",
      "#afd9ef",
      "#83c5e9",
      "#61b4e3",
      "#4eaae0",
      "#43a4e0",
      "#3690c7",
      "#2a80b2",
      "#0c5478"
    ],
    'ocean-blue': ['#7AD1DD', '#5FCCDB', '#44CADC', '#2AC9DE', '#1AC2D9', '#11B7CD', '#09ADC3', '#0E99AC', '#128797', '#147885'],
    'bright-pink': ['#F0BBDD', '#ED9BCF', '#EC7CC3', '#ED5DB8', '#F13EAF', '#F71FA7', '#FF00A1', '#E00890', '#C50E82', '#AD1374'],
  },
  primaryColor: 'teal',
  defaultRadius: 'sm'
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <MantineProvider defaultColorScheme='dark' theme={theme}>
          <App />
        </MantineProvider >
      </BrowserRouter>
    </QueryClientProvider>
  </StrictMode >
)
