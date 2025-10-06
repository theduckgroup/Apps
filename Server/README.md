# Auth Flow

See Auth/Server/

# Server

Configured in .env

- For dev: run on port 7021

- SERVER_URL env var contains the server hostname (used for auth redirect_uri)
  - For dev: http://localhost:7021
  - For prod: actual hostname
  
- WEBAPP_URL env var contains the webapp hostname (used for redirecting after authenticated) 
  - For dev: http://localhost:7022
  - For prod: (empty string)

# Webapp

Configured in vite.config.js

- Dev server runs on port 7022
- Dev server is configured to proxy request starting with `/auth` or `/api` to the server
- For prod, the app is built with output at Server/public folder