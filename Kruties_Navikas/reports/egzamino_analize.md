# Rezultatų analizė, palyginimas ir ataskaita

WDBC dvejetainis klasifikavimas (M vs B), užrakintas testas n = 113. Šaltiniai: tik `reports/` CSV ir paveikslai. Skaičiai — lentelėse; tekste — nuoroda į eilutę/stulpelį. Jei stulpelio faile nėra — pažymėta kaip trūkumas, skaičius neišgalvotas.

**Modelių kodai:** B0 = `majority`, B1 = `logreg`, M1 = `svm_rbf`, M2 = `mlp`, M3 = `rbfnet`.

---

## 1. Rezultatų lentelė

Se ir Sp 95 % intervalai paimti iš `main_results.csv` stulpelių `Se_lo`, `Se_hi`, `Sp_lo`, `Sp_hi`. ROC-AUC ir Brier (`AUC`, `BS`) faile yra tik taškiniai įverčiai: **atskirų modelių 95 % bootstrap PI stulpelių AUC ir BS nėra** (`TRŪKSTA DUOMENŲ`; ΔAUC ir ΔBS PI yra `hypotheses.csv`, ne čia).

### B0 — daugumos klasė (`majority`)

| Taškas | t | Se | Se 95 % PI | Sp | Sp 95 % PI | FN | FP | AUC | BS |
|---|---:|---:|---|---:|---|---:|---:|---:|---:|
| t_cost | 0,50 | 0,0000 | [0,0000; 0,0838] | 1,0000 | [0,9487; 1,0000] | 42 | 0 | 0,5000 | 0,3717 |
| t_se98 | 0,50 | 0,0000 | [0,0000; 0,0838] | 1,0000 | [0,9487; 1,0000] | 42 | 0 | 0,5000 | 0,3717 |
| t_youden | 0,50 | 0,0000 | [0,0000; 0,0838] | 1,0000 | [0,9487; 1,0000] | 42 | 0 | 0,5000 | 0,3717 |

Šaltinis: `main_results.csv`, eilutės `majority` × `t_cost` / `t_se98` / `t_youden`.

### B1 — L2 logistinė regresija (`logreg`)

| Taškas | t | Se | Se 95 % PI | Sp | Sp 95 % PI | FN | FP | AUC | BS |
|---|---:|---:|---|---:|---|---:|---:|---:|---:|
| t_cost | 0,32 | 1,0000 | [0,9162; 1,0000] | 0,7183 | [0,6046; 0,8096] | 0 | 20 | 0,9883 | 0,0721 |
| t_se98 | 0,21 | 1,0000 | [0,9162; 1,0000] | 0,5634 | [0,4477; 0,6725] | 0 | 31 | 0,9883 | 0,0721 |
| t_youden | 0,32 | 1,0000 | [0,9162; 1,0000] | 0,7183 | [0,6046; 0,8096] | 0 | 20 | 0,9883 | 0,0721 |

Šaltinis: `main_results.csv`, eilutės `logreg` × trys taškai.

### M1 — SVM-RBF (`svm_rbf`)

| Taškas | t | Se | Se 95 % PI | Sp | Sp 95 % PI | FN | FP | AUC | BS |
|---|---:|---:|---|---:|---|---:|---:|---:|---:|
| t_cost | 0,33 | 0,9524 | [0,8421; 0,9868] | 0,9296 | [0,8455; 0,9695] | 2 | 5 | 0,9863 | 0,0430 |
| t_se98 | 0,34 | 0,9524 | [0,8421; 0,9868] | 0,9296 | [0,8455; 0,9695] | 2 | 5 | 0,9863 | 0,0430 |
| t_youden | 0,33 | 0,9524 | [0,8421; 0,9868] | 0,9296 | [0,8455; 0,9695] | 2 | 5 | 0,9863 | 0,0430 |

Šaltinis: `main_results.csv`, eilutės `svm_rbf` × trys taškai.

### M2 — MLP (`mlp`)

