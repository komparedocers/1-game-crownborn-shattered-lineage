import hashlib
import stripe
from google.oauth2 import service_account
from googleapiclient.discovery import build
from sqlalchemy.orm import Session
from datetime import datetime
import httpx

from models.database import Purchase, Wallet, ReceiptAudit, PaymentProvider, PurchaseStatus
from config.settings import settings

stripe.api_key = settings.STRIPE_SECRET_KEY

# IAP Package Definitions (SC = Skycrowns)
IAP_PACKAGES = {
    "small_pack": {"sc": 500, "usd_cents": 99},
    "medium_pack": {"sc": 1200, "usd_cents": 199},
    "large_pack": {"sc": 2800, "usd_cents": 499},
    "mega_pack": {"sc": 6000, "usd_cents": 999},
    "legendary_pack": {"sc": 15000, "usd_cents": 1999},
}

async def verify_google_play_receipt(receipt_data: str, package_name: str):
    """Verify Google Play Store receipt"""
    try:
        # This would use Google Play Developer API
        # For now, returning mock verification
        return {
            "valid": True,
            "product_id": "small_pack",
            "purchase_token": receipt_data[:50]
        }
    except Exception as e:
        return {"valid": False, "error": str(e)}

async def verify_apple_receipt(receipt_data: str, sandbox: bool = False):
    """Verify Apple App Store receipt"""
    try:
        url = "https://sandbox.itunes.apple.com/verifyReceipt" if sandbox else "https://buy.itunes.apple.com/verifyReceipt"

        async with httpx.AsyncClient() as client:
            response = await client.post(
                url,
                json={
                    "receipt-data": receipt_data,
                    "password": settings.APPLE_SHARED_SECRET
                }
            )
            result = response.json()

            if result.get("status") == 0:
                return {"valid": True, "receipt": result}
            else:
                return {"valid": False, "error": f"Status {result.get('status')}"}
    except Exception as e:
        return {"valid": False, "error": str(e)}

async def verify_stripe_payment(payment_intent_id: str):
    """Verify Stripe payment"""
    try:
        payment_intent = stripe.PaymentIntent.retrieve(payment_intent_id)

        if payment_intent.status == "succeeded":
            return {
                "valid": True,
                "amount_cents": payment_intent.amount,
                "payment_id": payment_intent.id
            }
        else:
            return {"valid": False, "error": "Payment not succeeded"}
    except Exception as e:
        return {"valid": False, "error": str(e)}

def calculate_receipt_hash(receipt_id: str) -> str:
    """Calculate hash for receipt deduplication"""
    return hashlib.sha256(receipt_id.encode()).hexdigest()

async def process_purchase(
    db: Session,
    user_id: str,
    provider: PaymentProvider,
    receipt_id: str,
    package_id: str = None,
    amount_cents: int = None
):
    """Process IAP purchase and grant currency"""

    # Check for duplicate receipt
    receipt_hash = calculate_receipt_hash(receipt_id)
    existing_audit = db.query(ReceiptAudit).filter(
        ReceiptAudit.receipt_hash == receipt_hash
    ).first()

    if existing_audit:
        return {"success": False, "error": "Receipt already processed"}

    # Verify receipt based on provider
    verification_result = None
    if provider == PaymentProvider.GOOGLE_PLAY:
        verification_result = await verify_google_play_receipt(receipt_id, package_id)
    elif provider == PaymentProvider.APPLE_IAP:
        verification_result = await verify_apple_receipt(receipt_id)
    elif provider == PaymentProvider.STRIPE:
        verification_result = await verify_stripe_payment(receipt_id)

    # Create audit record
    audit = ReceiptAudit(
        receipt_hash=receipt_hash,
        verification_result=verification_result,
        retry_count=0
    )
    db.add(audit)

    if not verification_result.get("valid"):
        db.commit()
        return {"success": False, "error": "Invalid receipt"}

    # Determine SC amount
    sc_amount = 0
    if package_id and package_id in IAP_PACKAGES:
        sc_amount = IAP_PACKAGES[package_id]["sc"]
        amount_cents = IAP_PACKAGES[package_id]["usd_cents"]
    elif amount_cents:
        # Calculate SC based on amount (100 cents = 100 SC)
        sc_amount = amount_cents

    # Create purchase record
    purchase = Purchase(
        user_id=user_id,
        provider=provider,
        receipt_id=receipt_id,
        status=PurchaseStatus.VERIFIED,
        amount_cents=amount_cents,
        sc_granted=sc_amount,
        verified_at=datetime.utcnow()
    )
    db.add(purchase)

    # Grant currency to wallet
    wallet = db.query(Wallet).filter(Wallet.user_id == user_id).first()
    if wallet:
        wallet.sky_crowns += sc_amount
        wallet.lifetime_purchased += sc_amount

    db.commit()

    return {
        "success": True,
        "sc_granted": sc_amount,
        "new_balance": wallet.sky_crowns if wallet else 0
    }

def spend_currency(db: Session, user_id: str, amount: int) -> bool:
    """Spend SC from wallet"""
    wallet = db.query(Wallet).filter(Wallet.user_id == user_id).first()

    if not wallet or wallet.sky_crowns < amount:
        return False

    wallet.sky_crowns -= amount
    db.commit()
    return True

def grant_currency(db: Session, user_id: str, amount: int, reason: str = "earned"):
    """Grant SC to wallet (from gameplay)"""
    wallet = db.query(Wallet).filter(Wallet.user_id == user_id).first()

    if wallet:
        wallet.sky_crowns += amount
        wallet.lifetime_earned += amount
        db.commit()
        return True
    return False
