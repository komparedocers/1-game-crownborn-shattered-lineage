# Crownborn Server Backend

FastAPI-based game server for Crownborn: Shattered Lineage

## Quick Start

### Using Docker Compose (Recommended)

```bash
docker-compose up -d
```

This starts:
- PostgreSQL database (port 5432)
- Redis cache (port 6379)
- FastAPI server (port 8000)

### Manual Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment
cp .env.example .env
# Edit .env with your configuration

# Run server
python main.py
```

## API Endpoints

### Health Check
```
GET /health
```

### Authentication
```
POST /v1/auth/register - Create new user
POST /v1/auth/token - Get JWT token
```

### Progress
```
POST /v1/progress/stage - Submit stage completion
GET /v1/progress/user/{user_id} - Get user progress
```

### Economy
```
GET /v1/economy/catalog - Get shop items
POST /v1/economy/purchase - Process IAP
POST /v1/economy/spend - Spend currency
GET /v1/economy/wallet/{user_id} - Get wallet balance
```

### Leaderboards
```
GET /v1/leaderboard/global - Global leaderboard
GET /v1/leaderboard/stage/{stage} - Stage-specific leaderboard
GET /v1/leaderboard/user/{user_id}/rank - User's rank
```

## Database Schema

- **users** - Player accounts
- **auth_tokens** - JWT authentication
- **progress** - Stage completion data
- **wallet** - Currency balances
- **catalog** - Shop items
- **inventory** - Player items
- **purchases_iap** - Purchase records
- **leaderboard_snapshot** - Leaderboard cache

## Configuration

Environment variables in `.env`:

```env
DATABASE_URL=postgresql://user:pass@host:5432/crownborn
REDIS_URL=redis://host:6379
SECRET_KEY=your-secret-key-here
STRIPE_SECRET_KEY=sk_test_...
GOOGLE_PLAY_SERVICE_ACCOUNT=path/to/service-account.json
APPLE_SHARED_SECRET=your-apple-secret
```

## Payment Integration

### Stripe
Set `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET`

### Google Play
Add service account JSON path to `GOOGLE_PLAY_SERVICE_ACCOUNT`

### Apple IAP
Set `APPLE_SHARED_SECRET` from App Store Connect

## Development

### Run in debug mode
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Run tests
```bash
pytest
```

## Production Deployment

1. Set `DEBUG=False` in production
2. Use strong `SECRET_KEY`
3. Enable HTTPS
4. Use managed database services
5. Configure rate limiting
6. Enable monitoring (Prometheus/Grafana)
