import os
from abc import ABC, abstractmethod


class FDAProvider(ABC):
    source: str

    @abstractmethod
    async def get_drug_info(self, drug_name: str) -> dict:
        pass


class LiveFDAProvider(FDAProvider):
    source = "live"

    async def get_drug_info(self, drug_name: str) -> dict:
        # calls the real openFDA public API (keyless). Bounded by a timeout so a
        # slow/unreachable upstream degrades gracefully instead of hanging the request.
        import httpx

        url = f"https://api.fda.gov/drug/label.json?search=openfda.brand_name:{drug_name}&limit=1"
        timeout = httpx.Timeout(float(os.getenv("FDA_TIMEOUT", "8")))
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.get(url)
            response.raise_for_status()
            return response.json()


class FixtureFDAProvider(FDAProvider):
    source = "fixture"

    async def get_drug_info(self, drug_name: str) -> dict:
        # returns fake FDA data — used for testing
        return {
            "drug": drug_name,
            "warnings": [
                "May increase risk of heart attack or stroke with long-term use",
                "Can cause stomach bleeding especially in people over 60",
            ],
            "source": "fixture",
        }


def get_fda_provider() -> FDAProvider:
    p = os.getenv("FDA_PROVIDER", "live")
    if p == "fixture":
        return FixtureFDAProvider()
    return LiveFDAProvider()
