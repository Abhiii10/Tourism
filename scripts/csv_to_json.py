import json
import pandas as pd

CSV_PATH = "data/final/pokhara_rural_pilot.csv"
OUT_PATH = "app/assets/data/pokhara_rural_pilot.json"

def main():
    df = pd.read_csv(CSV_PATH).fillna("")
    records = df.to_dict(orient="records")

    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(records, f, ensure_ascii=False, indent=2)

    print("Saved:", OUT_PATH, "rows:", len(records))

if __name__ == "__main__":
    main()
