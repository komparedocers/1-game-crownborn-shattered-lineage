from sqlalchemy import create_engine, Column, Integer, String, BigInteger, Boolean, DateTime, Text, JSON, Enum, ForeignKey, Index
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
import uuid
from datetime import datetime
import enum

from config.settings import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class PaymentProvider(enum.Enum):
    GOOGLE_PLAY = "google_play"
    APPLE_IAP = "apple_iap"
    STRIPE = "stripe"

class PurchaseStatus(enum.Enum):
    PENDING = "pending"
    VERIFIED = "verified"
    FAILED = "failed"
    REFUNDED = "refunded"

class ItemType(enum.Enum):
    WEAPON = "weapon"
    GEAR = "gear"
    AMMO = "ammo"
    TRAVERSAL = "traversal"
    CONSUMABLE = "consumable"
    BUNDLE = "bundle"

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    country_code = Column(String(2), index=True)
    display_name = Column(String(50), nullable=False)
    gender = Column(String(10))  # boy/girl
    platform_ids = Column(JSONB, default={})
    banned = Column(Boolean, default=False)

    # Relationships
    progress = relationship("Progress", back_populates="user")
    wallet = relationship("Wallet", back_populates="user", uselist=False)
    inventory = relationship("Inventory", back_populates="user")
    purchases = relationship("Purchase", back_populates="user")

class AuthToken(Base):
    __tablename__ = "auth_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    jwt_id = Column(String(255), unique=True, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class Progress(Base):
    __tablename__ = "progress"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    stage = Column(Integer, nullable=False)
    best_time_ms = Column(BigInteger)
    deaths = Column(Integer, default=0)
    stars = Column(Integer, default=0)
    completed = Column(Boolean, default=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="progress")

    __table_args__ = (
        Index('idx_user_stage', 'user_id', 'stage', unique=True),
    )

class LeaderboardSnapshot(Base):
    __tablename__ = "leaderboard_snapshot"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    mode = Column(String(50), nullable=False)  # fastest_stage, total_score, etc.
    country_code = Column(String(2), index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    score_value = Column(BigInteger, nullable=False)
    rank = Column(Integer)
    snapshot_at = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        Index('idx_country_score', 'country_code', 'score_value'),
    )

class Wallet(Base):
    __tablename__ = "wallet"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), unique=True, nullable=False)
    sky_crowns = Column(BigInteger, default=0)
    lifetime_earned = Column(BigInteger, default=0)
    lifetime_purchased = Column(BigInteger, default=0)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="wallet")

class Catalog(Base):
    __tablename__ = "catalog"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    item_id = Column(String(100), unique=True, nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    type = Column(Enum(ItemType), nullable=False)
    tier = Column(Integer, default=1)
    price_sc = Column(Integer, nullable=False)
    meta = Column(JSONB, default={})
    active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class Inventory(Base):
    __tablename__ = "inventory"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    item_id = Column(String(100), nullable=False)
    quantity = Column(Integer, default=1)
    meta = Column(JSONB, default={})
    acquired_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="inventory")

    __table_args__ = (
        Index('idx_user_item', 'user_id', 'item_id'),
    )

class Purchase(Base):
    __tablename__ = "purchases_iap"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    provider = Column(Enum(PaymentProvider), nullable=False)
    receipt_id = Column(String(500), unique=True, nullable=False)
    status = Column(Enum(PurchaseStatus), default=PurchaseStatus.PENDING)
    amount_cents = Column(Integer)
    sc_granted = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    verified_at = Column(DateTime)

    user = relationship("User", back_populates="purchases")

class ReceiptAudit(Base):
    __tablename__ = "receipts_audit"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    receipt_hash = Column(String(255), unique=True, nullable=False)
    verification_result = Column(JSONB)
    retry_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    Base.metadata.create_all(bind=engine)
