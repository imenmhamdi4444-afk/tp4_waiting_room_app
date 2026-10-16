# TP4 — Real-Time Waiting Room

The waiting room uses Flutter, Provider, and Supabase. Queue changes are stored in
Supabase and streamed to connected app instances.

## Local Supabase configuration

1. In Supabase, enable anonymous sign-ins in **Authentication → Providers**.
2. Create a `public.clients` table with:
   - `id`: `uuid`, primary key, default `gen_random_uuid()`
   - `name`: `text`, not null
   - `created_at`: `timestamptz`, not null, default `now()`
3. Enable Row Level Security. Anonymous Supabase Auth users use the PostgreSQL
   `authenticated` role, so the policies must target `authenticated`:

   ```sql
   create policy "Authenticated users can read clients"
   on public.clients for select to authenticated using (true);

   create policy "Authenticated users can add clients"
   on public.clients for insert to authenticated with check (true);

   create policy "Authenticated users can delete clients"
   on public.clients for delete to authenticated using (true);
   ```

   These policies make one shared public queue; they are for the workshop only,
   not private data or a production access model.
4. Enable Realtime/replication for the `clients` table (the `supabase_realtime`
   publication in the Supabase dashboard).
5. Copy `.env.example` to `.env` in the project root and fill in the project URL
   and the `anon`/publishable key from **Project Settings → API**:

   ```powershell
   Copy-Item .env.example .env
   ```

   `.env` is ignored by Git and is included as a Flutter asset at build time.
   The client key is not a secret; access must be controlled with RLS. Never
   put the `service_role` key in a Flutter app or commit it.
6. Run `flutter pub get`, then `flutter run`.

## Tests and realtime check

Run `flutter test` and `flutter analyze`. To verify cross-device updates, run
the app on two devices or browser sessions using the same Supabase project:
add a client on one device and confirm it appears on the other; use **Next
Client** on either device and confirm it disappears on both.