| Taškas | t | Se | Se 95 % PI | Sp | Sp 95 % PI | FN | FP | AUC | BS |
|---|---:|---:|---|---:|---|---:|---:|---:|---:|
| t_cost | 0,32 | 0,9286 | [0,8099; 0,9754] | 0,9859 | [0,9244; 0,9975] | 3 | 1 | 0,9933 | 0,0328 |
| t_se98 | 0,44 | 0,9286 | [0,8099; 0,9754] | 0,9859 | [0,9244; 0,9975] | 3 | 1 | 0,9933 | 0,0328 |
| t_youden | 0,54 | 0,9286 | [0,8099; 0,9754] | 0,9859 | [0,9244; 0,9975] | 3 | 1 | 0,9933 | 0,0328 |

Šaltinis: `main_results.csv`, eilutės `mlp` × trys taškai.

### M3 — RBF tinklas (`rbfnet`)

| Taškas | t | Se | Se 95 % PI | Sp | Sp 95 % PI | FN | FP | AUC | BS |
|---|---:|---:|---|---:|---|---:|---:|---:|---:|
| t_cost | 0,34 | 0,9524 | [0,8421; 0,9868] | 0,9296 | [0,8455; 0,9695] | 2 | 5 | 0,9755 | 0,0525 |
| t_se98 | 0,22 | 0,9524 | [0,8421; 0,9868] | 0,8873 | [0,7931; 0,9418] | 2 | 8 | 0,9755 | 0,0525 |
| t_youden | 0,34 | 0,9524 | [0,8421; 0,9868] | 0,9296 | [0,8455; 0,9695] | 2 | 5 | 0,9755 | 0,0525 |

Šaltinis: `main_results.csv`, eilutės `rbfnet` × trys taškai.

Papildoma kalibracija (taškiniai `cal_b`, `ECE`; bootstrap PI šiems stulpeliams `main_results.csv` nėra):

| Modelis | cal_b | ECE |
|---|---:|---:|
| majority | 0,0152 | 0,3717 |
| logreg | 2,6785 | 0,1376 |
| svm_rbf | 1,0973 | 0,0380 |
| mlp | 0,1826 | 0,0330 |
| rbfnet | 0,7359 | 0,0538 |

Šaltinis: `main_results.csv`, bet kuri eilutė to modelio (šios reikšmės nesikeičia keičiant `point`).

ROC kreivės teste visos keturios diskriminantės yra toli nuo įstrižainės (`reports/figures/roc.png`), kas atitinka aukštus `AUC` taškus lentelėje (`main_results.csv`, stulpelis `AUC`). Kalibracijos diagrama (`reports/figures/calibration.png`) su 10 intervalų ir n = 113 yra laiptuota; ECE skirtumus skaityti iš lentelės, ne iš vizualaus „gražumo“.

**Prieštaravimas planui.** OOF taisyklė `t_se98` turėjo duoti Se ≥ 0,98 teste; SVM-RBF tame taške to nesiekia (`main_results.csv`, eilutė `svm_rbf`, `t_se98`, stulpeliai `Se` ir `FN`), o LR siekia (`main_results.csv`, eilutė `logreg`, `t_se98`, stulpelis `Se`). Trys SVM-RBF veikimo taškai sutampa pagal Se/Sp/FN/FP (`main_results.csv`, trys `svm_rbf` eilutės) — slenksčiai OOF tinklelyje buvo gretimi, testas jų nebeatskiria.

---

## 2. H1 / H2 / H3

Preregistruota H1: taške `t_se98` ΔSp ≥ 0,03 **ir** bootstrap 95 % PI apatinė riba > 0, **ir** DeLong AUC skirtumo PI apačia ≥ −0,005 (`reports/preregistration.md`).

| Hipotezė | Taškas | ci_lo | ci_hi | accepted |
|---|---:|---:|---:|---:|
| H1_dSp | 0,3662 | 0,2568 | 0,4786 | 1 |
| H1_AUC | −0,0020 | −0,0074 | 0,0034 | 0 |
| H1 | 0 | — | — | **0** |
| H2_BS | −0,0291 | −0,0496 | −0,0078 | 1 |
| H2_slope | 1,0973 | 0,7893 | 2,7525 | 1 |
| H2 | 1 | — | — | **1** |
| H3_frac | 1 | — | — | 1 |
| H3 | 1 | — | — | **1** |

