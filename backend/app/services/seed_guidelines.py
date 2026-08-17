"""
Run this once to load clinical guidelines into the vector database.
Usage: python -m app.services.seed_guidelines
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

from app.core.database import SessionLocal, init_db
from app.models import Embedding
from app.services.rag import get_embedding

# Clinical guidelines as text chunks
# In production, load these from PDF files or a CMS
GUIDELINES = [
    {
        "content": """Knee Replacement Post-Surgery Protocol:
Week 1-2: Complete rest, no weight bearing. Ice pack 20 minutes 3x daily.
Elevate leg above heart level. Monitor for DVT symptoms.
Pain management: Paracetamol 1g 4x daily, Ibuprofen 400mg 3x daily with food.""",
        "source": "NICE Guidelines — Knee Replacement",
        "source_type": "guideline",
        "surgery_type": "knee replacement"
    },
    {
        "content": """Knee Replacement Physiotherapy Protocol:
Day 3: Gentle ankle pumps and quadriceps sets.
Week 2: Begin partial weight bearing with walker.
Week 3-4: Progress to full weight bearing. Begin stair climbing.
Week 6: Return to driving if right knee, pain controlled.
Week 12: Return to low-impact activities.""",
        "source": "NICE Guidelines — Knee Replacement",
        "source_type": "guideline",
        "surgery_type": "knee replacement"
    },
    {
        "content": """Diabetic Patients Post-Surgery Special Considerations:
Monitor blood glucose every 4-6 hours for first 48 hours.
Target blood glucose: 6-10 mmol/L.
Increased infection risk — monitor wound site daily.
Delayed wound healing expected — extend suture removal to day 14.
NSAIDs with caution — monitor renal function.
Metformin: hold for 48 hours post-surgery, restart when eating normally.""",
        "source": "Surgical Diabetes Management Protocol",
        "source_type": "guideline",
        "surgery_type": None  # applies to all surgeries
    },
    {
        "content": """Hip Replacement Post-Surgery Protocol:
Avoid hip flexion beyond 90 degrees for 6 weeks.
No crossing legs. Use raised toilet seat.
Sleep with pillow between knees.
Physiotherapy from day 1: ankle pumps, heel slides.
Weight bearing as tolerated from day 1 with walking frame.
DVT prophylaxis: Rivaroxaban 10mg daily for 35 days.""",
        "source": "NICE Guidelines — Hip Replacement",
        "source_type": "guideline",
        "surgery_type": "hip replacement"
    },
    {
        "content": """General Post-Surgery Wound Care:
Keep wound dry for 48 hours post-surgery.
Change dressing every 2-3 days or when soiled.
Watch for signs of infection: redness, warmth, swelling, discharge, fever >38°C.
Do not submerge wound in water until fully healed.
Suture/staple removal: 10-14 days for lower limb, 7-10 days for upper limb.""",
        "source": "WHO Surgical Care Guidelines",
        "source_type": "guideline",
        "surgery_type": None
    },
    {
        "content": """NSAID Use Post-Surgery:
Ibuprofen 400mg 3x daily with food for pain management.
Contraindicated in: renal impairment, peptic ulcer disease, heart failure.
Use with caution in: diabetic patients, elderly (>65), patients on anticoagulants.
Maximum duration: 5-7 days post-surgery.
Alternative: Paracetamol 1g 4x daily if NSAIDs contraindicated.""",
        "source": "FDA Drug Safety Guidelines",
        "source_type": "guideline",
        "surgery_type": None
    }
]

def seed():
    print("Initialising database...")
    init_db()

    db = SessionLocal()

    print("Checking existing embeddings...")
    existing = db.query(Embedding).count()
    if existing > 0:
        print(f"Already have {existing} embeddings. Skipping seed.")
        db.close()
        return

    print(f"Seeding {len(GUIDELINES)} clinical guideline chunks...")

    for i, guideline in enumerate(GUIDELINES):
        print(f"  Embedding chunk {i+1}/{len(GUIDELINES)}: {guideline['source']}")
        embedding_vector = get_embedding(guideline["content"])

        embedding = Embedding(
            content=guideline["content"],
            source=guideline["source"],
            source_type=guideline["source_type"],
            surgery_type=guideline["surgery_type"],
            embedding=embedding_vector
        )
        db.add(embedding)

    db.commit()
    db.close()
    print("Done. Clinical guidelines loaded into vector database.")

if __name__ == "__main__":
    seed()
