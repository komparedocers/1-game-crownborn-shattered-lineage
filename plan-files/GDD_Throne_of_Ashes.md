# Throne of Ashes — Campaign GDD (Condensed)

**Version:** 2025-11-08T18:17:41Z  
**Campaigns:** 150-stage Boy variant, 150-stage Girl variant  
**Core Hook:** Rescue kin; gain powers; reveal blood-right to the throne; overthrow Warlord Bollock.

## 1. Player Setup
- **Protagonist:** Normal child of the realm (Boy/Girl). True lineage revealed at **Stage 2**.
- **Lives:** 3 per run; death #4 resets to **Stage 1**.
- **Default Kit:** Sword (parry/riposte), Knife (silent), **Auto-Bow** (multi-burst).

## 2. Family Rescue Distribution
- **Boy chosen:** More **women** relatives (70), then men (50), children (30).
- **Girl chosen:** More **children** (80), then men (40), women (30).
- **One rescue per stage; the rescued kin reveals the **next location**.

## 3. Progression & Power System
- **One power per rescue**, compounding traversal/CC/assassination (Blink Step, Shadow Veil, Time Slip, Aerial Glide, Chain Grapple, Sanctum Ward, etc.).
- **Purchased gear** (shop) has higher base strength; **synergy boost** when thematically overlapping with newly rescued power (+10% dmg, -8% cooldowns for that session).

## 4. Economy
- **Currency rewards** scale by stage; soft-capped to prevent inflation creep.
- **Shop** sells weapons, gear, ammo, traversal, lives, and bundles. See **ShopItems** sheet.
- **Loot:** Weighted drops from enemies/chests; see **LootTable** sheet.

## 5. Enemy Ecosystem
- Mixed packs (animals + soldiers + elites). Patrols can **ambush 360°**.
- **Bases**: Multiple ingress points, **secret doorways**, and stealth tools (vents, sewers, rafters, ivy, chimneys). Map preview at start of each mission.

## 6. Boss Design
- Every stage ends with a **Boss** with a **hidden weakness** (documented in CSV/Bosses sheet).
- **Boss HP** scales ~4.0× base enemies with a slight stage multiplier.
- Target Time-to-Kill (TTK) with Expected DPS: **25–80s** depending on stage.

## 7. Balancing Targets (Initial)
- See charts:
  - Enemy HP curve: `chart_enemy_hp.png`
  - Player DPS expectation: `chart_player_dps.png`
  - Currency reward curve: `chart_currency.png`
- See workbook `design_balancing.xlsx` → **Progression_Stages** (full per-stage proposal).

## 8. Shaman Guidance
- One line of tactical wisdom per stage; supports stealth learning and narrative rhythm.

## 9. Failure & Reset Loop
- Lives do not stack across runs (except temporary **Sanctum Token** effects).
- On fourth death: **full reset** to Stage 1; keep **hard unlocks** (cosmetics, lore, achievements).

## 10. Content Files
- Campaign CSVs: `campaign_150_stages_boy.csv`, `campaign_150_stages_girl.csv`
- Balancing workbook: `design_balancing.xlsx`
- Charts: `chart_enemy_hp.png`, `chart_player_dps.png`, `chart_currency.png`

---

### Notes for Implementation
- Gate *Legend Kit* to mid-game to avoid early trivialization.
- Boss quick-kill windows should always be **skill-read** (audio/FX tells) not arbitrary.
- Secret doorways must land behind **alarm nodes** to reward stealth routes.
- Mid-city **enemy camps** spawn with a short telegraph; stealth players can skirt by using rooftops/sewers.
