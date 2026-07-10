import os
from abc import ABC, abstractmethod

import jwt
from jwt import PyJWKClient


class AuthProvider(ABC):
    @abstractmethod
    async def verify_token(self, token: str) -> dict:
        # returns { sub, role, email }
        pass


class LocalAuthProvider(AuthProvider):
    async def verify_token(self, token: str) -> dict:
        secret = os.getenv("JWT_SECRET", "dev-secret-change-in-prod")
        return jwt.decode(token, secret, algorithms=["HS256"])


class CognitoAuthProvider(AuthProvider):
    def __init__(self):
        self._jwk_client: PyJWKClient | None = None

    def _jwks_url(self) -> str:
        region = os.getenv("COGNITO_REGION")
        pool_id = os.getenv("COGNITO_USER_POOL_ID")
        if not region or not pool_id:
            raise RuntimeError(
                "COGNITO_REGION and COGNITO_USER_POOL_ID must be set to use AUTH_PROVIDER=cognito"
            )
        return f"https://cognito-idp.{region}.amazonaws.com/{pool_id}" "/.well-known/jwks.json"

    async def verify_token(self, token: str) -> dict:
        if self._jwk_client is None:
            self._jwk_client = PyJWKClient(self._jwks_url())

        signing_key = self._jwk_client.get_signing_key_from_jwt(token)
        client_id = os.getenv("COGNITO_APP_CLIENT_ID")
        claims = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            audience=client_id,
        )
        return {
            "sub": claims["sub"],
            "role": claims.get("custom:role", "patient"),
            "email": claims.get("email"),
        }


def get_auth_provider() -> AuthProvider:
    p = os.getenv("AUTH_PROVIDER", "local")
    if p == "cognito":
        return CognitoAuthProvider()
    return LocalAuthProvider()
