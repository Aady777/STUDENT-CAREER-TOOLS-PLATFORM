"""
Authentication routes – register, login, me, change-password, refresh.

Rate limiting applied:
  - POST /auth/register  → 3 requests / 60 s per IP
  - POST /auth/login     → 5 requests / 60 s per IP
"""

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.core.security import (
    hash_password, verify_password,
    create_access_token, create_refresh_token, decode_token,
)
from app.core.rate_limiter import RateLimiter
from app.core.config import get_settings
from app.models.user import User

settings = get_settings()
router = APIRouter(prefix="/auth", tags=["Authentication"])

# ── Rate limiter instances ────────────────────────────
_register_limiter = RateLimiter(
    max_requests=settings.RATE_LIMIT_REGISTER_MAX,
    window_seconds=settings.RATE_LIMIT_REGISTER_WINDOW,
)
_login_limiter = RateLimiter(
    max_requests=settings.RATE_LIMIT_LOGIN_MAX,
    window_seconds=settings.RATE_LIMIT_LOGIN_WINDOW,
)


# ── Schemas (auth-specific, kept local) ──────────────────
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: int
    email: str
    created_at: str | None = None

    model_config = {"from_attributes": True}


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=6, max_length=128)


class RefreshRequest(BaseModel):
    refresh_token: str


# ── Routes ───────────────────────────────────────────────
@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(_register_limiter)],
)
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    """
    Create a new user account.
    Rate-limited to 3 registrations per 60 s per IP.
    """
    existing = db.query(User).filter(User.email == body.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(email=body.email, password=hash_password(body.password))
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post(
    "/login",
    response_model=TokenResponse,
    dependencies=[Depends(_login_limiter)],
)
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    Authenticate and return JWT access + refresh tokens.
    Rate-limited to 5 login attempts per 60 s per IP.
    """
    user = db.query(User).filter(User.email == form.username).first()
    if not user or not verify_password(form.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    token_data = {"sub": str(user.id)}
    return {
        "access_token": create_access_token(data=token_data),
        "refresh_token": create_refresh_token(data=token_data),
        "token_type": "bearer",
    }


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get current user profile",
)
def me(user: User = Depends(get_current_user)):
    """Return the currently authenticated user's profile."""
    return user


@router.post(
    "/change-password",
    status_code=status.HTTP_200_OK,
    summary="Change password for current user",
)
def change_password(
    body: ChangePasswordRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """
    Change the authenticated user's password.
    Requires the current password for verification.
    """
    if not verify_password(body.current_password, user.password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect",
        )

    if body.current_password == body.new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New password must be different from current password",
        )

    user.password = hash_password(body.new_password)
    db.commit()
    return {"message": "Password changed successfully"}


@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Refresh access token using a valid refresh token",
)
def refresh(body: RefreshRequest, db: Session = Depends(get_db)):
    """
    Exchange a valid refresh token for a new access + refresh token pair.
    The old refresh token is implicitly invalidated (short-lived by design).
    """
    payload = decode_token(body.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token payload",
        )

    # Verify user still exists
    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User no longer exists",
        )

    token_data = {"sub": str(user.id)}
    return {
        "access_token": create_access_token(data=token_data),
        "refresh_token": create_refresh_token(data=token_data),
        "token_type": "bearer",
    }