Šaltinis: `hypotheses.csv`, visos eilutės. `H3` eilutėse `ci_lo`/`ci_hi` faile yra tušti (`NaN`) — **H3 95 % PI TRŪKSTA DUOMENŲ** šiame faile.

**H1 ATMESTA** (`hypotheses.csv`, eilutė `H1`, stulpelis `accepted`). Tai **validus rezultatas**, kaip numatyta plano 4.1: neigiamas H1 nėra projekto nesėkmė. Pagal egzamino ir preregistracijos taisyklę prototipo modeliu tampa **logistinė regresija**.

ΔSp sąlyga **įvykdyta** (`hypotheses.csv`, eilutė `H1_dSp`: taškas ir `ci_lo` virš nulinės ir 0,03 ribos). H1 krenta ant **AUC neprastumo**: DeLong PI apatinė riba (`hypotheses.csv`, eilutė `H1_AUC`, stulpelis `ci_lo`) yra žemiau preregistruotos −0,005. Taškinis AUC skirtumas vis dar mažesnis už 0,005 absoliučiu dydžiu, bet intervalas neleidžia priimti konjunkcijos.

**Kritinis prieštaravimas planui.** Planas 4.1 prognozavo: jei klasės beveik tiesiškai atskiriamos, ΔSp bus ~0 arba neigiamas. Faktas priešingas ΔSp daliai (`hypotheses.csv`, `H1_dSp`) ir sutampa su lubų efektu AUC dalyje (`hypotheses.csv`, `H1_AUC`; `main_results.csv`, `logreg` ir `svm_rbf` stulpelis `AUC`). H1 buvo konjunkcija; vienos sąlygos sėkmė kitos neatstoja.

**H2 PRIIMTA** (`hypotheses.csv`, eilutė `H2`). ΔBS ženklas palankus SVM (`hypotheses.csv`, `H2_BS`), nuolydžio taškas arti 1 (`hypotheses.csv`, `H2_slope`). Nuolydžio PI platus ir išeina už [0,8; 1,25] viršutinės pusės (`hypotheses.csv`, `H2_slope`, `ci_hi`) — priėmimas čia reiškia sankirtą su [0,8; 1,25], ne intervalo sutalpinimą. Tai mažo testo, ne „idealios kalibracijos“, požymis.

**H3 PRIIMTA** (`hypotheses.csv`, eilutė `H3`) kaip papildomas ΔSp stabilumo testas po užrakinto testo; H3 **neatstoja** H1.

---

## 3. Abliacija

### A0 — dauguma

| id | Se | Sp | AUC | FN | FP |
|---|---:|---:|---:|---:|---:|
| A0 majority_t05 | 0 | 1 | 0,5000 | 42 | 0 |

Šaltinis: `ablation.csv`, eilutė `A0`. Metrikos sutampa su B0 (`main_results.csv`, `majority`): grandinė skaičiuoja Se/Sp/AUC taip, kaip planuota. Accuracy čia būtų klaidinanti metrika, nes visos M praleidžiamos.

### A2 — linear SVM vs RBF (t_se98)

| setting | t | Se | Sp | Sp 95 % PI | FN | FP | AUC | BS | EC_or_delta (ΔSp) | dSp PI |
|---|---:|---:|---:|---|---:|---:|---:|---:|---:|---|
| svm_rbf_tse98 | 0,34 | 0,9524 | 0,9296 | [0,8455; 0,9695] | 2 | 5 | 0,9863 | 0,0430 | +0,0423 | [−0,0294; 0,1111] |
| svm_linear_tse98 | 0,16 | 0,9762 | 0,8873 | [0,7931; 0,9418] | 1 | 8 | 0,9953 | 0,0312 | −0,0423 | [−0,1111; 0,0294] |

Šaltinis: `ablation.csv`, eilutės `A2`.

