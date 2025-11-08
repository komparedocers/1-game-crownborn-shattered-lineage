# Crownborn: Shattered Lineage

**A cross-platform action-adventure game with 150 stages of family rescue missions**

## Game Overview

Crownborn: Shattered Lineage is a complete 3rd-person action-adventure game where players rescue their kidnapped family members while uncovering their royal lineage. The game features:

- **150 Mission Campaign** (Boy & Girl variants)
- **Cross-Platform Support** (Android, iOS)
- **Online Leaderboards** (Global & Country-wise)
- **In-App Purchases** (Google Play, Apple Pay, Stripe)
- **Progressive Power System** (13+ unique abilities)
- **Advanced AI** (Animals, Soldiers, Elite enemies)
- **Boss Battles** with exploitable weaknesses
- **Shaman Guidance System** (summoned via magic ring)
- **Currency System** (Skycrowns - SC)

## Project Structure

```
.
├── android-game/           # Android game build
│   ├── godot-project/      # Godot 4.x game engine
│   │   ├── scripts/        # GDScript game logic
│   │   ├── scenes/         # Game scenes (create in Godot Editor)
│   │   ├── data/           # Mission JSON data
│   │   └── project.godot   # Godot project config
│   └── export_presets.cfg  # Android export settings
│
├── iphone-game/            # iOS game build
│   ├── godot-project/      # Same as Android
│   └── export_presets.cfg  # iOS export settings
│
├── server/                 # Game server backend
│   ├── api/                # FastAPI REST endpoints
│   ├── models/             # Database models
│   ├── services/           # Business logic
│   ├── config/             # Configuration
│   ├── web-gui/            # React leaderboard website
│   ├── main.py             # FastAPI application
│   ├── requirements.txt    # Python dependencies
│   ├── Dockerfile          # Docker container
│   └── docker-compose.yml  # Multi-service setup
│
└── plan-files/             # Game design documents
    ├── missions_boy.json   # 150 missions for boy character
    ├── missions_girl.json  # 150 missions for girl character
    ├── story.md            # Complete story bible
    ├── architecture.md     # Technical architecture
    └── GDD_Throne_of_Ashes.md  # Game Design Document
```

## Tech Stack

### Game Client (Godot 4.x)
- **Engine**: Godot 4.2+ (MIT License)
- **Languages**: GDScript (gameplay), C# (performance-critical)
- **Graphics**: Vulkan/GLES3
- **Platforms**: Android (API 21+), iOS (11+)

### Backend Server
- **API**: FastAPI (Python)
- **Database**: PostgreSQL
- **Cache**: Redis
- **Auth**: JWT tokens
- **Payments**: Stripe, Google Play Billing, Apple IAP

### Web Leaderboard
- **Framework**: React + Vite
- **Styling**: TailwindCSS
- **API Client**: Axios

## Getting Started

### Prerequisites

