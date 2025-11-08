# Crownborn: Shattered Lineage — Architecture

**Version:** 2025-11-08T18:38:24Z  
**Platforms:** Android, iOS, Web (leaderboard)  
**Monetization:** IAP for currency (Stripe on web), no royalties except platform fees  
**Ownership:** Source-available, you own all code/art; uses open or permissive stacks

---

## 1) Game Identity
- **Game Title:** **Crownborn: Shattered Lineage**
- **In-Game Currency:** **Skycrowns (SC)**

---

## 2) Tech Stack (Open & Mobile-Friendly)

### Client / Game
- **Engine:** **Godot 4.x** (MIT)
- **Languages:** **GDScript** (gameplay/tools), **C#** (perf-critical AI/utilities)
- **3D Tooling:** Blender (models/rigs), Krita/GIMP (textures), optional ArmorPaint
- **Graphics:** Vulkan (Forward+) with fallback **GLES3** for broad device support
- **Mobile Export:** Android .aab (Gradle), iOS Xcode (StoreKit)

### Backend (Leaderboards, Accounts, Economy)
- **API:** FastAPI (Python), uvicorn, pydantic
- **Database:** PostgreSQL
- **Cache/Queue:** Redis (rate-limits, sessions, LB cache), RQ/Celery workers
- **Realtime:** WebSockets or SSE for live leaderboard updates
- **Auth:** Platform IDs (Google Play Games / Apple Game Center) + guest; JWT for sessions
- **Payments:** Google Play Billing, Apple IAP (server-side validation), **Stripe** for web
- **Analytics (optional, self-host):** PostHog
- **CDN (optional):** Cloudflare for static site assets

### DevOps & Observability
- **Containerization:** Docker (docker-compose), later K8s
- **CI/CD:** GitHub Actions (client export + server build/test/deploy)
- **TLS/Edge:** Caddy or Nginx
- **Metrics/Logs:** Prometheus + Grafana, Loki for logs
- **Security:** HTTPS, WAF rules, fail2ban, secrets in vault or OIDC

---

## 3) Game Client Architecture (Godot 4)

```
GameRoot
 ├─ Systems/
 │   ├─ GameState (signals: relative_saved, lives, currency, powers)
 │   ├─ SaveManager (encrypted; optional cloud sync via API)
 │   ├─ EconomyManager (IAP bridge, server sync, inventory)
 │   ├─ InputManager (virtual sticks, aim-assist)
 │   ├─ AudioManager (buses: SFX/VO/Music)
 │   ├─ PoolManager (bullets, arrows, FX, enemies)
 │   ├─ AI/ (Director, Spawner, BehaviorLib, Perception, Utility AI)
 │   └─ NetClient (JWT auth, REST, WS/SSE)
 ├─ World/
 │   ├─ LevelLoader (streamed chunks, occlusion, portals)
 │   ├─ NavMesh + OffMeshLinks (vents, rafters, ziplines)
 │   ├─ SpawnPoints (patrol graphs)
 │   └─ SecretDoorways (procedural toggles by seed)
 ├─ Player/
 │   ├─ Controller
 │   ├─ Movement (C# kinematics; Sky Ascent, aerial glide)
 │   ├─ Combat (sword, knife, auto-bow; combo state machine)
 │   ├─ Powers (modular; cooldowns; synergy tags)
 │   └─ Inventory
 ├─ Enemies/
 │   ├─ BaseEnemy (Idle/Patrol/Search/Attack/Flee)
 │   ├─ Animal/Soldier/Elite controllers
 │   ├─ Bosses (weakness sensors)
 │   └─ Perception (LOS, audio, scent)
 ├─ UI/
 │   ├─ HUD (lives, SC, ammo, cooldowns)
 │   ├─ MapPreview (base map + ingress hints)
 │   ├─ Shop (IAP + SC store)
 │   ├─ Leaderboard (country filters, friends)
 │   └─ Shaman (advice ticker)
 └─ Tools/
     ├─ MissionImporter (reads missions_*.json)
     └─ BalanceOverlays (debug DPS/HP/TTK)
```

