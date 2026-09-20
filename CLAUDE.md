# CLAUDE.md — Next.js 15 + SQLite SaaS Template

## Stack & Versions
- **Framework:** Next.js 15 (App Router, React 19, Server Actions)
- **Language:** TypeScript 5+ (Strict mode, no `any`)
- **Database:** SQLite via `better-sqlite3` (local dev/single-instance) or `@libsql/client` (Turso edge deployment).
- **ORM / Query Builder:** Drizzle ORM (type-safe, explicit SQL control without heavy abstraction).
- **Styling:** Tailwind CSS v4 + shadcn/ui (unstyled accessible primitives).
- **Auth:** Better Auth (native SQLite adapter, stateless session cookies).
- **Validation:** Zod v3 (runtime type safety for API inputs, Server Actions, and env vars).

---

## Development Commands
```bash
npm run dev           # Start Next.js dev server with Turbopack
npm run build         # Production build (runs typecheck + db:generate)
npm run start         # Start production server
npm run lint          # Run Next.js linter (ESLint)
npm run typecheck     # Run TypeScript compiler check
npm run db:generate   # Generate Drizzle migration files
npm run db:migrate    # Apply pending migrations to SQLite database
npm run db:studio     # Launch Drizzle Studio (visual DB GUI)
```

---

## Folder Structure
```text
├── app/                  # Next.js App Router (colocated features)
│   ├── (auth)/           # Unauthenticated route group (login, register)
│   ├── (dashboard)/      # Authenticated SaaS app route group
│   │   ├── dashboard/    # Main user dashboard view
│   │   ├── settings/     # Account and billing settings
│   │   └── layout.tsx    # Dashboard shell (sidebar, header, auth guard)
│   ├── api/              # API route handlers (webhooks, file downloads)
│   ├── layout.tsx        # Root layout (fonts, providers, global styles)
│   └── page.tsx          # Public marketing landing page
├── components/           # Shared, reusable UI components
│   ├── ui/               # shadcn/ui primitives (button, dialog, input)
│   └── shared/           # App-specific reusable widgets (header, modals)
├── db/                   # Database layer
│   ├── index.ts          # Database client initialization & connection pooling
│   ├── schema.ts         # Single source of truth for Drizzle database schema
│   └── migrations/       # Version-controlled SQL migration files
├── lib/                  # Application business logic & utilities
│   ├── actions/          # Server Actions (categorized by domain, e.g., billing.ts)
│   ├── auth.ts           # Better Auth server configuration
│   └── utils.ts          # Pure helper functions (cn, formatters)
└── types/                # Global TypeScript type definitions
```

---

## Naming Conventions
- **Files & Folders:** `kebab-case` for all files and directories (e.g., `user-profile.tsx`, `billing-actions.ts`). *Reason: Prevents cross-platform casing bugs between macOS, Linux, and Windows.*
- **React Components:** `PascalCase` for component functions and filenames if exporting a single component (e.g., `SubmitButton.tsx`).
- **Database Tables:** `snake_case` plural nouns (e.g., `users`, `subscriptions`, `audit_logs`). *Reason: Aligns natively with SQL conventions and ORM naming standards.*
- **Database Columns:** `snake_case` (e.g., `created_at`, `stripe_customer_id`). *Reason: Avoids camelCase/snake_case mapping friction in raw SQL queries.*
- **TypeScript Types/Interfaces:** `PascalCase` without prefixes like `I` or `T` (e.g., `type User = ...`, `interface BillingProps = ...`).

---

## SQL & Database Migration Rules
1. **Never mutate production schemas directly:** All database changes must go through Drizzle migration files. Run `npm run db:generate` followed by `npm run db:migrate`. *Reason: Ensures reproducibility and prevents state drift between local dev and production.*
2. **Always define foreign keys with cascade rules:** Use `.references(() => table.id, { onDelete: 'cascade' })` where appropriate. *Reason: Prevents orphaned records in single-file SQLite databases.*
3. **Use WAL mode for SQLite:** Always initialize `better-sqlite3` with Write-Ahead Logging enabled (`PRAGMA journal_mode = WAL;`). *Reason: Dramatically improves concurrent read performance under Next.js server workloads.*
4. **Enforce timestamps:** Every table must include `created_at` (default to current timestamp) and `updated_at`. *Reason: Essential for auditing, debugging, and data synchronization.*
5. **No raw SQL strings in components:** All queries must live in `db/` or `lib/actions/` using Drizzle's query builder. *Reason: Prevents SQL injection vulnerabilities and keeps database logic testable.*

---

## Component & Architecture Patterns
1. **Server Components by Default:** All components in `app/` are Server Components unless they require browser APIs, state (`useState`), or event listeners (`onClick`). Add `'use client'` strictly at the top of leaf components. *Reason: Minimizes client-side JavaScript bundle size and executes database queries safely on the server.*
2. **Server Actions for Mutations:** Form submissions and data mutations must use Next.js Server Actions placed in `lib/actions/`. Validate all inputs inside the action using Zod before touching the database. *Reason: Provides type-safe end-to-end data flow without building custom REST endpoint boilerplate.*
3. **Colocation:** Keep domain-specific components, hooks, and utils near their consuming route when they are not shared globally. *Reason: Reduces codebase navigation fatigue as the SaaS grows.*
4. **Error Boundaries:** Wrap dashboard route groups in `error.tsx` boundaries to gracefully catch unhandled database or network failures. *Reason: Prevents the entire application shell from crashing when a single query fails.*

---

## What We Don't Do (And Why)
- **Do not use heavy ORMs like Prisma:** We use Drizzle ORM because it compiles directly to lightweight SQL queries with zero hidden runtime overhead and instantaneous startup times in serverless environments.
- **Do not use `useEffect` for data fetching:** Fetch data directly in Server Components using async/await or inside Server Actions. *Reason: Eliminates waterfall loading states, client-side loading spinners, and complex state management libraries like Redux or React Query for standard CRUD.*
- **Do not store secrets in client-side code:** Environment variables without the `NEXT_PUBLIC_` prefix must only be accessed inside Server Components, Server Actions, or API routes. *Reason: Leaking database connection strings or API secrets into browser bundles is a critical security vulnerability.*
- **Do not write custom CSS or inline styles:** Use Tailwind utility classes combined with `cn()` and shadcn/ui components. *Reason: Maintains design system consistency and speeds up UI development.*
- **Do not use `any` in TypeScript:** Use `unknown` with type guards or proper Zod parsing if dealing with untrusted external payloads. *Reason: Preserves strict type safety guarantees across the entire codebase.*