**Lubų efektas (netiesinio branduolio nauda).** Planas: jei klasės tiesiškai atskiriamos, RBF AUC/Sp nepranoks linijinio. **AUC dalis patvirtinta:** linear taškinis AUC didesnis nei RBF (`ablation.csv`, A2, stulpelis `AUC`; tas pats `main_results.csv`, `svm_linear` vs `svm_rbf`). **Sp dalis neįrodyta:** RBF taškinis ΔSp teigiamas, bet bootstrap PI kerta nulį (`ablation.csv`, eilutė `svm_rbf_tse98`, stulpeliai `dSp_lo`, `dSp_hi`). RBF čia nėra statistiškai įrodytas Sp pranašumas prieš linear.

### A5 — mean10 / worst10 / all30 (t_se98)

| setting | t | Se | Sp | Sp 95 % PI | FN | FP | AUC | BS |
|---|---:|---:|---:|---|---:|---:|---:|---:|
| mean10 | 0,08 | 0,9762 | 0,7183 | [0,6148; 0,8194] | 1 | 20 | 0,9745 | 0,0619 |
| worst10 | 0,09 | 1,0000 | 0,8732 | [0,8000; 0,9452] | 0 | 9 | 0,9963 | 0,0249 |
| all30 | 0,34 | 0,9524 | 0,9296 | [0,8644; 0,9855] | 2 | 5 | 0,9863 | 0,0430 |

Šaltinis: `ablation.csv`, eilutės `A5`. A5 `dSp_lo`/`dSp_hi` šiame faile yra **to modelio Sp PI**, ne ΔSp (stulpelių pavadinimai persidengia su A2).

Planas rėmėsi tuo, kad originaliame darbe pakako „worst“ statistikų. **Patvirtinta diskriminacijai:** `worst10` turi aukščiausią taškinį AUC ir nulinį FN šiame teste (`ablation.csv`, `worst10_tse98`). **Ne visai patvirtinta kaip H1 pakaitalas:** `all30` turi mažiau FP ir aukštesnį Sp (`ablation.csv`, `all30_tse98` vs `worst10`). `mean10` Sp yra silpniausias iš trijų. Lubų efektą tai papildo: 10 „worst“ požymių jau duoda AUC lubas; 30 požymių nepakelia AUC virš `worst10`.

### A7 — kainų santykis (t_cost iš OOF, metrikos teste)

| id | t | Se | Sp | FN | FP | EC_or_delta |
|---|---:|---:|---:|---:|---:|---:|
| A7_1_1 | 0,33 | 0,9524 | 0,9296 | 2 | 5 | 7 |
| A7_3_1 | 0,33 | 0,9524 | 0,9296 | 2 | 5 | 11 |
| A7_5_1 | 0,33 | 0,9524 | 0,9296 | 2 | 5 | 15 |
| A7_10_1 | 0,33 | 0,9524 | 0,9296 | 2 | 5 | 25 |

Šaltinis: `ablation.csv`, eilutės `A7_*`. Se/Sp PI šiose eilutėse yra bootstrap (`Se_lo`…`Sp_hi`); `dSp_lo`/`dSp_hi` tušti.

**Prieštaravimas planui.** Planas 1.4/A7 tikėjosi, kad keičiant c_FN : c_FP slenkstis ir FN/FP pasislinks. Fakte OOF `t_cost` visiems keturiems santykiams sutapo, todėl teste FN ir FP identiški (`ablation.csv`, visos `A7_*` eilutės, stulpeliai `t`, `FN`, `FP`). Keičiasi tik perskaičiuota kaina `EC_or_delta`. Atsparumo bandymas kainai čia parodė **ne slenksčio jautrumą, o tos pačios painiavos persvėrimą**.

---

## 4. Klaidų analizė (SVM-RBF, t_se98)

Profilio santrauka (`error_profile.txt`): FN = 2, FP = 5, t = 0,34. Mokymo medianos M/B ir klaidų medianos ten pat. Žemiau — visos `error_cases.csv` eilutės; tipiškumui išskirti 2 FN ir 3 FP.

