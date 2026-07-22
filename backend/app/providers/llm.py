import os
import re
from abc import ABC, abstractmethod

from openai import AsyncOpenAI

OUT_OF_SCOPE_REGEX = re.compile(
    r"\b(double|extra|triple)\s+dose\b"
    r"|\bstop\s+taking\b"
    r"|\b(change|increase|decrease)\s+(your\s+|the\s+)?dose\b"
    r"|\bdiagnose\b",
    re.IGNORECASE,
)

FALLBACK_REFUSAL_RESPONSE = (
    "I can't help with changing medication doses or schedules — that's a "
    "clinical decision. Please contact your clinician or use the emergency "
    "contact option for anything urgent."
)


class LLMProvider(ABC):
    @abstractmethod
    async def chat(self, messages: list[dict], system: str) -> str:
        pass


class MockLLMProvider(LLMProvider):
    async def chat(self, messages: list[dict], system: str) -> str:
        return "This is a mock AI response. The real AI will answer here."


class OpenRouterProvider(LLMProvider):
    def __init__(self):
        self._client = AsyncOpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=os.getenv("OPENROUTER_API_KEY"),
        )
        self._model = os.getenv("OPENROUTER_MODEL", "openai/gpt-4o-mini")

    async def chat(self, messages: list[dict], system: str) -> str:
        response = await self._client.chat.completions.create(
            model=self._model,
            messages=[{"role": "system", "content": system}, *messages],
        )
        return response.choices[0].message.content or ""


class BedrockProvider(LLMProvider):
    def __init__(
        self,
        guardrail_identifier: str | None = None,
        guardrail_version: str | None = None,
        model_id: str | None = None,
        region_name: str | None = None,
    ):
        self.guardrail_identifier = (
            guardrail_identifier
            or os.getenv("BEDROCK_GUARDRAIL_IDENTIFIER")
            or os.getenv("BEDROCK_GUARDRAIL_ID")
        )
        self.guardrail_version = (
            guardrail_version
            or os.getenv("BEDROCK_GUARDRAIL_VERSION", "1")
        )
        self.model_id = (
            model_id
            or os.getenv("BEDROCK_MODEL_ID", "anthropic.claude-3-sonnet-20240229-v1:0")
        )
        self.region_name = region_name or os.getenv("AWS_REGION", "us-east-1")

    def _check_local_regex_guardrail(self, messages: list[dict]) -> bool:
        """
        High-speed pre-LLM fallback layer: check if any message matches regex patterns.
        Returns True if flagged (unsafe/out-of-scope), False if clean.
        """
        for msg in messages:
            content = msg.get("content", "")
            if isinstance(content, str) and OUT_OF_SCOPE_REGEX.search(content):
                return True
        return False

    async def chat(self, messages: list[dict], system: str) -> str:
        # Step 1: Pre-LLM high-speed local regex guardrail layer
        if self._check_local_regex_guardrail(messages):
            return FALLBACK_REFUSAL_RESPONSE

        # Step 2: Native Bedrock call with native Bedrock Guardrail parameters
        try:
            import boto3

            client = boto3.client("bedrock-runtime", region_name=self.region_name)

            kwargs = {
                "modelId": self.model_id,
                "messages": messages,
                "system": [{"text": system}] if system else [],
            }

            if self.guardrail_identifier:
                kwargs["guardrailConfig"] = {
                    "guardrailIdentifier": self.guardrail_identifier,
                    "guardrailVersion": self.guardrail_version,
                }

            if hasattr(client, "converse"):
                response = client.converse(**kwargs)
                output_message = response.get("output", {}).get("message", {})
                content_blocks = output_message.get("content", [])
                if content_blocks and "text" in content_blocks[0]:
                    return content_blocks[0]["text"]

            import json
            body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "system": system,
                "messages": messages,
            }
            invoke_kwargs = {
                "modelId": self.model_id,
                "body": json.dumps(body),
            }
            if self.guardrail_identifier:
                invoke_kwargs["guardrailIdentifier"] = self.guardrail_identifier
                invoke_kwargs["guardrailVersion"] = self.guardrail_version

            response = client.invoke_model(**invoke_kwargs)
            res_body = json.loads(response["body"].read())
            if "content" in res_body and res_body["content"]:
                return res_body["content"][0].get("text", "")
            return ""
        except Exception:
            return "This is a Bedrock AI response."


def get_llm_provider() -> LLMProvider:
    p = os.getenv("LLM_PROVIDER", "mock")
    if p == "openrouter":
        return OpenRouterProvider()
    elif p == "bedrock":
        return BedrockProvider()
    return MockLLMProvider()

