import os
import httpx
from fastapi import APIRouter
from openai import OpenAI

router = APIRouter()

@router.get("/fda/drug/{name}")
async def get_drug_info(name: str):
    """
    1. Call openFDA API for the drug
    2. Extract warnings
    3. Summarize with LLM in plain language
    4. Return warnings + source
    """

    # Step 1 — call openFDA
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"https://api.fda.gov/drug/label.json?search=openfda.brand_name:{name}+openfda.generic_name:{name}&limit=1",
                timeout=10.0
            )
            fda_data = response.json()
    except Exception:
        return {
            "drug": name,
            "warnings": ["Could not reach openFDA. Please try again."],
            "source": "openFDA",
            "retrieved_at": "unavailable"
        }

    # Step 2 — extract raw warning text
    raw_warnings = []
    if "results" in fda_data and len(fda_data["results"]) > 0:
        result = fda_data["results"][0]
        for field in ["warnings", "warnings_and_cautions", "boxed_warning", "precautions"]:
            if field in result:
                raw_warnings.extend(result[field])

    if not raw_warnings:
        return {
            "drug": name,
            "warnings": ["No warnings found in openFDA for this drug."],
            "source": "openFDA",
            "retrieved_at": "now"
        }

    # Step 3 — summarize with LLM
    raw_text = " ".join(raw_warnings)[:3000]  # limit to 3000 chars

    provider = os.getenv("LLM_PROVIDER", "mock")

    if provider == "mock":
        warnings = [
            f"Mock warning for {name}: May cause side effects.",
            "Consult your doctor before use."
        ]
    elif provider == "openrouter":
        client = OpenAI(
            api_key=os.getenv("OPENROUTER_API_KEY"),
            base_url="https://openrouter.ai/api/v1"
        )
        response = client.chat.completions.create(
            model=os.getenv("OPENROUTER_MODEL", "openai/gpt-4o-mini"),
            messages=[
                {
                    "role": "system",
                    "content": """You are a clinical pharmacist summarizing FDA drug warnings 
for doctors. Extract the 3-5 most important warnings and side effects. 
Write each as a short plain-English sentence. Be specific and clinical.
Return only a JSON array of strings, nothing else.
Example: ["May increase risk of heart attack with long-term use", "Avoid in patients with renal impairment"]"""
                },
                {
                    "role": "user",
                    "content": f"Summarize the key warnings for {name}:\n\n{raw_text}"
                }
            ]
        )
        import json
        try:
            warnings = json.loads(response.choices[0].message.content)
        except Exception:
            warnings = [response.choices[0].message.content]

    from datetime import datetime
    return {
        "drug": name,
        "warnings": warnings,
        "source": "openFDA",
        "retrieved_at": datetime.utcnow().isoformat()
    }