| tipas | abs_idx | p | dist_to_t | concave_points_worst | area_worst | cp − medM | ar − medM | cp − medB | ar − medB |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| FN | 41 | 0,0479 | 0,2921 | 0,1112 | 787,9 | −0,0715 | −544,6 | +0,0371 | +239,5 |
| FN | 264 | 0,2138 | 0,1262 | 0,0857 | 988,6 | −0,0970 | −343,9 | +0,0116 | +440,2 |
| FP | 69 | 0,7762 | 0,4362 | 0,1750 | 324,7 | −0,0077 | −1007,8 | +0,1009 | −223,8 |
| FP | 82 | 0,5083 | 0,1683 | 0,1708 | 614,9 | −0,0119 | −717,6 | +0,0967 | +66,4 |
| FP | 153 | 0,8043 | 0,4643 | 0,1571 | 380,5 | −0,0256 | −952,0 | +0,0830 | −168,0 |
| FP | 291 | 0,4462 | 0,1062 | 0,1021 | 767,3 | −0,0806 | −565,2 | +0,0280 | +218,9 |
| FP | 466 | 0,3846 | 0,0446 | 0,1357 | 733,5 | −0,0470 | −599,0 | +0,0616 | +185,1 |

Šaltinis: `error_cases.csv` visos eilutės; medianų atskaitos — `error_profile.txt`.

Ribinis atvejis pagal planą: |p − t| < 0,10. Tokia yra tik FP eilutė `abs_idx=466` (`error_cases.csv`). FN `41` ir `264` yra **toli nuo slenksčio** (`dist_to_t` virš 0,10) — tai ne „vos neperžengė t“, o **sisteminė** spraga: abu piktybiniai turi `concave_points_worst` ir `area_worst` žemiau mokymo M medianos ir arčiau B (`error_cases.csv`, stulpeliai `cp_minus_medM`, `ar_minus_medM`; `error_profile.txt` M/B medianos).

FP `69` ir `153` turi **mažą plotą** (žemiau B medianos) bet **aukštus įgaubtus taškus** (arti M medianos) ir aukštą p (`error_cases.csv`). Tai kitos rūšies sisteminė klaida: formos požymis traukia į M, dydis — į B. SVM-RBF čia ne „ribinis slenksčio triukšmas“, o prieštaringų požymių zona.

---

## 5. Kodėl SVM-RBF nepranoko LR pagal H1

H1 reikalavo ne „geresnio modelio apskritai“, o konjunkcijos aukšto Se taške **ir** AUC neprastumo (`preregistration.md`; `hypotheses.csv`, `H1`).

Diskriminacijos reitingas (slenksčio nepriklausomas) palankesnis LR ir MLP nei SVM-RBF (`main_results.csv`, stulpelis `AUC`: `mlp` > `logreg` > `svm_rbf` > `rbfnet`). Veikimo taške `t_se98` vaizdas kitoks: LR turi nulinį FN ir daug FP, SVM-RBF — atvirkščiai (`main_results.csv`, eilutės `logreg` ir `svm_rbf` prie `t_se98`, stulpeliai `FN`, `FP`, `Sp`). Todėl ΔSp didelis ir bootstrap PI toli nuo nulio (`hypotheses.csv`, `H1_dSp`), bet DeLong vis tiek neatmeta, kad LR reitingas visoje ROC nėra prastesnis už SVM daugiau nei leidžia 0,005 atsarga (`hypotheses.csv`, `H1_AUC`).

Tai sutampa su duomenų savybėmis, kurias planas įvardijo kaip lubas: 30 koreliuotų branduolių matų, n_test piktybinių = FN+TP iš painiavos (`main_results.csv`, `svm_rbf` `t_se98`: FN ir TP), klasių disbalansas (B0 visada B, `majority` eilutė). RBF branduolys tokioje erdvėje nepakėlė AUC virš linijinių metodų (`ablation.csv`, A2 `AUC`; `main_results.csv`, `svm_linear` vs `svm_rbf`). Jis pakeitė **klaidų balansą** (mažiau FP, daugiau FN), o H1 AUC sąlyga būtent to nepriima kaip „pranokimo“.

---

## 6. Sprendimo ribos, rizika, praktinis tinkamumas

Planas 1.4 ir 6.5 įspėjo: mažas testas, Wilson/bootstrap plotis, PPV/NPV neperkeliami, FN brangesni už FP, prototipas nėra klinikinė diagnozė. Žemiau — tas pats, bet pagal faktines eilutes.

