from recommender.recommender import load_data, build_similarity, recommend
from recommender.preference_matcher import find_seed_places

def main():
    df = load_data("data/final/pokhara_rural_pilot.csv")
    S = build_similarity(df)

    print("\n=== Experience-based Recommendation Demo ===")
    print("Pick an experience instead of typing place names.\n")

    activity = input("Activity (hiking/viewpoint/lake/culture/adventure/wildlife): ").strip()
    budget = input("Budget (Low/Medium/High) or leave blank: ").strip()
    season = input("Season (Oct–May/All Year etc.) or leave blank: ").strip()
    vibe = input("Vibe (quiet/family/photography) or leave blank: ").strip()

    prefs = {"activity": activity, "budget": budget, "season": season, "vibe": vibe}

    seeds = find_seed_places(df, prefs, top_n=3)
    print("\nTop seed matches:")
    for name, sc in seeds:
        print(f"- {name} (match score={sc:.2f})")

    if not seeds or seeds[0][1] == 0:
        print("\nNo strong matches found. Try different keywords.")
        return

    seed_name = seeds[0][0]
    recs = recommend(df, S, seed_name, top_k=8)

    print(f"\nRecommendations based on: {seed_name}\n")
    for r in recs:
        print(f"- {r['name']} ({r['type']}) score={r['score']}")

if __name__ == "__main__":
    main()
