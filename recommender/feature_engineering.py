import re
import pandas as pd

def normalize_text(value):
    text = str(value or "").lower().strip()
    text = re.sub(r"[|,/;]+", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text


def repeat_tokens(tokens, weight):
    cleaned = [normalize_text(t) for t in tokens if normalize_text(t)]
    return " ".join(cleaned * weight)


def season_tokens(season):
    s = normalize_text(season)

    if s == "all year":
        return ["all year", "year round"]

    if "oct" in s or "may" in s:
        return ["oct-may", "dry season", "autumn", "spring"]

    if "jun" in s or "sep" in s:
        return ["jun-sep", "monsoon", "rainy"]

    return [s]


def build_item_text(row: pd.Series):

    parts = []

    parts.append(repeat_tokens([row.get("type", "")], 3))
    parts.append(repeat_tokens(str(row.get("amenities", "")).split(), 3))
    parts.append(repeat_tokens(str(row.get("cultural_tags", "")).split(), 3))
    parts.append(repeat_tokens(season_tokens(row.get("best_season", "")), 2))
    parts.append(repeat_tokens([row.get("price_tier", "")], 2))
    parts.append(normalize_text(row.get("description", "")))

    return normalize_text(" ".join(parts))


def build_preference_text(prefs):

    tokens = []

    if prefs.get("activity"):
        tokens.extend([prefs["activity"]] * 4)

    if prefs.get("vibe"):
        tokens.extend([prefs["vibe"]] * 3)

    if prefs.get("budget"):
        tokens.extend([prefs["budget"]] * 2)

    if prefs.get("season"):
        tokens.extend(season_tokens(prefs["season"]) * 2)

    return normalize_text(" ".join(tokens))


def extract_match_reasons(row, prefs):

    reasons = []

    text_blob = " ".join([
        str(row.get("type", "")),
        str(row.get("amenities", "")),
        str(row.get("cultural_tags", "")),
        str(row.get("description", ""))
    ]).lower()

    activity = prefs.get("activity", "").lower()
    if activity and activity in text_blob:
        reasons.append(f"matches activity '{activity}'")

    vibe = prefs.get("vibe", "").lower()
    if vibe and vibe in text_blob:
        reasons.append(f"matches vibe '{vibe}'")

    budget = prefs.get("budget", "").lower()
    if budget and str(row.get("price_tier", "")).lower() == budget:
        reasons.append(f"fits budget '{budget}'")

    return reasons[:3]