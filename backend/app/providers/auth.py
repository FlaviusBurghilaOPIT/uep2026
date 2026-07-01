import os
from abc import ABC, abstractmethod

class AuthProvider(ABC):
    @abstractmethod
    async def verify_token(self, token: str) -> dict:
        # returns { sub, role, email }
        pass

class LocalAuthProvider(AuthProvider):
    async def verify_token(self, token: str) -> dict:
        # verifies a local JWT token — used in development
        import jwt
        secret = os.getenv("JWT_SECRET", "dev-secret-change-in-prod")
        return jwt.decode(token, secret, algorithms=["HS256"])

class CognitoAuthProvider(AuthProvider):
    async def verify_token(self, token: str) -> dict:
        # verifies an AWS Cognito token — used in production
        # built in Phase 3
        pass

def get_auth_provider() -> AuthProvider:
    p = os.getenv("AUTH_PROVIDER", "local")
    if p == "cognito": return CognitoAuthProvider()
    return LocalAuthProvider()