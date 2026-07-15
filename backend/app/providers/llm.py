import os
from abc import ABC, abstractmethod

from openai import AsyncOpenAI


class LLMProvider(ABC):
    @abstractmethod
    async def chat(self, messages: list[dict], system: str) -> str:
        pass


class MockLLMProvider(LLMProvider):
    async def chat(self, messages, system):
        return "This is a mock AI response. The real AI will answer here."


class OpenRouterProvider(LLMProvider):
    def __init__(self):
        self._client = AsyncOpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=os.getenv("OPENROUTER_API_KEY"),
        )
        self._model = os.getenv("OPENROUTER_MODEL", "openai/gpt-4o-mini")

    async def chat(self, messages, system):
        response = await self._client.chat.completions.create(
            model=self._model,
            messages=[{"role": "system", "content": system}, *messages],
        )
        return response.choices[0].message.content


def get_llm_provider() -> LLMProvider:
    p = os.getenv("LLM_PROVIDER", "mock")
    if p == "openrouter":
        return OpenRouterProvider()
    return MockLLMProvider()
