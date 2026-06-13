import argparse
import json

import pandas as pd
from scipy.stats import ks_2samp


def drift(current_path: str, baseline_path: str):
    current = pd.read_csv(current_path)
    baseline = pd.read_csv(baseline_path)
    flags = []
    for feature in sorted(set(current.columns) & set(baseline.columns)):
        current_values = pd.to_numeric(current[feature], errors="coerce").dropna()
        baseline_values = pd.to_numeric(baseline[feature], errors="coerce").dropna()
        if len(current_values) > 5 and len(baseline_values) > 5:
            statistic, p_value = ks_2samp(current_values, baseline_values)
            if p_value < 0.05:
                flags.append({"feature": feature, "statistic": float(statistic), "pValue": float(p_value)})
    return {"driftDetected": bool(flags), "driftFlags": flags}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compare current and baseline feature distributions.")
    parser.add_argument("current")
    parser.add_argument("baseline")
    args = parser.parse_args()
    print(json.dumps(drift(args.current, args.baseline)))
