#!/usr/bin/env python3
import json
import math
import random
import sys


def number(value, default):
    try:
        return float(value)
    except (TypeError, ValueError):
        return float(default)


request = json.loads(sys.stdin.read() or "{}")
targets = request.get("targetProperties", {})
constraints = request.get("constraints", {})
target = number(request.get("target_strength", targets.get("compressive_strength_mpa")), 40)
max_cost = number(request.get("max_cost", constraints.get("max_cost_per_m3")), 220)
max_co2 = number(request.get("max_co2", constraints.get("max_co2_kg_per_m3")), 300)
seed = int(number(request.get("seed"), 42))
iterations = max(60, min(int(number(request.get("iterations"), 600)), 10000))
random.seed(seed)

candidates = []
for _ in range(iterations):
    cement = random.uniform(180, 450)
    fly_ash = random.uniform(0, 160)
    ggbss = random.uniform(0, 200)
    silica_fume = random.uniform(0, 35)
    water = random.uniform(120, 205)
    admixture = random.uniform(0, 14)
    fine_aggregate = random.uniform(600, 950)
    coarse_aggregate = random.uniform(750, 1200)
    binder = max(cement + fly_ash + ggbss + silica_fume, 1)
    scm = fly_ash + ggbss + silica_fume
    water_binder = water / binder
    scm_ratio = scm / binder

    strength = 110 * math.exp(-2.05 * water_binder)
    strength *= 1 - 0.10 * scm_ratio + 0.08 * min(1, silica_fume / 20)
    strength += random.gauss(0, 1.5)
    cost = (
        cement * 0.16 + fly_ash * 0.08 + ggbss * 0.09 + silica_fume * 0.35
        + water * 0.002 + admixture * 2.5 + (fine_aggregate + coarse_aggregate) * 0.025
    )
    co2 = cement * 0.82 + fly_ash * 0.04 + ggbss * 0.07 + silica_fume * 0.18
    feasible = strength >= target and cost <= max_cost and co2 <= max_co2
    score = (
        abs(target - strength) * 2
        + cost * 0.15
        + co2 * 0.04
        + max(0, target - strength) * 100
        + max(0, cost - max_cost) * 50
        + max(0, co2 - max_co2) * 25
    )
    candidates.append({
        "components": {
            "cement_kg": round(cement, 1),
            "fly_ash_kg": round(fly_ash, 1),
            "ggbss_kg": round(ggbss, 1),
            "silica_fume_kg": round(silica_fume, 1),
            "water_kg": round(water, 1),
            "superplasticizer_kg": round(admixture, 2),
            "fine_aggregate_kg": round(fine_aggregate, 1),
            "coarse_aggregate_kg": round(coarse_aggregate, 1),
        },
        "compressiveStrengthMPa": round(strength, 2),
        "slumpMM": 100.0,
        "permeability": None,
        "costPerM3": round(cost, 2),
        "co2KgPerM3": round(co2, 2),
        "waterBinderRatio": round(water_binder, 4),
        "feasible": feasible,
        "score": round(score, 3),
    })

candidates.sort(key=lambda candidate: (not candidate["feasible"], candidate["score"]))
selected = candidates[:3]
feasible_count = sum(1 for candidate in candidates if candidate["feasible"])
result = {
    "mixes": selected,
    "candidates": candidates[:20],
    "optimizer": "seeded-heuristic-search",
    "model": "analytical-strength-surrogate-v1",
    "evaluatedCandidates": iterations,
    "feasibleCandidates": feasible_count,
    "constraints": {
        "targetStrengthMPa": target,
        "maxCostPerM3": max_cost,
        "maxCo2KgPerM3": max_co2,
    },
    "rationale": (
        f"Selected the three highest-ranked candidates from {iterations} deterministic samples; "
        f"{feasible_count} satisfied all strength, cost, and CO2 constraints."
    ),
}
sys.stdout.write(json.dumps(result))
