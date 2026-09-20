# CLAUDE.md — Next.js 15 + SQLite SaaS Template

## Stack & Versions
- **Framework:** Next.js 15 (App Router, React 19)
- **Language:** TypeScript (Strict mode enabled)
- **Database:** SQLite via `better-sqlite3` (local) or `@libsql/client` (Turso edge)
- **ORM / Query Builder:** Drizzle ORM (type-safe, explicit SQL control)
- **Styling:** Tailwind CSS v4 + shadcn/ui (unstyled primitives)
- **Auth:** Better Auth (session-based, lightweight SQLite adapter)
- **Validation:** Zod v3 (runtime type safety for API inputs and environment variables)

---

## Development Commands
```bash
npm run dev           # Start Next.js dev server with Turbopack
npm run build         # Production build (validates types and prerendering)
npm run start         # Start production server
npm run lint          # Run ESLint and TypeScript compiler check
npm run db:generate   # Generate Drizzle migration files from schema changes
npm run db:migrate    # Apply pending SQLite migrations
npm run db:studio     # Open Drizzle Studio to inspect local SQLite DB
```

---

## Folder Structure
```text
├── app/                  # Next.js App Router (pages, layouts, API routes)
│   ├── (auth)/           # Route group for unauthenticated flows (login, register)
│   ├── (dashboard)/      # Route group for authenticated app views
│   │   ├── dashboard/    # Main user dashboard
│   │   └── settings/     # Account and billing settings
│   ├── api/              # API route handlers (JSON endpoints, webhooks)
│   ├── layout.tsx        # Root layout with providers
│   └── page.tsx          # Public landing page
├── components/           # React components
│   ├── ui/               # shadcn/ui primitives (button, dialog, input, etc.)
│   └── shared/           # Cross-feature components (header, footer, user-menu)
├── db/                   # Database layer
│   ├── schema.ts         # Drizzle ORM database schema definitions
│   ├── index.ts          # Database client singleton connection
│   └── migrations/       # Generated SQL migration files
├── lib/                  # Shared utilities and configurations
│   ├── auth.ts           # Better Auth server configuration
│   ├── utils.ts          # Helper functions (cn, formatting)
│   └── validators/       # Zod validation schemas
├── types/                # TypeScript global type definitions
└── public/               # Static assets (images, fonts, icons)
```

---

## Naming Conventions
- **Files & Folders:** `kebab-case` for all files and directories (e.g., `user-profile.tsx`, `payment-modal.tsx`), except Next.js special files (`page.tsx`, `layout.tsx`, `route.ts`).
- **React Components:** `PascalCase` for component functions (e.g., `export function UserProfile()`).
- **Database Tables:** `snake_case` and plural nouns (e.g., `users`, `subscriptions`, `audit_logs`).
- **Database Columns:** `snake_case` (e.g., `created_at`, `stripe_customer_id`, `is_active`).
- **TypeScript Types & Interfaces:** `PascalCase` without prefixes or suffixes like `I` or `Type` (e.g., `type User = ...`, `interface SubscriptionProps = ...`).
- **Constants:** `UPPER_SNAKE_CASE` for global configuration constants (e.g., `MAX_UPLOAD_SIZE_MB`).

---

## Database & Migration Rules
1. **Never edit applied migrations:** Once a migration file is committed and applied to production or staging databases, it is immutable. Create a new migration for subsequent changes.
   - *Reason:* Modifying history breaks schema sync across environments and corrupts the migration journal.
2. **Always use Drizzle for schema definitions:** Define tables, indexes, and relations strictly inside `db/schema.ts`.
   - *Reason:* Keeps a single source of truth for TypeScript types and prevents raw SQL drift.
3. **Run `npm run db:migrate` on startup / deployment:** Ensure migrations run before the Next.js process accepts traffic.
   - *Reason:* Prevents runtime errors where application code expects new columns or tables that don't exist yet.
4. **Enforce Foreign Key Constraints:** Always define `.references(() => ...)` and appropriate onDelete cascades.
   - *Reason:* SQLite does not enforce foreign keys by default in some older environments; explicit Drizzle relations and SQLite PRAGMA settings ensure referential integrity.

---

## Component Patterns
1. **Server Components by Default:** All components in `app/` are Server Components unless interactivity is strictly required.
   - *Reason:* Reduces client-side JavaScript bundles and allows direct, secure database queries inside the component tree.
2. **Explicit Client Boundary:** Add `'use client'` only at the absolute leaf of the component tree that requires React hooks, event listeners, or browser APIs.
   - *Reason:* Maximizes Server Component rendering performance and prevents accidental leakage of server-only modules (like database clients) to the client bundle.
3. **Zod Validation at Boundaries:** Validate all incoming user data (Server Actions, API route inputs, URL search parameters) using Zod schemas before processing.
   - *Reason:* Guarantees runtime type safety and stops malformed data from reaching the database layer.

---

## What We Don't Do (Anti-Patterns)
1. **Never import `db/index.ts` inside Client Components:**
   - *Why:* It exposes database credentials and native Node bindings (`better-sqlite3`) to the browser, causing hard build crashes or security vulnerabilities.
2. **Never use `any` or `@ts-ignore` in TypeScript code:**
   - *Why:* Bypasses the strict type safety guarantees required for maintaining a robust SaaS backend and predictable refactoring.
3. **Never write raw SQL strings inside components or API routes:**
   - *Why:* Bypasses Drizzle's query builder safety, opening the codebase to SQL injection vectors and untyped result sets. Always use the Drizzle query API.
4. **Never perform blocking database queries in root layouts without suspense:**
   - *Why:* Blocks the initial HTML shell streaming of the entire page, destroying Time to First Byte (TTFB) metrics. Wrap database-dependent layout parts in `<Suspense>`.
5. **Never use barrel files (`index.ts` exporting an entire folder):**
   - *Why:* Slows down Next.js hot module replacement (HMR) and bloats client-side bundles by importing unneeded modules. Import directly from the file path.