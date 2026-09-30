Svarbiausi:

run_all.m – visos grandinės paleidimas iš eilės.

make_report_plots.m – ataskaitos grafikai iš užšaldytų prognozių.

-----------------------------------------------------------------------------------------------

mlp_backprop_manual.m – rankinis atgalinis sklidimas: išėjimo formulė ir svorių atnaujinimas.

train_mlp.m – produkcinis MLP mokymas (patternnet, trainscg).

train_svm_rbf.m – RBF branduolio SVM mokymas.

train_svm_poly.m – polinominio branduolio SVM mokymas.

svm_poly_score.m – polinominio SVM sprendimo funkcija f(z).

train_rbfnet.m – RBF tinklo centrai ir išėjimo svoriai.

train_logreg.m – L2 logistinė regresija.

train_majority.m – daugumos klasės atskaita.

train_ensemble.m – M4 ansamblis: polinominis SVM, MLP ir logistinė regresija, OOF svoriai ir slenkstis.

lr_gradient_descent.m – rankinis logistinės regresijos gradientas.

class_weights.m – klasių svoriai pagal klaidų kainą.

predict_proba.m – tikimybių skaičiavimas visiems modeliams.

calibrate_platt.m – balų kalibracija į tikimybes.

platt_apply.m – išmokytos Platt sigmoidės pritaikymas.

choose_threshold.m – sprendimo slenksčio parinkimas iš OOF.

tune_cv.m – hiperparametrų paieška vidiniame CV.

evaluate_test.m – testo įvertinimas ir rezultatų lentelės.

ablation.m – abliacijos tame pačiame teste.

robustness.m – atsparumas triukšmui ir trūkstamoms reikšmėms.

error_analysis.m – klaidingai neigiamų ir klaidingai teigiamų atvejų analizė.

bootstrap_ci.m – pasikliautinieji intervalai.

delong_test.m – AUC skirtumo DeLong testas.

metrics.m, roc_auc.m, brier.m – jautrumas, specifiškumas, ROC-AUC ir Brier įvertis.

calibration_curve.m – kalibracijos kreivė.

repeated_nested_cv.m – kartojama įdėtinė kryžminė patikra.



write_exam_figures.m – ROC, kalibracijos ir klaidų pasiskirstymo grafikai.

make_split.m / make_inner_cv.m – išorinis 455/114 skaidymas ir vidinis CV.

fit_scaler.m / apply_scaler.m – normavimas tik iš mokymo duomenų.

select_features.m – požymių atranka, kai |r| > 0,95.

get_wdbc.m / load_wdbc.m – duomenų atsisiuntimas ir patikra.

predict_case.m – vieno naujo atvejo prognozė.



config.m – visi fiksuoti nustatymai.
