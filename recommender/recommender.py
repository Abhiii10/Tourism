from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

import pandas as pd

from recommender.feature_engineering import (
    build_item_text,
    build_preference_text,
    extract_match_reasons,
)
from recommender.preference_matcher import find_seed_places
from recommender.similarity import (
    build_vector_space,
    pairwise_similarity,
    similarity_to_query,
)

CSV_PATH = "data/final/pokhara_rural_pilot.csv"


@dataclass
class RecommenderArtifacts:
    df: pd.DataFrame
    vectorizer: object
    matrix: object
    similarity_matrix: object


def load_data(path: str = CSV_PATH) -> pd.DataFrame:
    df = pd.read_csv(path).fillna("").copy()
    df["item_text"] = df.apply(build_item_text, axis=1)
    return df


def build_artifacts(path: str = CSV_PATH) -> RecommenderArtifacts:
    df = load_data(path)
    vectorizer, matrix = build_vector_space(df["item_text"].tolist())
    similarity_matrix = pairwise_similarity(matrix)
    return RecommenderArtifacts(
        df=df,
        vectorizer=vectorizer,
        matrix=matrix,
        similarity_matrix=similarity_matrix,
    )


def recommend_from_preferences(
    prefs: Dict[str, str],
    artifacts: Optional[RecommenderArtifacts] = None,
    csv_path: str = CSV_PATH,
    top_k: int = 8,
    top_seed_n: int = 3,
    preference_weight: float = 0.7,
    seed_weight: float = 0.3,
) -> Dict[str, object]:
    if artifacts is None:
        artifacts = build_artifacts(csv_path)

    df = artifacts.df
    pref_text = build_preference_text(prefs)

    if not pref_text.strip():
        raise ValueError("At least one preference is required.")

    pref_scores = similarity_to_query(
        artifacts.vectorizer,
        artifacts.matrix,
        pref_text
    )

    seed_candidates = find_seed_places(df, prefs, top_n=max(top_seed_n, 1))

    seed_rows: List[Tuple[int, str, float]] = []
    for seed_name, seed_match_score in seed_candidates:
        idx_list = df.index[df["name"].str.lower() == seed_name.lower()].tolist()
        if idx_list:
            seed_rows.append((idx_list[0], seed_name, seed_match_score))

    if seed_rows and sum(seed_match for _, _, seed_match in seed_rows) > 0:
        avg_seed_scores = sum(
            artifacts.similarity_matrix[idx] for idx, _, _ in seed_rows
        ) / len(seed_rows)
    else:
        avg_seed_scores = pref_scores
        seed_rows = []

    final_scores = preference_weight * pref_scores + seed_weight * avg_seed_scores

    rankings = []
    seed_names = {name.lower() for _, name, _ in seed_rows}

    for idx, row in df.iterrows():
        rankings.append({
            "name": row["name"],
            "type": row.get("type", ""),
            "best_season": row.get("best_season", ""),
            "price_tier": row.get("price_tier", ""),
            "latitude": float(row.get("latitude", 0) or 0),
            "longitude": float(row.get("longitude", 0) or 0),
            "preference_score": round(float(pref_scores[idx]), 4),
            "seed_similarity": round(float(avg_seed_scores[idx]), 4),
            "final_score": round(float(final_scores[idx]), 4),
            "reasons": extract_match_reasons(row, prefs),
            "is_seed": row["name"].lower() in seed_names,
        })

    rankings.sort(key=lambda x: x["final_score"], reverse=True)

    filtered = []
    for item in rankings:
        if item["is_seed"]:
            continue
        filtered.append(item)
        if len(filtered) >= top_k:
            break

    return {
        "preferences": prefs,
        "preference_text": pref_text,
        "seed_places": [
            {"name": name, "match_score": round(float(score), 2)}
            for _, name, score in seed_rows
        ],
        "recommendations": filtered,
        "dataset_size": int(len(df)),
    }