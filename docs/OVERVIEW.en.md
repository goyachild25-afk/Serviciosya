# YALO — Project overview (for collaborators)

**Tagline:** *"¿Ya lo resolviste? Con YALO, sí."* ("Got it solved yet? With YALO, you do.")

## What YALO is

YALO is a **home-services marketplace for the Dominican Republic**. It connects
clients who need household help (cleaning, plumbing, electrical, gardening,
elderly/child care, moving, appliance repair, etc.) with **verified local
providers**, end to end inside a single app: discovery, instant or scheduled
booking, in-app chat, live location sharing, identity verification, and
(next phase) in-app payment.

Think of it as the "Uber/TaskRabbit for household services" built specifically
for the Dominican market — Spanish-first, cédula-based identity verification,
and compliance with Dominican data-protection law (Ley 172-13).

## Who uses it (three roles)

- **Client (solicitante):** searches or requests a service, chats with the
  provider, shares their exact GPS location, pays, and rates the job.
- **Provider (prestador):** sets up services and prices, completes **mandatory
  identity verification**, receives and accepts nearby requests, and navigates
  to the client. Providers cannot operate until identity-verified and approved.
- **Admin:** verifies identities, resolves disputes, manages users and
  bookings, and monitors finances and analytics.

## How YALO makes money

A **10% commission per completed service**: 5% "Garantía YALO" (a guarantee fee
added on the client side) + 5% "Membresía de Visibilidad" (a visibility fee
deducted from the provider). In-app payment (AZUL/CardNET) is the next phase;
today the pilot coordinates cash payment directly, with the commission model
already coded.

## Trust and safety (core to the product)

Providers enter people's homes, so identity is non-negotiable:

- **Mandatory KYC** via [Didit](https://didit.me): live capture of national ID
  (cédula) + selfie with liveness detection and face match.
- The automated result is **decision support only** — a human admin gives the
  final approval. No one operates unverified.
- Biometric documents auto-delete 90 days after review; explicit consent is
  recorded. Anti-spam blocks phone/email exchange in chat to keep transactions
  on-platform.

## What's built and live today

Both marketplace sides are connected in real time:

- Web Push notifications (standard VAPID, no Firebase) in both directions:
  providers get notified of new matching requests even with the app closed;
  clients get notified the moment a provider accepts.
- Real GPS location captured on requests, shareable in chat, with a
  "Get directions" button (Google Maps / Waze).
- Profile photos in chat with a full-screen viewer.
- Requests without a provider auto-expire after 24h; one-tap "request again".
- Provider levels (New → Featured → Expert → Elite), ratings, live activity map.
- Full admin panel (9 tabs), demo mode, accessibility options, and Ley 172-13
  data export/delete.

## Where it's going (roadmap)

1. **In-app payments** (AZUL/CardNET or an aggregator like Fygaro) — pending
   business formalization (RNC + commercial bank account).
2. **YALO Points** — cashback loyalty to keep payments in-app.
3. Migrate to the `yalo.do` custom domain.
4. Admin/provider quality-of-life improvements (CSV export, net-earnings
   breakdown, distance filtering, etc.).

## Tech stack (start here)

- **Frontend:** Flutter Web (Dart), Riverpod state management, go_router.
- **Backend:** Supabase — Postgres with Row Level Security, Auth, Realtime,
  Storage, Edge Functions (Deno), pg_cron, pg_net.
- **Hosting/CI:** GitHub Pages + GitHub Actions (verify → build → deploy).

For the deeper docs, read in this order:
[ARQUITECTURA.md](ARQUITECTURA.md) (architecture) →
[BACKEND.md](BACKEND.md) (database, functions, cron) →
[CONFIGURACION.md](CONFIGURACION.md) (dev setup, build, deploy) →
[SEGURIDAD_Y_PRIVACIDAD.md](SEGURIDAD_Y_PRIVACIDAD.md) (verification, privacy) →
[ESTADO.md](ESTADO.md) (living status: what works, what's pending).

> Note: the codebase and docs are Spanish-first because the product and market
> are Dominican. This overview is the English entry point; the deeper docs are
> in Spanish but the code, table names, and identifiers are English/standard.
