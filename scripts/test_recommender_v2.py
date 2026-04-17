import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from recommender.recommender import build_artifacts, recommend_from_preferences

SCENARIOS = [
    {"activity": "culture", "budget": "Low", "season": "All Year", "vibe": "quiet"},
    {"activity": "hiking", "budget": "Low", "season": "Oct-May", "vibe": "photography"},
    {"activity": "adventure", "budget": "Medium", "season": "All Year", "vibe": "family"},
]

def main():
    artifacts = build_artifacts("data/final/pokhara_rural_pilot.csv")

    print(f"Loaded dataset rows: {len(artifacts.df)}")

    for i, prefs in enumerate(SCENARIOS, start=1):

        result = recommend_from_preferences(
            prefs,
            artifacts=artifacts,
            top_k=5
        )

        print("\n--------------------------------")
        print(f"Scenario {i}")
        print("Preferences:", prefs)
        print("Seed places:", result["seed_places"])

        for rank, rec in enumerate(result["recommendations"], start=1):
            print(
                f"{rank}. {rec['name']} | "
                f"score={rec['final_score']} | "
                f"reasons={rec['reasons']}"
            )

if __name__ == "__main__":
    main()