### Visual Quality & Performance
- LOD meshes, impostors for distant units
- Baked lightmaps + minimal dynamic lights; small mobile shadow cascades
- Texture compression ASTC/ETC2; atlases for UI
- Dynamic resolution (0.7–1.0), 60→45→30 fps fallback
- Occlusion/portal culling, frustum culling, visibility notifiers
- GPU particles with CPU fallbacks; simplified stylized shaders as a toggle

---

## 4) Game AI Architecture

### Layers
1. **Encounter Director**: orchestrates waves, elites, flanks, and ambush cones by reading player state and noise.
2. **Behavior Trees**: per class (Animal pack tactics; Soldier patrol/suppress/grenade; Elite aura control).
3. **Utility AI (C#)**: action scoring (cover vs rush vs throw) using TTK/crowd density/LOS.
4. **GOAP for Bosses**: pylon/chant/engine sub-goals and punish phases.
5. **Navigation**: NavMesh layers with off-mesh links (vents, rafters, ziplines).
6. **Perception**: FOV, audio falloff; animals include scent cones.

**Result:** Smart, varied enemies with readable telegraphs and fair counterplay.

---

## 5) Networking Model

- Core game is **offline single-player**; network used for **auth, economy, and leaderboards**.
- Client is **untrusted** for currency/scores; server recomputes and validates.

### API (FastAPI, sample)
- **Auth**
  - `POST /v1/auth/token` → issue JWT (guest or platform-bound)
- **Progress & Scores**
  - `POST /v1/progress/stage` → stage#, time, deaths; server grants SC
  - `GET /v1/leaderboard/global?country=SE&mode=fastest_stage` (paged)
  - `WS/SSE /v1/leaderboard/stream?country=XX`
- **Economy**
  - `GET /v1/economy/catalog`
  - `POST /v1/economy/purchase` (IAP receipt → verify with Apple/Google/Stripe → mint SC)
  - `POST /v1/economy/spend` (spend SC on items; server updates inventory)

### Anti-cheat
- Server-side reward calculation, time floor checks per stage, anomaly detection (z-scores), device attestation, data checksums, rate limits.

---

## 6) Data Model (PostgreSQL)

**users**: `id uuid pk`, `created_at`, `country_code`, `display_name`, `platform_ids jsonb`, `banned bool`  
**auth_tokens**: `user_id`, `jwt_id`, `expires_at`  
**progress**: `user_id`, `stage int`, `best_time_ms`, `deaths int`, `stars smallint`, `updated_at`  
**leaderboard_snapshot**: `id`, `mode enum`, `country_code`, `user_id`, `score_value`, `rank`, `snapshot_at`  
**wallet**: `user_id`, `sky_crowns bigint`, `lifetime_earned`, `lifetime_purchased`  
**inventory**: `user_id`, `item_id fk`, `qty`, `meta jsonb`  
**purchases_iap**: `id`, `user_id`, `provider enum`, `receipt_id`, `status`, `amount_cents`, `sc_granted`, `created_at`  
**catalog**: `id`, `name`, `type enum`, `tier`, `price_sc`, `meta jsonb`, `active`  
**receipts_audit**: hashed receipt, verification result, retry count

**Indexes:** `(country_code, score_value DESC)`, `(user_id, stage)`, `(status, created_at)`

---

## 7) Economy & Currency

- **Currency:** **Skycrowns (SC)**  
- **Acquisition**
  - Earned: Stage clears, boss bonuses, stealth/perfect runs, dailies/weekly bounties
  - Purchased: IAP packs that grant SC (cosmetic-first; no paywall to finish)
- **Earnings (suggested)**
  - Stage base: 50→250 SC (stage-scaled)
  - Boss first-kill: +400 SC
  - Perfect stealth: +200 SC
  - Daily: +500 SC, Weekly: +2,000 SC
- **Catalog (examples)**
  - **Sanctum Token** (1 extra life for next 3 stages): **2,500 SC**
  - **Refill Ammo**: **200 SC**
  - **Cooldown Charm** (-12% cooldowns): **1,800 SC**
  - **Repeater Arbalest (T2)**: **1,200 SC**
  - **Storm Chakram (T3)**: **2,200 SC**
  - **Runic Shield (T2)**: **900 SC**
  - **Grapnel Reel (T2)**: **800 SC**
  - **Oil Vials (T1, 3x)**: **300 SC**
  - **Sonic Arrows (T2, 5x)**: **700 SC**
  - **Frost Bombs (T3, 3x)**: **1,500 SC**
  - **Legend Kit (T4 bundle)**: **5,200 SC**
- **Synergy Boost**: Purchased item overlaps with newly unlocked rescue power → **+10% damage**, **-8% cooldowns** for that theme during current session.

---

## 8) Powers & Rescue Mapping

- **Per-stage unlocks** are defined in mission bundles (`missions_boy.json`, `missions_girl.json`) via `rewards.powerUnlocked`.
- Highlights: **Blink Step**, **Shadow Veil**, **Time Slip**, **Aerial Glide / Sky Ascent**, **Hawkeye Burst**, **Stoneguard**, **Spectral Decoy**, **Thunderbrand**, **Ember Dash**, **Frostlock**, **Chain Grapple**, **Viper Strike**, **Sanctum Ward**.

---

## 9) Web Leaderboard & Site

- **Frontend:** React + Vite, TailwindCSS
- **Features:** Country filters, friends list, search, live updates via SSE/WebSockets
- **SEO/CDN:** Static hosting behind CDN (Cloudflare)
- **Privacy:** Minimal PII (display name, country). Parental gates for U13 markets if applicable.

---

## 10) Build & Release

1. **Content Authoring:** Blender/Krita → import to Godot → LODs & lightmaps baked
2. **Testing:** AI decision unit tests; TTK/balance sims; device farm on low-end Android
3. **CI:** Export Android .aab & iOS Xcode project; sign Android; attach artifacts
4. **API Deploy:** Tests → migrations → rolling deploy (Fly.io/Hetzner/AWS)
5. **Rollout:** Staged percentage on Play; TestFlight on iOS
6. **Observability:** Godot logs → Loki; metrics → Prometheus; Grafana dashboards

---

## 11) Security & Compliance

- HTTPS-only; JWT short TTL with refresh; rotating keys
- Server-side receipt validation (Apple/Google/Stripe)
- Rate limits & anomaly detection on economy endpoints
- GDPR: data export/delete endpoints; data minimization

---

## 12) Repos & Structure (Monorepo example)

```
/client-godot/           # Godot project (scenes, scripts, assets, exporters)
/server-fastapi/         # FastAPI app (routers, models, services, alembic migrations)
/web-leaderboard/        # React+Vite site
/ops/                    # Dockerfiles, compose, k8s manifests, Caddy config
/tools/                  # Balancing exporters, JSON validators
/docs/                   # This architecture.md, GDD, API specs
```

---

## 13) Roadmap (Suggested)

- **M1**: Core loop (1–3 bases), AI Director v1, powers, shop stub, offline run
- **M2**: Leaderboards & economy server, receipt validation, anti-cheat v1
- **M3**: Content scale-out (25–50 stages), performance passes, live LB
- **M4**: Full 150 stages, polishing, accessibility, localization, launch prep

---

## 14) Ownership & Licensing

- Godot (MIT), FastAPI (MIT), React (MIT), Tailwind (MIT), Postgres/Redis (OSS)
- You own all produced code and assets; only third-party costs: Stripe fees & store cuts
- Avoid viral asset licenses; keep source art files in repo for provenance

---

## 15) Integration With Existing Files

- Import missions from: `missions_boy.json` and `missions_girl.json` via `MissionImporter` tool
- Use `design_balancing.xlsx` for tuning; exporter emits updated JSON/TSV for the client

---

*End of document.*
