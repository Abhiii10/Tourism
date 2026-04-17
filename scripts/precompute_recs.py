import json
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

CSV_PATH = "data/final/pokhara_rural_pilot.csv"
OUT_PATH = "app/assets/data/recommendations.json"
TOP_K = 8

def main():
    df = pd.read_csv(CSV_PATH).fillna("")
    required = ["name", "type", "description", "amenities", "cultural_tags"]
    for c in required:
        if c not in df.columns:
            raise ValueError(f"Missing column in CSV: {c}")

    df["text"] = (
        df["type"].astype(str) + " " +
        df["description"].astype(str) + " " +
        df["amenities"].astype(str).str.replace("|", " ", regex=False) + " " +
        df["cultural_tags"].astype(str).str.replace("|", " ", regex=False)
    )

    vectorizer = TfidfVectorizer(stop_words="english", ngram_range=(1, 2))
    X = vectorizer.fit_transform(df["text"])
    S = cosine_similarity(X)

    names = df["name"].tolist()
    recs = {}

    for i, name in enumerate(names):
        scores = list(enumerate(S[i]))
        scores.sort(key=lambda x: x[1], reverse=True)
        top = []
        for j, score in scores[1:TOP_K+1]:
            top.append({"name": names[j], "score": float(round(score, 4))})
        recs[name] = top

    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(recs, f, ensure_ascii=False, indent=2)

    print("Saved:", OUT_PATH, "items:", len(recs))

if __name__ == "__main__":
    main()
