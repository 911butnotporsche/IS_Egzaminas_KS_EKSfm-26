function ablation(cfg, pack, ytest, ytrain)
%ABLATION A0, A2, A5, A7. Testo p jau apskaiciuoti evaluate_test; HP/slenksčiai iš OOF.
%  Bootstrap 2000. H1 nekeičia.

nBoot = cfg.eval.n_boot;
rows = {};

% A0 — dauguma, t=0.5: Se=0, Sp=1, AUC=0.5
m0 = metrics(ytest, pack.majority.p, 0.5);
auc0 = roc_auc(ytest, pack.majority.score);
rows(end+1, :) = arow('A0', 'majority_t05', 0.5, m0, auc0, brier(ytest, pack.majority.p), NaN, NaN, NaN, NaN); %#ok<AGROW>

% A2 — linear vs RBF, t_se98
tR = pack.svm_rbf.thresholds.t_se98;
tL = pack.svm_linear.thresholds.t_se98;
mR = metrics(ytest, pack.svm_rbf.p, tR);
mLin = metrics(ytest, pack.svm_linear.p, tL);
aucR = pack.svm_rbf.auc;
aucLin = pack.svm_linear.auc;
dSp = mR.Sp - mLin.Sp;
bootA2 = bootstrap_ci(ytest, @(idx) [ ...
    metrics(ytest(idx), pack.svm_rbf.p(idx), tR).Sp - ...
    metrics(ytest(idx), pack.svm_linear.p(idx), tL).Sp, ...
    safe_auc(ytest(idx), pack.svm_rbf.score(idx)) - ...
    safe_auc(ytest(idx), pack.svm_linear.score(idx))
    ], nBoot, cfg.seed);
rows(end+1, :) = arow('A2', 'svm_rbf_tse98', tR, mR, aucR, pack.svm_rbf.bs, dSp, bootA2.lo(1), bootA2.hi(1), NaN); %#ok<AGROW>
rows(end+1, :) = arow('A2', 'svm_linear_tse98', tL, mLin, aucLin, pack.svm_linear.bs, -dSp, -bootA2.hi(1), -bootA2.lo(1), NaN);

% A5 — mean / worst / all
sets = {'svm_mean', 'svm_worst', 'svm_rbf'};
labs = {'mean10', 'worst10', 'all30'};
for i = 1:3
    nm = sets{i};
    t = pack.(nm).thresholds.t_se98;
    mm = metrics(ytest, pack.(nm).p, t);
    boot = bootstrap_ci(ytest, @(idx) [ ...
        metrics(ytest(idx), pack.(nm).p(idx), t).Sp, ...
        safe_auc(ytest(idx), pack.(nm).score(idx))
        ], nBoot, cfg.seed);
    rows(end+1, :) = arow('A5', [labs{i} '_tse98'], t, mm, pack.(nm).auc, ...
        brier(ytest, pack.(nm).p), NaN, boot.lo(1), boot.hi(1), boot.lo(2)); %#ok<AGROW>
end

% A7 — kainų santykis: slenkstis iš OOF, metrikos teste
ratios = [1 3 5 10];
pOof = pack.svm_rbf.oof_p;
pTe = pack.svm_rbf.p;
for i = 1:numel(ratios)
    cfgC = cfg;
    cfgC.cost = [ratios(i), 1];
    thr = choose_threshold(pOof, ytrain, cfgC);
    mm = metrics(ytest, pTe, thr.t_cost);
    EC = ratios(i) * mm.FN + 1 * mm.FP;
    boot = bootstrap_ci(ytest, @(idx) [ ...
        metrics(ytest(idx), pTe(idx), thr.t_cost).Se, ...
        metrics(ytest(idx), pTe(idx), thr.t_cost).Sp
        ], nBoot, cfg.seed);
    rows(end+1, :) = {sprintf('A7_%d_1', ratios(i)), 'svm_t_cost', thr.t_cost, ...
        mm.Se, boot.lo(1), boot.hi(1), mm.Sp, boot.lo(2), boot.hi(2), ...
        mm.FN, mm.FP, pack.svm_rbf.auc, pack.svm_rbf.bs, EC, NaN, NaN}; %#ok<AGROW>
end

Tab = cell2table(rows, 'VariableNames', { ...
    'id', 'setting', 't', 'Se', 'Se_lo', 'Se_hi', 'Sp', 'Sp_lo', 'Sp_hi', ...
    'FN', 'FP', 'AUC', 'BS', 'EC_or_delta', 'dSp_lo', 'dSp_hi'});
writetable(Tab, fullfile(cfg.paths.tables, 'ablation.csv'));
end

function row = arow(id, setting, t, m, auc, bs, extra, lo, hi, extra2)
if nargin < 10, extra2 = NaN; end %#ok<NASGU>
row = {id, setting, t, m.Se, m.Se_lo, m.Se_hi, m.Sp, m.Sp_lo, m.Sp_hi, ...
    m.FN, m.FP, auc, bs, extra, lo, hi};
end

function a = safe_auc(y, s)
if sum(y == 1) < 1 || sum(y == 0) < 1
    a = NaN;
    return
end
a = roc_auc(y, s);
end
