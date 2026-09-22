function H = repeated_nested_cv(cfg)
%REPEATED_NESTED_CV H3: 10×5 išorė, viduje 5×5. PO testo; H1/slenksčių nekeičia.
%  Naudoja visą aibę naujiems išoriniams skaidiniams, ne užrakintą 113 testą.

if nargin < 1
    cfg = config();
end
W = load(fullfile(cfg.paths.processed, 'wdbc.mat'), 'X', 'y');
X = W.X; y = W.y(:);
nOut = 0;
dSp = [];
rng(cfg.seed + 99999, 'twister');
for r = 1:cfg.h3.outer_repeats
    cvp = cvpartition(y, 'KFold', cfg.h3.outer_k, 'Stratify', true);
    for f = 1:cfg.h3.outer_k
        nOut = nOut + 1;
        tr = training(cvp, f);
        va = test(cvp, f);
        idxTr = find(tr);
        idxVa = find(va);
        dummyTest = idxVa;
        cfgI = cfg;
        cfgI.seed = cfg.seed + 100000 * nOut;
        cvInner = make_inner_cv(y(idxTr), cfgI);
        resL = tune_cv(X(idxTr, :), y(idxTr), cvInner, cfgI, 'logreg', idxTr, dummyTest, ...
            sprintf('h3_lr_%d', nOut));
        resS = tune_cv(X(idxTr, :), y(idxTr), cvInner, cfgI, 'svm_rbf', idxTr, dummyTest, ...
            sprintf('h3_svm_%d', nOut));
        ZL = apply_scaler(X(idxVa, :), resL.model.scaler);
        ZS = apply_scaler(X(idxVa, :), resS.model.scaler);
        [pL, ~] = predict_proba(resL.model, ZL, resL.thresholds.t_se98);
        [pS, ~] = predict_proba(resS.model, ZS, resS.thresholds.t_se98);
        mL = metrics(y(idxVa), pL, resL.thresholds.t_se98);
        mS = metrics(y(idxVa), pS, resS.thresholds.t_se98);
        dSp(nOut, 1) = mS.Sp - mL.Sp; %#ok<AGROW>
        fprintf('H3 %d/%d dSp=%.4f\n', nOut, cfg.h3.outer_repeats * cfg.h3.outer_k, dSp(end));
        delete(resL.path);
        delete(resS.path);
    end
end
H.dSp = dSp;
H.frac_positive = mean(dSp > 0);
H.accept = H.frac_positive >= 0.70;
writetable(table(dSp, 'VariableNames', {'dSp_se98'}), ...
    fullfile(cfg.paths.tables, 'h3_nested.csv'));
save(fullfile(cfg.paths.processed, 'h3.mat'), 'H', '-v7');
append_h3_hypothesis(cfg, H);
end

function append_h3_hypothesis(cfg, H)
hypPath = fullfile(cfg.paths.tables, 'hypotheses.csv');
if exist(hypPath, 'file') ~= 2
    return
end
T = readtable(hypPath);
T(strcmp(T.hypothesis, 'H3_frac') | strcmp(T.hypothesis, 'H3'), :) = [];
row1 = { 'H3_frac', H.frac_positive, NaN, NaN, double(H.accept) };
row2 = { 'H3', double(H.accept), NaN, NaN, double(H.accept) };
add = cell2table([row1; row2], 'VariableNames', T.Properties.VariableNames);
T = [T; add];
writetable(T, hypPath);
end