- **Godot 4.2+** - Download from [godotengine.org](https://godotengine.org/)
- **Python 3.11+** - For server backend
- **Node.js 18+** - For web GUI
- **Docker & Docker Compose** - For deployment
- **PostgreSQL 15+** - Database
- **Redis 7+** - Caching

### 1. Server Setup

#### Using Docker (Recommended)

```bash
cd server
cp .env.example .env
# Edit .env with your configurations

docker-compose up -d
```

The server will be available at http://localhost:8000

#### Manual Setup

```bash
cd server

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export DATABASE_URL="postgresql://user:pass@localhost:5432/crownborn"
export REDIS_URL="redis://localhost:6379"
export SECRET_KEY="your-secret-key"

# Run server
python main.py
```

#### Database Initialization

The database tables are created automatically on first run. To manually initialize:

```python
from models.database import init_db
init_db()
```

### 2. Web GUI Setup

```bash
cd server/web-gui

# Install dependencies
npm install

# Development server
npm run dev

# Production build
npm run build
```

Access at http://localhost:3000

### 3. Game Client Setup

#### Open in Godot

1. Download and install Godot 4.2+
2. Open Godot
3. Import project: `android-game/godot-project/project.godot`
4. The project will load with all scripts and configurations

#### Configure Server Connection

Edit `scripts/NetClient.gd` and set your server URL:

```gdscript
const API_BASE = "https://your-server-url.com"
```

#### Building for Android

1. Open the project in Godot
2. Go to **Project > Export**
3. Select **Android** preset
4. Configure:
   - **Package Name**: com.crownborn.shatteredlineage
   - **Min SDK**: 21
   - **Target SDK**: 33
5. Click **Export Project** to generate AAB/APK

**Requirements**:
- Android SDK
- Android build tools
- Keystore for signing (production)

#### Building for iOS

1. Open the project in Godot
2. Go to **Project > Export**
3. Select **iOS** preset
4. Configure:
   - **Bundle ID**: com.crownborn.shatteredlineage
   - **Team ID**: Your Apple Developer Team ID
   - **Provisioning Profile**: Add your profile
5. Click **Export Project** to generate Xcode project
6. Open in Xcode and build

**Requirements**:
- macOS with Xcode
- Apple Developer Account
- Valid provisioning profile

## Game Features

### Core Gameplay

1. **Combat System**
   - Sword (parry/riposte)
   - Knife (stealth kills)
   - Auto-Bow (multi-burst arrows)

2. **Power System** (Unlocked through rescues)
   - Blink Step - Short-range teleport
   - Shadow Veil - Invisibility
   - Time Slip - Slow motion
   - Aerial Glide - Slow fall
   - Sky Ascent - Double jump
   - Stoneguard - Damage reduction
   - Hawkeye Burst - Enhanced bow
   - Thunderbrand - Lightning attacks
   - Ember Dash - Fire dash
   - Frostlock - Freeze enemies
   - Chain Grapple - Grappling hook
   - Viper Strike - Poison attacks
   - Sanctum Ward - Shield

3. **Enemy Types**
   - Animals (Wolf, Bear, Eagle)
   - Soldiers (Guards, Archers)
   - Elites (Captains, Champions)

4. **Boss System**
   - Each boss has unique weakness
   - Multi-phase battles
   - Discoverable through Shaman hints

### Progression System

- **Lives**: 3 per run (4th death resets to Stage 1)
- **Currency**: Skycrowns (SC) earned through gameplay
- **Stages**: 150 unique missions
- **Powers**: Unlock 1 per stage completion
- **Family Rescue**: One relative rescued per stage

### Shop & Economy

Purchase with SC:
- Weapons (1200-2200 SC)
- Gear & Armor (800-1800 SC)
- Ammunition (300-1500 SC)
- Consumables (200-2500 SC)
- Bundles (5200 SC)

### Payment Integration

#### Google Play (Android)

1. Set up Google Play Console
2. Create in-app products
3. Configure in `PaymentManager.gd`

#### Apple IAP (iOS)

1. Set up App Store Connect
2. Create in-app purchase products
3. Configure StoreKit

#### Stripe (Web)

1. Get Stripe API keys
2. Set in server `.env`:
   ```
   STRIPE_SECRET_KEY=sk_test_...
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```

### Packages Available

| Package | SC Granted | Price |
|---------|-----------|-------|
| Small Pack | 500 SC | $0.99 |
| Medium Pack | 1,200 SC | $1.99 |
| Large Pack | 2,800 SC | $4.99 |
| Mega Pack | 6,000 SC | $9.99 |
| Legendary Pack | 15,000 SC | $19.99 |

## API Documentation

### Authentication

#### Register User
```http
POST /v1/auth/register
Content-Type: application/json

{
  "display_name": "PlayerName",
  "gender": "boy",  // or "girl"
  "country_code": "US"
}

Response:
{
  "access_token": "jwt_token",
  "user_id": "uuid",
  "display_name": "PlayerName"
}
```

### Progress

#### Submit Stage Completion
```http
POST /v1/progress/stage
Authorization: Bearer {token}
Content-Type: application/json

{
  "stage": 1,
  "time_ms": 120000,
  "deaths": 1,
  "stars": 3,
  "completed": true
}

Response:
{
  "success": true,
  "sc_earned": 150,
  "new_balance": 650,
  "is_best_time": true
}
```

### Economy

#### Get Shop Catalog
```http
GET /v1/economy/catalog

Response:
[
  {
    "item_id": "repeater_arbalest_t2",
    "name": "Repeater Arbalest",
    "price_sc": 1200,
    "type": "weapon",
    "tier": 2
  }
]
```

#### Purchase Item
```http
POST /v1/economy/spend
Authorization: Bearer {token}

{
  "item_id": "repeater_arbalest_t2",
  "quantity": 1
}
```

#### Process IAP
```http
POST /v1/economy/purchase

{
  "provider": "google_play",
  "receipt_id": "purchase_token",
  "package_id": "small_pack"
}
```

### Leaderboards

#### Get Global Leaderboard
```http
GET /v1/leaderboard/global?mode=fastest_total&country=US

Response:
{
  "mode": "fastest_total",
  "country_code": "US",
  "entries": [
    {
      "rank": 1,
      "display_name": "TopPlayer",
      "country_code": "US",
      "score": 45000
    }
  ]
}
```

## Development

### Adding New Missions

Edit `plan-files/missions_boy.json` or `missions_girl.json`:

```json
{
  "id": 151,
  "variant": "boy",
  "location": "New Location",
  "relative": {
    "name": "Uncle Marcus",
    "category": "men"
  },
  "enemies": ["Soldier", "Wolf"],
  "boss": {
    "name": "Captain Drex",
    "weakness": "fire"
  },
  "mission": {
    "hook": "Mission description",
    "mapFeatures": "vents, rafters",
    "stealthTip": "Use the shadows"
  },
  "rewards": {
    "powerUnlocked": "New Power"
  },
  "guidance": {
    "shamanWisdom": "Wise words from the Shaman"
  }
}
```

### Adding New Powers

In `Player.gd`, add to `use_power()`:

```gdscript
"New Power":
    new_power_function()

func new_power_function():
    # Implement power logic
    pass
```

### Adding Shop Items

In `server/services/catalog_init.py`:

```python
{
    "item_id": "new_item",
    "name": "New Item",
    "description": "Description",
    "type": ItemType.WEAPON,
    "tier": 2,
    "price_sc": 1500,
    "meta": {"damage_bonus": 20}
}
```

## Deployment

### Server Deployment

#### Using Docker

```bash
cd server
docker build -t crownborn-server .
docker run -p 8000:8000 \
  -e DATABASE_URL="postgresql://..." \
  -e REDIS_URL="redis://..." \
  crownborn-server
```

#### Production Considerations

1. **Database**: Use managed PostgreSQL (AWS RDS, Google Cloud SQL)
2. **Redis**: Use managed Redis (AWS ElastiCache, Redis Cloud)
3. **Server**: Deploy on cloud (AWS, GCP, Fly.io, Heroku)
4. **CDN**: Use Cloudflare for web GUI
5. **SSL**: Configure HTTPS with valid certificates
6. **Environment Variables**: Use secrets manager

### Mobile App Release

#### Android (Google Play)

1. Build signed AAB
2. Create app listing in Play Console
3. Upload AAB
4. Configure in-app products
5. Submit for review

#### iOS (App Store)

1. Build in Xcode
2. Archive and upload to App Store Connect
3. Create app listing
4. Configure in-app purchases
5. Submit for review

## Security

- JWT tokens with short TTL (60 minutes)
- Server-side receipt validation for all purchases
- Anti-cheat: Server validates all scores and progress
- Rate limiting on API endpoints
- HTTPS only in production
- No client-side currency manipulation

## License

This is your proprietary game. All code and assets are owned by you.

### Third-Party Licenses

- Godot Engine: MIT License
- FastAPI: MIT License
- React: MIT License
- PostgreSQL: PostgreSQL License
- Redis: BSD License

## Support & Community

- **Bug Reports**: GitHub Issues
- **Documentation**: See `plan-files/` for complete design docs
- **Story**: See `plan-files/story.md`
- **Architecture**: See `plan-files/architecture.md`

## Credits

**Game Design**: Based on comprehensive GDD
**Story**: Throne of Ashes narrative
**Campaign**: 150-stage mission design (Boy/Girl variants)

---

**Rescue your kin. Reclaim your throne. One stage at a time.**
