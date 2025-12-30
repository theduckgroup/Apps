# CLAUDE.md

## Repository Overview

This is a multi-platform monorepo containing web applications, backend server, and iOS native applications. All apps share the same Node.js/Express backend server. The web applications share a single React frontend. iOS apps are separate but share a Common Swift package.

## Project Structure

```
/Apps (Monorepo root)
├── Server/               # Backend API server (Node.js/Express/TypeScript)
├── WebApp/               # Web application frontend (React/Vite/TypeScript)
└── iOS/                  # iOS applications (Swift/SwiftUI)
    ├── Common/           # Shared Swift packages
    ├── SuperDuck/        # Main iOS app (active development)
    ├── WeeklySpending/   # iOS expense tracking app
    ├── Quiz/             # iOS quiz app
    └── NakedBlendCalc/   # iOS calculator app
```

### Multi-App Backend Pattern

The Express server hosts multiple sub-applications via route prefixing:

- `/api/quiz-app` - Quiz management
- `/api/ws-app` - Weekly Spending (expense tracking)
- `/api/inventory-app` - Inventory management (active development)
- `/api/admin` - Admin operations
- `/api/reset-password` - Password reset flow

Each sub-app has its own:
- Router with public/user/admin endpoints
- Models and Zod schemas
- Event hub for real-time updates

**Entry point:** `Server/src/index.ts`

### Path Aliases

Both Server and WebApp use `src/` path aliases in their TypeScript configurations. Import from `src/...` rather than relative paths.

## Important Notes

- Server and Web App uses TypeScript
  - No trailing comma
  - Single quote instead of double quote
