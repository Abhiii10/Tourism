import json

from recommender.recommender import build_artifacts, recommend_from_preferences

SCENARIOS = [
    {"activity": "culture", "budget": "Low", "season": "All Year", "vibe": "quiet"},
    {"activity": "hiking", "budget": "Low", "season": "Oct-May", "vibe": "photography"},
    {"activity": "lake", "budget": "Low", "season": "All Year", "vibe": "family"},
]

def main():

    artifacts = build_artifacts("data/final/pokhara_rural_pilot.csv")

    results = []

    for prefs in SCENARIOS:
        result = recommend_from_preferences(prefs, artifacts=artifacts, top_k=5)
        results.append(result)

    with open("app/assets/data/recommendations_v2.json", "w") as f:
        json.dump(results, f, indent=2)

    print("Saved recommendations_v2.json")

if __name__ == "__main__":
    main()