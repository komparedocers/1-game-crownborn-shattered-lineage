from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional

from models.database import get_db, User, Wallet, Catalog, Inventory, ItemType, PaymentProvider
from services.payment_service import process_purchase, spend_currency, IAP_PACKAGES

router = APIRouter(prefix="/v1/economy", tags=["economy"])

class CatalogItemResponse(BaseModel):
    item_id: str
    name: str
    description: Optional[str]
    type: str
    tier: int
    price_sc: int
    meta: dict

class PurchaseRequest(BaseModel):
    provider: str  # "google_play", "apple_iap", "stripe"
    receipt_id: str
    package_id: Optional[str] = None

class SpendRequest(BaseModel):
    item_id: str
    quantity: int = 1

class WalletResponse(BaseModel):
    sky_crowns: int
    lifetime_earned: int
    lifetime_purchased: int

@router.get("/catalog", response_model=List[CatalogItemResponse])
async def get_catalog(db: Session = Depends(get_db)):
    """Get shop catalog"""
    items = db.query(Catalog).filter(Catalog.active == True).all()

    return [
        CatalogItemResponse(
            item_id=item.item_id,
            name=item.name,
            description=item.description,
            type=item.type.value,
            tier=item.tier,
            price_sc=item.price_sc,
            meta=item.meta or {}
        )
        for item in items
    ]

@router.get("/iap-packages")
async def get_iap_packages():
    """Get IAP currency packages"""
    return {"packages": IAP_PACKAGES}

@router.post("/purchase")
async def purchase_currency(
    request: PurchaseRequest,
    user_id: str = "mock-user-id",  # Would come from JWT
    db: Session = Depends(get_db)
):
    """Process IAP purchase"""
    # Map provider string to enum
    provider_map = {
        "google_play": PaymentProvider.GOOGLE_PLAY,
        "apple_iap": PaymentProvider.APPLE_IAP,
        "stripe": PaymentProvider.STRIPE
    }

    provider = provider_map.get(request.provider)
    if not provider:
        raise HTTPException(status_code=400, detail="Invalid provider")

    # Get or create user
    user = db.query(User).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    result = await process_purchase(
        db=db,
        user_id=str(user.id),
        provider=provider,
        receipt_id=request.receipt_id,
        package_id=request.package_id
    )

    if not result["success"]:
        raise HTTPException(status_code=400, detail=result.get("error"))

    return result

@router.post("/spend")
async def spend_item(
    request: SpendRequest,
    user_id: str = "mock-user-id",  # Would come from JWT
    db: Session = Depends(get_db)
):
    """Spend SC to buy item"""
    user = db.query(User).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Get item from catalog
    item = db.query(Catalog).filter(Catalog.item_id == request.item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    total_cost = item.price_sc * request.quantity

    # Spend currency
    success = spend_currency(db, str(user.id), total_cost)
    if not success:
        raise HTTPException(status_code=400, detail="Insufficient funds")

    # Add to inventory
    inventory = db.query(Inventory).filter(
        Inventory.user_id == user.id,
        Inventory.item_id == request.item_id
    ).first()

    if inventory:
        inventory.quantity += request.quantity
    else:
        inventory = Inventory(
            user_id=user.id,
            item_id=request.item_id,
            quantity=request.quantity
        )
        db.add(inventory)

    db.commit()

    return {"success": True, "item_id": request.item_id, "quantity": request.quantity}

@router.get("/wallet/{user_id}", response_model=WalletResponse)
async def get_wallet(user_id: str, db: Session = Depends(get_db)):
    """Get user wallet"""
    wallet = db.query(Wallet).filter(Wallet.user_id == user_id).first()

    if not wallet:
        raise HTTPException(status_code=404, detail="Wallet not found")

    return WalletResponse(
        sky_crowns=wallet.sky_crowns,
        lifetime_earned=wallet.lifetime_earned,
        lifetime_purchased=wallet.lifetime_purchased
    )