**Mažas M skaičius teste.** Kiekvienoje `main_results.csv` eilutėje FN+TP = 42 (pvz. `svm_rbf`, `t_se98`). Vienas FN keičia Se grubiai 1/42; tai matyti iš Se PI pločio (`main_results.csv`, `svm_rbf` `t_se98`, `Se_lo` vs `Se_hi` vs `logreg` to paties taško `Se_lo`). H1_AUC DeLong PI kerta tiek nulį, tiek −0,005 (`hypotheses.csv`, `H1_AUC`) — neapibrėžtis pakankama, kad konjunkcija kristų, net kai ΔSp atrodo didelis.

**Se tikslas teste.** OOF Se ≥ 0,98 neneša garantijos į testą (`main_results.csv`, `svm_rbf` `t_se98` vs `logreg` `t_se98`). Prototipas, jei vis tiek būtų paliktas SVM, praleistų FN eilutes `41` ir `264` (`error_cases.csv`) — abu „maži, lygesni“ piktybiniai. Plano 6.5 klausimas „kada reikia žmogaus“: toli nuo t esantys FN **neužstringa** `margin_flag` taisyklėje |p−t|<0,10 (`error_cases.csv`, `dist_to_t`). Tai **siauresnė** apsauga, nei planas tikėjosi.

**PPV / NPV.** `main_results.csv` ir `ablation.csv` **neturi** stulpelių PPV ir NPV (`TRŪKSTA DUOMENŲ` kaip atskirų metrikų). Yra TP, FP, TN, FN, iš kurių PPV būtų skaičiuojamas, bet WDBC paplitimas (testo M dalis = 42/113 iš painiavos stulpelių) **nėra** klinikinis paplitimas (planas 1.4). Todėl net turint TP/FP, PPV į praktiką neperkeliama: keičiant paplitimą keičiasi PPV, Se/Sp — ne. Praktikoje lieka Se/Sp/AUC ir kaina, ne „teigiamos prognozės tikimybė iš WDBC“.

**Kainų taisyklė.** A7 parodė, kad 1:1…10:1 **nekeitė** FN/FP (`ablation.csv`, `A7_*`). 5:1 čia ne „išgelbėjo“ daugiau M nei 1:1 tame pačiame OOF `t_cost`. Rizika: konfigūracijos c_FN:c_FP jautrumo analizė šiame rinkinyje silpna, nes modelis jau pastumtas į platų Se intervalą.

**Kalibracija praktikai.** H2 priimta, bet `cal_b` PI platus (`hypotheses.csv`, `H2_slope`) ir LR `cal_b` toli nuo 1 (`main_results.csv`, `logreg`, `cal_b`). Tikimybės kaip „rizikos procentas“ vartotojui būtų perinterpretuotos; prototipo privalomas tekstas lieka: rezultatas nėra klinikinė diagnozė.

**Kas lieka prototipui.** H1 atmesta → pagal 4.1 ir šio egzamino formuluotę pagrindinis modelis yra **logistinė regresija** (`hypotheses.csv`, `H1`; `main_results.csv`, `logreg` `t_se98`: nulinis FN, didelis FP). Linear SVM A2 turi aukštesnį AUC ir mažiau FP nei LR tame pačiame H1 taške (`ablation.csv`, `svm_linear_tse98` vs `main_results.csv`, `logreg` `t_se98`) — plano 4.1 skliaustas „arba linear, jei A2 geresnis“ čia yra pagrįstas **diskriminacija**, bet egzamino promptas prototipui fiksuoja LR. Abu keliai dokumentuotini kaip H1 atmetimo pasekmė, ne kaip „SVM laimėjo“.

**Išorinė kohorta.** Šiame `reports/` rinkinyje nėra kitos laboratorijos testo (`TRŪKSTA DUOMENŲ`). Visi skaičiai — vienas 1990-ųjų FNA centras, vienas 80/20 skaidinys plius H3 vidiniai perskaidymai tos pačios aibės (`hypotheses.csv`, `H3`).
