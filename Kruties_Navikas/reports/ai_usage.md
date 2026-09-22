# 7. AI naudojimo žurnalas

Taisyklė: AI tekstas ar citata savaime nėra įrodymas. Priimta tik tai, kas sutikrinta su planu, MATLAB išvestimi arba CSV.

| Užklausa AI | Priimta / Atmesta | Priežastis |
|---|---|---|
| Visas 5 etapų MATLAB vamzdis pagal planą (`config.m`, `run_all.m`, `data/`, `prep/`, `models/`, `evalx/`, `app/`, `tests/`) | Priimta (su korekcijomis žemiau) | Katalogų ir modulių vardai sutapo su 1/3/8 lentelėmis; paleista `run_all.m`, testai žali, `freeze.txt` + `test_unlocked.flag`. |
| Slenkstį ar HP rinkti pagal **testo** Se/Sp/AUC | **Atmesta** | Pažeistų nutekėjimo taisyklę. Patikrinta: `choose_threshold` / `tune_cv` gauna tik OOF/mokymą; `evaluate_test` lock draudžia antrą kvietimą (`WDBC:Eval:AlreadyUnlocked`). |
| `fit_scaler` ant visos 569×30 matricos | Atmesta | `test_no_leakage` ir `fit_scaler` klaida kai n = 569; scaler.mu tik iš 456 mokymo eilučių. |
| HoldOut 20 % = 114 test / 455 mokymas | Atmesta kaip „taisymas“ | AI/planas rašė ≈114/455. MATLAB `cvpartition` davė **113/456**. Priimta kaip natūrali išvestis, įrašyta į `preregistration.md`, nekirpta ranka. |
| Atmesti WDBC eilutes su nuliais `concavity` / `concave_points` | Atmesta | Oficialiame `wdbc.data` nulių yra; tai ne NaN. `load_wdbc` atmeta tik X < 0. Patikrinta: 569 eilutės, 212 M / 357 B. |
| HP rinkti nuosekliai „pirmas paprastas tinklelyje“ | **Atmesta (AI klaida #1)** | Žr. žemiau. |
| Formulių komentarai numeriais (6)–(24) iš 25 p. plano | **Atmesta (AI klaida #2)** | Žr. žemiau. |
| `t_cost` ≈ `t_se98` (0,33 vs 0,34) = programavimo klaida | Atmesta | OOF kreivė `oof_ec_se_curve.csv`: tas pats min EC, `t_se98` = paskutinis t su Se ≥ 0,98. Ne klaida. |
| H1 „SVM laimėjo, nes ΔSp didelis“ | Atmesta kaip išvada | `hypotheses.csv` eilutė `H1` `accepted=0`; krenta `H1_AUC` `ci_lo`. Analizėje H1 = ATMESTA. |
| Jei H1 atmesta, prototipas = linear SVM (A2) | Priimta kode kaip 4.1 skliaustas; egzamino promptas sako LR | Abu keliai užfiksuoti ataskaitoje; čia nekeičiami CSV. |
| App Designer `wdbc_app.mlapp` | Atmesta (neprivaloma) | Planas 8 lentelė: neprivaloma. Paliktas `predict_case.m`. |
| H3 automatiškai keičia H1 | Atmesta | H3 po testo; `hypotheses.csv` H1 neperrašyta. |
| `error_analysis` antraštėje dubliuoti `area_worst` ir visus 30 požymių | Atmesta po lūžio | Pirmas `evaluate_test` krito `Duplicate table variable name: 'area_worst'`. Pataisyta antraštė, testas atrakintas **vieną** kartą po pataisos (lock dar nebuvo). |

## Dvi konkretčios AI klaidos / nepatikrintos prielaidos

### 1. Hiperparametrų „pirmas paprastas“ vietoj max-AUC, tada ±0,002

AI į `tune_cv` pirmiausia įdėjo nuoseklų pasirinkimą: einant tinklu palikti pirmos konfigūracijos, jei paprastesnė, ir **nesulaukti viso tinklo maksimumo**. Pasekmė: būtų pasirinktos konfigūracijos su **žemesniu** OOF AUC nei maksimumas (pvz. SVM tinklo gale didelis C ir s).

Patikra: po viso 49 langelių SVM tinklo palyginti `aucMean`; taisyklė pakeista į „tarp visų, kurių AUC ≥ max−0,002, paprastesnis“. Peržiūrėtas `tune_cv.m` ciklas ir konsolės eilutės `tune_cv svm_rbf: geriausias AUC=…` prieš `evaluate_test`. Testo metrikos HP nekeičia.

### 2. Neteisinga formulių numeracija komentaruose

AI rašė MATLAB komentarus pagal 25 p. plano (6)–(24) numerius. Kolokviumo trumpasis planas naudoja (1) z-score, (2)–(3) RBF/SVM, (4) Platt, (5)–(6) slenkstis/EC, (7) Se/Sp, (8) AUC, (9) Brier.

Patikra: gretutinai atidarytas `Kolokviumo dalis.pdf` ir modulių antraštės (`fit_scaler`, `train_svm_rbf`, `calibrate_platt`, `choose_threshold`, `metrics`, `roc_auc`, `brier`). Komentarai perrašyti kolokviumo numeriais **prieš** testo atrakinimą. Skaičiai CSV nuo šios klaidos nepriklauso, bet egzamino „formulė ↔ kodas“ ryšys būtų buvęs klaidingas.

### Papildoma (implementacijos lūžis, ne statistikos išgalvojimas)

`error_analysis` antraštėje `area_worst` ir `concave_points_worst` kartojosi su `featNames` — MATLAB `cell2table` klaida. Patikra: `run_all` stack `error_analysis (line 44)`. Antraštė sutrumpinta; `test_unlocked.flag` tada dar neegzistavo, todėl antras `evaluate_test` nebuvo „pakartotas atrakintas testas“.
