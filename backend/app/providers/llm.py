import os
from abc import ABC, abstractmethod

class LLMProvider(ABC):
    @abstractmethod
    async def chat(self, messages: list[dict], system: str) -> str:
        pass

class MockLLMProvider(LLMProvider):
    async def chat(self, messages, system):
        return "This is a mock AI response. The real AI will answer here."

class OpenRouterProvider(LLMProvider):
    async def chat(self, messages, system):
        # real OpenRouter API call — built in Phase 2
        pass

class BedrockProvider(LLMProvider):
    async def chat(self, messages, system):
        # real AWS Bedrock call — built in Phase 3
        pass

def get_llm_provider() -> LLMProvider:
    p = os.getenv("LLM_PROVIDER", "mock")
    if p == "openrouter": return OpenRouterProvider()
    if p == "bedrock": return BedrockProvider()
    return MockLLMProvider()