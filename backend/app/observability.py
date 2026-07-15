import os


def setup_tracing() -> None:
    endpoint = os.getenv("PHOENIX_COLLECTOR_ENDPOINT")
    if not endpoint:
        return

    from openinference.instrumentation.openai import OpenAIInstrumentor
    from phoenix.otel import register

    tracer_provider = register(project_name=os.getenv("PHOENIX_PROJECT_NAME", "remote-carepro"))
    OpenAIInstrumentor().instrument(tracer_provider=tracer_provider)
