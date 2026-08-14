import pytest
from unittest.mock import patch, MagicMock
from app.services.rag import generate_recommendation_stream

@pytest.fixture
def anyio_backend():
    return 'asyncio'

@pytest.mark.anyio
@patch('app.services.rag.retrieve_relevant_chunks')
@patch('app.services.rag.client_async')
async def test_generate_recommendation_stream_yields_chunks(mock_client_async, mock_retrieve):
    mock_retrieve.return_value = [{"source": "test.txt", "content": "mock context"}]
    
    # Mock OpenRouter client
    mock_chunk1 = MagicMock()
    mock_chunk1.choices = [MagicMock(delta=MagicMock(content="Hello "))]
    mock_chunk2 = MagicMock()
    mock_chunk2.choices = [MagicMock(delta=MagicMock(content="World"))]
    
    async def mock_create(*args, **kwargs):
        async def mock_async_generator():
            yield mock_chunk1
            yield mock_chunk2
        return mock_async_generator()
        
    mock_client_async.chat.completions.create.side_effect = mock_create
    
    generator = generate_recommendation_stream("test message", "knee")
    chunks = [chunk async for chunk in generator]
    assert chunks == ["Hello ", "World"]
