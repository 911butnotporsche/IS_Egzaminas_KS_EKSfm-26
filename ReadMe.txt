mlp_backprop_manual.m – rankinis atgalinis sklidimas: išėjimo formulė ir svorių atnaujinimas.

train_mlp.m – produkcinis MLP mokymas (patternnet, trainscg).

train_svm_rbf.m – pagrindinio SVM-RBF modelio mokymas.

train_rbfnet.m – RBF tinklo centrai ir išėjimo svoriai.

calibrate_platt.m – SVM balų kalibracija į tikimybes.

choose_threshold.m – sprendimo slenksčio parinkimas.

evaluate_test.m – testo atrakinimas, vienintelis įvertinimas.

make_split.m / fit_scaler.m / apply_scaler.m – duomenų padalinimas ir normavimas be nutekėjimo.

tune_cv.m – hiperparametrų paieška vidiniame CV.

metrics.m, roc_auc.m, delong_test.m, brier.m – metrikų skaičiavimas.

get_wdbc.m / load_wdbc.m – duomenų atsisiuntimas ir patikra.

ablation.m, error_analysis.m – papildomi eksperimentai ir klaidų analizė.

predict_case.m – vieno naujo atvejo prognozė.

run_all.m – visos grandinės paleidimas iš eilės.

config.m – visi fiksuoti nustatymai.

tests/ – automatiniai patikros testai