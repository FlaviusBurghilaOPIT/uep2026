from datetime import datetime
from pydantic import BaseModel


class UserBase(BaseModel):
    email: str
    full_name: str
    role: str


class UserCreate(UserBase):
    password: str


class UserResponse(UserBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True
