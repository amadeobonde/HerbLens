# HerbLens — Scan. Learn. Brew.

iOS app for identifying herbs and medicinal plants using AI vision, with a full knowledge base, recipe library, and conversational AI assistant. Point your camera at a plant and get an instant ID, health properties, brewing instructions, and AI-powered chat.

## What It Does

- **Scan** — Camera-based plant identification using Gemini Vision API with confidence scoring
- **Barcode scan** — Identify packaged herbs from product barcodes
- **Herb Vault** — Searchable database of 100+ herbs with properties, contraindications, and sourcing
- **Recipes** — Tea, tincture, and remedy recipes with step-by-step brewing guides and real photography
- **AI Chat** — Context-aware Claude-powered assistant that knows which plant you're looking at
- **Onboarding + Paywall** — Full subscription flow with usage-gated premium features

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | SwiftUI, iOS 16+, async/await |
| Backend | Supabase (PostgreSQL, Auth, Storage, Realtime) |
| Serverless | Deno Edge Functions (plant ID pipeline, recipe generation) |
| AI — Vision | Gemini Vision API (plant identification) |
| AI — Chat | Claude API (context-aware herb assistant) |
| Auth | Supabase Auth (email + JWT, session persistence) |
| Image Pipeline | AsyncImage with Wikipedia/Openverse CDN, daily rotation |

## Architecture

```
iOS App (SwiftUI)
    │
    ├── Camera → Gemini Vision API → Deno Edge Function → Plant ID Result
    │                                        │
    │                                   Supabase DB (herb data, user history)
    │
    ├── Chat → Claude API (with herb context injected in system prompt)
    │
    └── Vault → Supabase PostgreSQL (100+ herbs, properties, recipes)
```

## Features Built

- [x] Real-time camera scan with bounding box overlay
- [x] Barcode scanning for packaged herb products
- [x] AI plant identification with confidence scores and alternative matches
- [x] Full herb profile pages (properties, contraindications, sourcing, seasonality)
- [x] Recipe library with hero photography and step-by-step instructions
- [x] AI chat scoped to identified plant context
- [x] Animated mascot system for onboarding and empty states
- [x] Subscription paywall with usage-gated premium herbs
- [x] Offline-tolerant vault (cached herb data)
- [x] Admin test accounts for QA flows
- [x] Supabase RLS policies for per-user data isolation

## How to Run

**Prerequisites:** Xcode 15+, a Supabase project, Gemini API key, Anthropic API key

```bash
git clone https://github.com/amadeobonde/HerbLens
cd HerbLens/HerbLens
```

1. Create a Supabase project and run migrations:
   ```bash
   cd ../supabase
   supabase db push
   supabase db seed  # optional: seed herb data
   ```

2. Deploy edge functions:
   ```bash
   supabase functions deploy identify-plant
   supabase functions deploy generate-recipes
   ```

3. Configure API keys in `HerbLens/Config/`:
   ```swift
   // Config.swift (not committed — copy from Config.example.swift)
   static let supabaseURL = "your-project-url"
   static let supabaseAnonKey = "your-anon-key"
   static let geminiAPIKey = "your-gemini-key"
   static let anthropicAPIKey = "your-anthropic-key"
   ```

4. Open `HerbLens.xcodeproj` → select target → `Cmd+R`

## Database Schema

```
herbs            — id, name, latin_name, properties[], contraindications[], image_url
recipes          — id, herb_id, type (tea/tincture/remedy), steps[], brew_time
user_history     — user_id, herb_id, scanned_at
user_vault       — user_id, herb_id (saved herbs)
```

Row-level security enforces per-user data isolation on all user tables.

## Project Structure

```
HerbLens/
├── HerbLens/
│   ├── App/            # Entry point, root navigation
│   ├── Features/       # Feature modules (Scan, Vault, Recipes, Chat, Profile...)
│   ├── Services/       # API clients (Supabase, Gemini, Claude)
│   ├── Shared/         # Design system, components, extensions
│   └── Config/         # Environment config (gitignored)
├── supabase/
│   ├── functions/      # Deno edge functions
│   ├── migrations/     # SQL migrations
│   └── seed.sql        # Herb database seed
└── HerbLensTests/
```

## What I Learned

- Gemini Vision performs well for plant ID at medium confidence thresholds — below ~0.65 it's better to ask the user for a clearer photo than surface a wrong result
- Deno edge functions add ~80ms cold start; pre-warming with a scheduled ping keeps it under 200ms for real users
- SwiftUI's `@Sendable` closures interact poorly with `@MainActor` state mutations in tab navigation — plain closures with explicit `Task { @MainActor in }` are safer
- Supabase RLS + Deno service-role key is the right split: client uses anon key, edge function uses service-role for privileged DB writes

## License

MIT
