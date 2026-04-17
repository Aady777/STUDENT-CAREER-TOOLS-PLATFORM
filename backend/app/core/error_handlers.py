"""
Global error handlers – registered in app/main.py.

Provides a consistent JSON envelope for all error responses:

    {
        "error":   "Validation Error",
        "detail":  [...],          # or a string
        "status":  422
    }

Handlers:
  - RequestValidationError  → 422 with field-level error details
  - HTTPException           → standard HTTP errors with structured body
  - Exception               → catch-all 500 with sanitised message
"""

import logging
import traceback

from fastapi import HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)


async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    """
    Handle Pydantic / FastAPI validation errors (422).

    Returns structured field-level error details so clients know
    exactly which field failed validation and why.
    """
    errors = []
    for error in exc.errors():
        field = " → ".join(str(loc) for loc in error["loc"])
        errors.append({"field": field, "message": error["msg"], "type": error["type"]})

    logger.warning(
        "Validation error | %s %s | %d field(s) invalid",
        request.method, request.url.path, len(errors),
    )

    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "Validation Error",
            "detail": errors,
            "status": status.HTTP_422_UNPROCESSABLE_ENTITY,
        },
    )


async def http_exception_handler(
    request: Request, exc: HTTPException
) -> JSONResponse:
    """
    Handle all HTTPExceptions with a consistent JSON envelope.

    Replaces FastAPI's default plain-string detail response.
    """
    logger.info(
        "HTTP %d | %s %s | %s",
        exc.status_code, request.method, request.url.path, exc.detail,
    )

    response = JSONResponse(
        status_code=exc.status_code,
        content={
            "error": _status_label(exc.status_code),
            "detail": exc.detail,
            "status": exc.status_code,
        },
    )

    # Preserve any extra headers set by the handler (e.g. Retry-After, WWW-Authenticate)
    if exc.headers:
        for key, value in exc.headers.items():
            response.headers[key] = value

    return response


async def unhandled_exception_handler(
    request: Request, exc: Exception
) -> JSONResponse:
    """
    Catch-all handler for any unhandled exception → 500 Internal Server Error.

    Logs the full traceback server-side but returns a sanitised message
    to the client (never leak stack traces in production).
    """
    logger.error(
        "Unhandled exception | %s %s\n%s",
        request.method, request.url.path, traceback.format_exc(),
    )

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Internal Server Error",
            "detail": "An unexpected error occurred. Please try again later.",
            "status": status.HTTP_500_INTERNAL_SERVER_ERROR,
        },
    )


# ── Helper ────────────────────────────────────────────────
def _status_label(code: int) -> str:
    """Return a human-readable label for common HTTP status codes."""
    labels = {
        400: "Bad Request",
        401: "Unauthorized",
        403: "Forbidden",
        404: "Not Found",
        405: "Method Not Allowed",
        408: "Request Timeout",
        409: "Conflict",
        422: "Unprocessable Entity",
        429: "Too Many Requests",
        500: "Internal Server Error",
        502: "Bad Gateway",
        503: "Service Unavailable",
    }
    return labels.get(code, f"HTTP {code}")
