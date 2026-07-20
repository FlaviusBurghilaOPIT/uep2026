import asyncio
import os
from abc import ABC, abstractmethod

import boto3
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
        return response.choices[0].message.content or ""


class BedrockLLMProvider(LLMProvider):
    def __init__(self):
        region = os.getenv("AWS_REGION", "us-east-1")
        self._client = boto3.client("bedrock-runtime", region_name=region)
        self._model_id = os.getenv(
            "BEDROCK_MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0"
        )
        self._guardrail_id = os.getenv("BEDROCK_GUARDRAIL_ID")
        self._guardrail_version = os.getenv("BEDROCK_GUARDRAIL_VERSION")

    async def chat(self, messages, system):
        converse_messages = [
            {"role": m["role"], "content": [{"text": m["content"]}]}
            for m in messages
        ]

        kwargs = {
            "modelId": self._model_id,
            "messages": converse_messages,
            "system": [{"text": system}],
        }

        if self._guardrail_id and self._guardrail_version:
            kwargs["guardrailConfig"] = {
                "guardrailIdentifier": self._guardrail_id,
                "guardrailVersion": self._guardrail_version,
            }

        # boto3 is sync-only; run in a thread so we don't block the event loop
        response = await asyncio.to_thread(self._client.converse, **kwargs)

        output_message = response["output"]["message"]
        return "".join(
            block.get("text", "") for block in output_message["content"]
        )


def get_llm_provider() -> LLMProvider:
    p = os.getenv("LLM_PROVIDER", "mock")
    if p == "openrouter":
        return OpenRouterProvider()
    if p == "bedrock":
        return BedrockLLMProvider()
    return MockLLMProvider()
