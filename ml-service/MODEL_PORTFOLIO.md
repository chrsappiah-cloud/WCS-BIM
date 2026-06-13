# WCS-BIM ML Portfolio

## Chapter 3: Materials prediction

The tabular training pipeline supports one registered model per target and compares BPNN, SVM-RBF, random forest, gradient boosting, and XGBoost. Supported concrete and geopolymer targets include compressive strength, tensile strength, slump, RCPT, and water absorption.

The same pipeline can train domain datasets by supplying the relevant numeric feature columns and target:

- Soil: moisture, density, gradation, and compaction energy to CBR.
- Asphalt: binder, gradation, and air voids to rut depth or stability.
- FRP: fibre/resin type and volume fraction to tensile or compressive strength.

Use separate artifact directories per domain so feature and target registries cannot be mixed accidentally.

## Chapter 3: Multi-objective optimization

`POST /optimize` uses the best registered compressive-strength surrogate and returns three feasible cost/carbon trade-offs. Every candidate is checked against target strength, maximum cost, and maximum embodied carbon. This can later be replaced with NSGA-II without changing the iOS response contract.

## Chapter 5: Image QC

Crack classification and segmentation require a separately versioned vision dataset and model artifact. Recommended production flow:

1. Store original inspection images in private Supabase Storage.
2. Train a U-Net or SAM-assisted segmentation model using reviewed pixel masks.
3. Record model version, confidence, crack length/width, mask URI, and human-review status in `material_tests.image_analysis`.
4. Require human confirmation before creating a BIM-linked non-conformance.

Do not treat automated image findings as structural-safety determinations.

## Chapters 7 and 8: Generative workflows

Design Copilot, QC reporting, and DFMA planning remain prompt-driven services in the Node API. Their outputs are proposals and reports, not autonomous engineering approvals. Persist selected alternatives, source BIM element IDs, prompt/model versions, and reviewer decisions for traceability.
