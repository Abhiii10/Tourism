import pandas as pd
from typing import List, Dict, Tuple

def normalize_tokens(s: str) -> List[str]:
    return [t.strip().lower() for t in str(s).replace("|", " ").split() if t.strip()]

def score_place(row: pd.Series, prefs: Dict[str, str]) -> float:
    score = 0.0

    text_tokens = set(
        normalize_tokens(row.get("type", "")) +
        normalize_tokens(row.get("amenities", "")) +
        normalize_tokens(row.get("cultural_tags", "")) +
        normalize_tokens(row.get("description", ""))
    )

    activity = prefs.get("activity", "").lower().strip()
    if activity:
        if activity in text_tokens:
            score += 3.0

        synonyms = {
            "viewpoint": ["sunrise", "sunset", "panoramic", "view", "ridge"],
            "hiking": ["trek", "trail", "walk", "forest"],
            "lake": ["boating", "fish", "wetland"],
            "culture": ["gurung", "magar", "newar", "tharu", "museum", "heritage"],
            "adventure": ["paragliding", "canyoning", "cycling", "zip", "cave"],
            "wildlife": ["bird", "wetland", "forest", "conservation"],
        }

        for syn in synonyms.get(activity, []):
            if syn in text_tokens:
                score += 1.0

    budget = prefs.get("budget", "").strip()
    if budget and str(row.get("price_tier", "")).strip().lower() == budget.lower():
        score += 1.5

    season = prefs.get("season", "").strip().lower()
    if season:
        row_season = str(row.get("best_season", "")).strip().lower()
        if season in row_season or row_season in season:
            score += 0.7
        if row_season == "all year":
            score += 0.3

    vibe = prefs.get("vibe", "").lower().strip()
    if vibe and vibe in text_tokens:
        score += 1.0

    return score

def find_seed_places(df: pd.DataFrame, prefs: Dict[str, str], top_n: int = 5) -> List[Tuple[str, float]]:
    scored = []
    for _, row in df.iterrows():
        s = score_place(row, prefs)
        scored.append((row["name"], s))

    scored.sort(key=lambda x: x[1], reverse=True)
    return scored[:top_n]