# Preregistracija — krūties naviko požymių klasifikavimas (WDBC)

Užrašyta **prieš** `evaluate_test.m`. Po testo atrakinimo šio failo hipotezės, slenksčių taisyklės ir skaidinys **nekeičiami**.

## Užrakintas išorinis skaidinys

- Procedūra: `cvpartition(y, 'HoldOut', 0.20, 'Stratify', true)` su `rng(42, 'twister')`.
- Faktinis rezultatas (natūralus `cvpartition`, ne rankinis kirpimas): **456 mokymas** (170 M / 286 B), **113 testas** (42 M / 71 B).
- Plane minėta ≈455 / ≈114 ir ≈42 M / ≈72 B; priimta 113/456 kaip oficialaus MATLAB kvietimo išvestis. Klasių santykis viso rinkinio ±1 atvejis.
- Indeksai: `data/processed/split_idx.mat` (`idxTrain`, `idxTest`). Testo statistikos jokiame `fit` nenaudojamos.

## Vidinis CV (6.1)

- 5 poaibiai × 5 kartojimai = **25 skaidiniai**, kiekvienas stratifikuotas pagal klasę.
- Pakartojimo sėkla: `rng(cfg.seed + 1000*r)`, r = 1…5.
- Foldo mokymo sėkla: `rng(cfg.seed + 1000*r + f)`.
- Standartizacija (formulė 1) kiekviename folde iš naujo, tik iš to foldo mokymo eilučių.

## Patvirtintos konstantos (nekeisti)

- Kainų santykis **c_FN : c_FP = 5 : 1**, `cfg.cost = [5 1]`, `cfg.costMatrix = [0 1; 5 0]`.
- H1 riba **ΔSp ≥ 0,03** ir AUC_SVM ≥ AUC_LR − 0,005 taške `t_se98`.
- Jautrumo tikslas **Se ≥ 0,98** slenksčiui `t_se98`.
- `cfg.seed = 42`, MLP sėklos `1:5`.
- Hiperparametrai tik tinkleliu pagal vidutinį OOF ROC-AUC per 25 skaidinius; `bayesopt` nenaudojama.

## Hipotezės

**H1.** Taške `t_se98` (didžiausias t su OOF Se ≥ 0,98): Sp_SVM − Sp_LR ≥ 0,03 ir AUC_SVM ≥ AUC_LR − 0,005. Priėmimas: taškinis ΔSp ≥ 0,03 ir suporuoto bootstrap (2000) 95 % PI apatinė riba > 0; AUC — DeLong PI apatinė riba ≥ −0,005.

**H2.** Platt SVM Brier teste ne blogesnis už LR daugiau kaip 0,01; kalibracijos nuolydis b ∈ [0,8; 1,25].

**H3.** Įdėtiniame CV (10 × 5 išorė) ΔSp taške Se ≥ 0,98 teigiamas ≥ 70 % skaidinių. H3 neatstoja H1; vykdoma **po** užrakinto testo.

Jei H1 atmetama, prototipo modeliu tampa logistinė regresija (arba tiesinis SVM, jei A2 geresnis). Tai validus rezultatas.

## Slenksčiai (tik iš OOF kalibruotų tikimybių)

- `thresholds.t_cost` = arg min EC(t), EC = 5·FN + 1·FP, t tinklelis 0,01.
- `thresholds.t_se98` = didžiausias t su OOF Se ≥ 0,98.
- `thresholds.t_youden` = arg max (Se + Sp − 1).
- Bajeso t* = 1/6 ≈ 0,167 (formulė 11) nenaudojamas kaip galutinis slenkstis.

## Metrikų lentelių forma (pildoma 4 etape, ne dabar)

- `reports/tables/main_results.csv` — modelis × veikimo taškas: Se, Sp, FN, FP, AUC, PI, BS.
- `reports/tables/hypotheses.csv` — H1, H2 sprendimai su PI.
- `reports/tables/ablation.csv` — A0, A2, A5, A7 su bootstrap 2000.
- Testas atrakinamas **lygiai vieną kartą** per `evaluate_test.m`. Šiame etape testas **užrakintas**.
