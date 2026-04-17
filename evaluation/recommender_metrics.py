import pandas as pd
from recommender.recommender import load_data, build_similarity, recommend

# Simple scenario-based evaluation:
# We define "relevant" as sharing at least one cultural tag OR same type.
# This is a proxy evaluation suitable for low-data, content-based pilot studies.

def tags_set(s: str):
    return set([t.strip().lower() for t in str(s).split("|") if t.strip()])

def precision_at_k(recs, relevant_set):
    if not recs:
        return 0.0
    hits = sum([1 for r in recs if r["name"] in relevant_set])
    return hits / len(recs)

def main():
    df = load_data("data/final/pokhara_rural_pilot.csv")
    S = build_similarity(df)

    # Build quick relevance sets
    name_to_type = dict(zip(df["name"], df["type"]))
    name_to_tags = {row["name"]: tags_set(row.get("cultural_tags", "")) for _, row in df.iterrows()}

    test_names = df["name"].head(10).tolist()  # evaluate first 10 seeds
    k = 5
    scores = []

    for seed in test_names:
        seed_type = name_to_type.get(seed, "")
        seed_tags = name_to_tags.get(seed, set())

        # relevant: same type OR share at least one tag
        relevant = set()
        for name in df["name"].tolist():
            if name == seed:
                continue
            if name_to_type.get(name, "") == seed_type:
                relevant.add(name)
                continue
            if len(seed_tags.intersection(name_to_tags.get(name, set()))) > 0:
                relevant.add(name)

        recs = recommend(df, S, seed, top_k=k)
        p = precision_at_k(recs, relevant)
        scores.append(p)

    avg_p = sum(scores) / len(scores) if scores else 0.0
    print(f"Average Precision@{k} (proxy): {avg_p:.3f}")

if __name__ == "__main__":
    main()
