# OpenRouter Streaming RAG Design

## Overview
This document outlines the refactoring of the backend RAG (Retrieval-Augmented Generation) pipeline for RemoteCare Pro. The goal is to remove dead code (AWS Bedrock, mock providers), exclusively use OpenRouter with open-source models, and implement Server-Sent Events (SSE) streaming to improve perceived latency.

## Architecture & Data Flow
1. **Endpoint Update**: The FastAPI `/chat` endpoint will be updated to return a `StreamingResponse`.
2. **Context Retrieval**: The system will embed the user's query and perform a vector similarity search in `pgvector`.
3. **Prompt Construction**: The system prompt and retrieved context will be cleanly separated to ensure open-source models (like Llama 3 or Mixtral) do not confuse context with instruction.
4. **LLM Invocation**: The OpenRouter API will be called with `stream=True`.
5. **Streaming Response**: The `generate_recommendation` function will become an async generator that yields chunks of text back to the client as they arrive from OpenRouter.

## Dead Code Removal
- Completely remove the `bedrock` provider block and `boto3` import from `app/services/rag.py`.
- Completely remove the `mock` provider block and the `LLM_PROVIDER` environment variable dependency.
- Remove any unused synchronous logic that handles the entire response at once.

## Error Handling & Resilience
- **Database Search Failure**: If the `pgvector` query fails, the stream should yield an appropriate error message and gracefully close.
- **OpenRouter Timeout/Failure**: If the upstream OpenRouter API fails, the generator must catch the exception and yield an error chunk before terminating, allowing the client to show a friendly error state.

## Testing Strategy
- Update existing RAG tests to consume the async generator instead of a static dictionary.
- Verify that open-source models correctly follow the clinical guardrails with the updated prompt format.
