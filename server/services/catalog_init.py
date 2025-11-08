from sqlalchemy.orm import Session
from models.database import Catalog, ItemType

def initialize_catalog(db: Session):
    """Initialize shop catalog with default items"""

    # Check if catalog already initialized
    existing = db.query(Catalog).first()
    if existing:
        return

    items = [
        # Weapons
        {
            "item_id": "repeater_arbalest_t2",
            "name": "Repeater Arbalest",
            "description": "Rapid-fire crossbow with increased damage",
            "type": ItemType.WEAPON,
            "tier": 2,
            "price_sc": 1200,
            "meta": {"damage_bonus": 15, "fire_rate": 1.5}
        },
        {
            "item_id": "storm_chakram_t3",
            "name": "Storm Chakram",
            "description": "Lightning-imbued throwing weapon",
            "type": ItemType.WEAPON,
            "tier": 3,
            "price_sc": 2200,
            "meta": {"damage_bonus": 25, "element": "lightning"}
        },
        {
            "item_id": "viper_blade_t2",
            "name": "Viper Blade",
            "description": "Poisoned sword for silent kills",
            "type": ItemType.WEAPON,
            "tier": 2,
            "price_sc": 1500,
            "meta": {"damage_bonus": 18, "poison": True}
        },

        # Gear
        {
            "item_id": "runic_shield_t2",
            "name": "Runic Shield",
            "description": "Magical shield that absorbs damage",
            "type": ItemType.GEAR,
            "tier": 2,
            "price_sc": 900,
            "meta": {"defense_bonus": 20}
        },
        {
            "item_id": "shadow_cloak_t3",
            "name": "Shadow Cloak",
            "description": "Enhances stealth capabilities",
            "type": ItemType.GEAR,
            "tier": 3,
            "price_sc": 1800,
            "meta": {"stealth_bonus": 30}
        },
        {
            "item_id": "grapnel_reel_t2",
            "name": "Grapnel Reel",
            "description": "Advanced grappling hook",
            "type": ItemType.TRAVERSAL,
            "tier": 2,
            "price_sc": 800,
            "meta": {"range_bonus": 50}
        },

        # Ammo
        {
            "item_id": "oil_vials_t1",
            "name": "Oil Vials (3x)",
            "description": "Create fire traps",
            "type": ItemType.AMMO,
            "tier": 1,
            "price_sc": 300,
            "meta": {"quantity": 3, "effect": "fire"}
        },
        {
            "item_id": "sonic_arrows_t2",
            "name": "Sonic Arrows (5x)",
            "description": "Stun enemies with sonic blast",
            "type": ItemType.AMMO,
            "tier": 2,
            "price_sc": 700,
            "meta": {"quantity": 5, "effect": "stun"}
        },
        {
            "item_id": "frost_bombs_t3",
            "name": "Frost Bombs (3x)",
            "description": "Freeze enemies in place",
            "type": ItemType.AMMO,
            "tier": 3,
            "price_sc": 1500,
            "meta": {"quantity": 3, "effect": "freeze"}
        },

        # Consumables
        {
            "item_id": "sanctum_token",
            "name": "Sanctum Token",
            "description": "Extra life for next 3 stages",
            "type": ItemType.CONSUMABLE,
            "tier": 3,
            "price_sc": 2500,
            "meta": {"extra_lives": 1, "duration_stages": 3}
        },
        {
            "item_id": "ammo_refill",
            "name": "Ammo Refill",
            "description": "Restore all ammunition",
            "type": ItemType.CONSUMABLE,
            "tier": 1,
            "price_sc": 200,
            "meta": {"restores": "ammo"}
        },
        {
            "item_id": "cooldown_charm",
            "name": "Cooldown Charm",
            "description": "Reduce all cooldowns by 12%",
            "type": ItemType.CONSUMABLE,
            "tier": 2,
            "price_sc": 1800,
            "meta": {"cooldown_reduction": 12}
        },

        # Bundles
        {
            "item_id": "legend_kit_t4",
            "name": "Legend Kit",
            "description": "Premium bundle with best weapons and gear",
            "type": ItemType.BUNDLE,
            "tier": 4,
            "price_sc": 5200,
            "meta": {
                "includes": [
                    "storm_chakram_t3",
                    "shadow_cloak_t3",
                    "frost_bombs_t3",
                    "sanctum_token"
                ]
            }
        },
    ]

    for item_data in items:
        item = Catalog(**item_data)
        db.add(item)

    db.commit()
    print(f"Initialized catalog with {len(items)} items")
