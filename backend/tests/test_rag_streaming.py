import pytest
from unittest.mock import patch, MagicMock
from app.services.rag import generate_recommendation_stream

@pytest.fixture
def anyio_backend():
    return 'asyncio'

@pytest.mark.anyio
@patch('app.services.rag.retrieve_relevant_chunks')
@patch('app.services.rag.OpenAI')
async def test_generate_recommendation_stream_yields_chunks(mock_openai, mock_retrieve, db_session):
    mock_retrieve.return_value = [{"source": "test.txt", "content": "mock context"}]
    
    # Mock OpenRouter client
    mock_stream = MagicMock()
    mock_chunk1 = MagicMock()
    mock_chunk1.choices = [MagicMock(delta=MagicMock(content="Hello "))]
    mock_chunk2 = MagicMock()
    mock_chunk2.choices = [MagicMock(delta=MagicMock(content="World"))]
    mock_stream.__iter__.return_value = [mock_chunk1, mock_chunk2]
    mock_openai.return_value.chat.completions.create.return_value = mock_stream
    
    generator = generate_recommendation_stream(db_session, "test message", "knee")
    chunks = [chunk async for chunk in generator]
    assert chunks == ["Hello ", "World"]
