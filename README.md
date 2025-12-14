# Overview

This project hosts multiple apps. 

- All apps share the same server; each app occupies a folder with their routes etc
- All apps share the same web app
- iOS apps are separate but are in the same workspace with a Common package

# Server

- Run: npm run nodemon

# Web App

- Run: `npm run dev -- --host`

  - `--host` makes the app available on local network

- Build when changes are detected: `npm run build-watch`

- `vite.config.js` notes:
  - Dev server runs on port 8022
  - Dev server forwards requests starting with `/api` to server
  - For prod, the app is built with output at Server/public folder

# Notes
- bson npm package is locked to version 4 because bson@5 and @6 rely on top-level await, which is not available
- `useCallback` is important if you are using functions as dependencies for useEffect; this is because  every time the component changes, a new function is created!
- Strict Mode causes components to be mounted twice, so requests will be fired twice, and maybe same for web sockets
