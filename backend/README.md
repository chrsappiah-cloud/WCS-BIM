# WCS-BIM Node API

```bash
cp .env.example .env
npm install
npm run dev
```

Apply [`../docs/ai-bim-supabase-schema.sql`](../docs/ai-bim-supabase-schema.sql) to PostgreSQL/Supabase first. The API validates project creation with Zod, reads project-linked resources, proxies material optimization to the Python service, and provides Codex-style QA, design, and fabrication endpoints.

Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` to validate Supabase Auth bearer tokens. The reusable helpers in `src/supabaseAuth.ts` provide email/password sign-in and sign-out for TypeScript clients. `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are also accepted by that module for a Next.js client.

Set `JWT_SECRET` only when the local signed-JWT fallback is required. Leave all authentication settings empty only for local development. Keep `SUPABASE_SERVICE_ROLE_KEY` on the Node gateway and never expose it to iOS or browser clients.

Start the complete local stack with:

```bash
docker compose up --build
```
