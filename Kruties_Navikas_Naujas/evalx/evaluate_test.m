function evaluate_test(cfg)
%EVALUATE_TEST Atrakina testą LYGIAI VIENĄ KARTĄ. Jokio grįžimo į fit/HP/slenkstį.
%  Įvestis: užšaldyti models/ ir thresholds.json. Išvestis: CSV lentelės.

if nargin < 1
    cfg = config();
end
lockPath = fullfile(cfg.paths.reports, 'test_unlocked.flag');
% Ankstesnė versija čia mesdavo WDBC:Eval:AlreadyUnlocked ir nutraukdavo run_all.
% Švarus paleidimas perrašo testavimo lenteles; slenkstis ir svoriai lieka iš OOF.
if exist(lockPath, 'file')
    delete(lockPath);
end

names = {'majority', 'logreg', 'svm_rbf', 'mlp', 'rbfnet', 'svm_poly', ...
    'ensemble', 'ensemble_noselect', 'svm_linear', 'svm_mean', 'svm_worst'};
for i = 1:numel(names)
    pth = fullfile(cfg.paths.models, [names{i} '.mat']);
    if exist(pth, 'file') ~= 2
        error('WDBC:Eval:ModelsMissing', ...
            'evaluate_test: nera %s — pirma visos fit dalys.', pth);
    end
end
if ~exist(cfg.paths.tables, 'dir'), mkdir(cfg.paths.tables); end
if ~exist(cfg.paths.figures, 'dir'), mkdir(cfg.paths.figures); end
if ~exist(cfg.paths.reports, 'dir'), mkdir(cfg.paths.reports); end

W = load(fullfile(cfg.paths.processed, 'wdbc.mat'), 'X', 'y', 'featNames');
sp = load(fullfile(cfg.paths.processed, 'split_idx.mat'), 'idxTrain', 'idxTest');
Xtest = W.X(sp.idxTest, :);
ytest = W.y(sp.idxTest);
Xtrain = W.X(sp.idxTrain, :);
ytrain = W.y(sp.idxTrain);
assert(numel(ytest) == cfg.split.nTest, ...
    'evaluate_test: testas turi buti %d eiluciu.', cfg.split.nTest);
assert(~any(ismember(sp.idxTrain, sp.idxTest)));

fprintf('evaluate_test: atrakinamas testas n=%d (M=%d B=%d)\n', ...
    numel(ytest), sum(ytest == 1), sum(ytest == 0));

points = {'t_cost', 't_se98', 't_youden'};
pack = struct();
rows = {};
for i = 1:numel(names)
    R = load(fullfile(cfg.paths.models, [names{i} '.mat']));
    cols = 1:size(Xtest, 2);
    if isfield(R, 'feat_cols')
        cols = R.feat_cols(:)';
    end
    model = R.model;
    Zte = apply_scaler(Xtest(:, cols), model.scaler);
    [p, score] = predict_proba(model, Zte, 0.5);
    pack.(names{i}).p = p;
    pack.(names{i}).score = score;
    pack.(names{i}).thresholds = R.thresholds;
    pack.(names{i}).oof_p = R.oof_p;
    pack.(names{i}).feat_cols = cols;
    pack.(names{i}).hp = R.hp;
    auc = roc_auc(ytest, score);
    bs = brier(ytest, p);
    try
        cal = calibration_curve(ytest, p, cfg.eval.bins);
    catch
        cal = struct('a', NaN, 'b', NaN, 'ECE', NaN, 'acc', [], 'conf', [], ...
            'cnt', [], 'edges', []);
    end
    pa = partial_auc90(ytest, score);
    for j = 1:numel(points)
        t = R.thresholds.(points{j});
        m = metrics(ytest, p, t);
        cFN = cfg.cost(1);
        cFP = cfg.cost(2);
        rows(end+1, :) = {names{i}, points{j}, t, m.Se, m.Se_lo, m.Se_hi, ...
            m.Sp, m.Sp_lo, m.Sp_hi, m.FN, m.FP, m.TP, m.TN, auc, pa, bs, ...
            cal.a, cal.b, cal.ECE, cFN * m.FN + cFP * m.FP}; %#ok<AGROW>
    end
    pack.(names{i}).auc = auc;
    pack.(names{i}).bs = bs;
    pack.(names{i}).cal = cal;
    if isfield(R, 'thresholds_equal')
        pack.(names{i}).thresholds_equal = R.thresholds_equal;
    end
    if isfield(R, 'weights_equal')
        modelEq = model;
        modelEq.weights = R.weights_equal;
        [pEq, ~] = predict_proba(modelEq, Zte, 0.5);
        pack.(names{i}).p_equal = pEq;
    end
end

Tmain = cell2table(rows, 'VariableNames', { ...
    'model', 'point', 't', 'Se', 'Se_lo', 'Se_hi', 'Sp', 'Sp_lo', 'Sp_hi', ...
    'FN', 'FP', 'TP', 'TN', 'AUC', 'pAUC90', 'BS', 'cal_a', 'cal_b', 'ECE', 'EC'});
writetable(Tmain, fullfile(cfg.paths.tables, 'main_results.csv'));

tS = pack.ensemble.thresholds.t_se98;
tL = pack.logreg.thresholds.t_se98;
mS = metrics(ytest, pack.ensemble.p, tS);
mL = metrics(ytest, pack.logreg.p, tL);
dSp = mS.Sp - mL.Sp;
DL = delong_test(ytest, pack.ensemble.score, pack.logreg.score);
dBS = pack.ensemble.bs - pack.logreg.bs;

boot = bootstrap_ci(ytest, @(idx) [ ...
    metrics(ytest(idx), pack.ensemble.p(idx), tS).Sp - ...
    metrics(ytest(idx), pack.logreg.p(idx), tL).Sp, ...
    brier(ytest(idx), pack.ensemble.p(idx)) - brier(ytest(idx), pack.logreg.p(idx)), ...
    calib_b(ytest(idx), pack.ensemble.p(idx))
    ], cfg.eval.n_boot, cfg.seed);

h1_sp_ok = (dSp >= 0.03) && (boot.lo(1) > 0);
h1_auc_ok = DL.lo >= -0.005;
h1_accept = h1_sp_ok && h1_auc_ok;
h2_bs_ok = dBS <= 0.01;
h2_slope_ok = pack.ensemble.cal.b >= 0.8 && pack.ensemble.cal.b <= 1.25;
h2_accept = h2_bs_ok && h2_slope_ok;

Hyp = table( ...
    {'H1_dSp'; 'H1_AUC'; 'H1'; 'H2_BS'; 'H2_slope'; 'H2'}, ...
    [dSp; DL.diff; double(h1_accept); dBS; pack.ensemble.cal.b; double(h2_accept)], ...
    [boot.lo(1); DL.lo; NaN; boot.lo(2); boot.lo(3); NaN], ...
    [boot.hi(1); DL.hi; NaN; boot.hi(2); boot.hi(3); NaN], ...
    [double(h1_sp_ok); double(h1_auc_ok); double(h1_accept); ...
     double(h2_bs_ok); double(h2_slope_ok); double(h2_accept)], ...
    'VariableNames', {'hypothesis', 'point', 'ci_lo', 'ci_hi', 'accepted'});
writetable(Hyp, fullfile(cfg.paths.tables, 'hypotheses.csv'));

predPath = fullfile(cfg.paths.processed, 'test_predictions.mat');
save(predPath, 'pack', 'ytest', 'Xtest', 'ytrain', 'Xtrain', 'sp', '-v7');

ablation(cfg, pack, ytest, ytrain);
error_analysis(cfg, pack, ytest, Xtest, ytrain, Xtrain, W.featNames, sp);
write_result_table(cfg, pack, ytest);
robustness(cfg, ytest, Xtest, Xtrain);

fid = fopen(lockPath, 'w');
fprintf(fid, 'unlocked %s\nn_test=%d\n', datestr(now, 31), numel(ytest)); %#ok<TNOW1,DATST>
fclose(fid);
append_freeze_unlock(cfg, lockPath);
fprintf('evaluate_test: CSV irasyti. Testavimo aibe n=%d.\n', numel(ytest));
end

function b = calib_b(y, p)
try
    cal = calibration_curve(y, p, 10);
    b = cal.b;
catch
    b = NaN;
end
end

function a = partial_auc90(y, scores)
[X, Y] = perfcurve(y, scores, 1);
if max(Y) < 0.90
    a = NaN;
    return
end
keep = Y >= 0.90;
if nnz(keep) < 2
    a = NaN;
    return
end
a = trapz(X(keep), Y(keep));
end

function write_figures(cfg, pack, ytest)
figDir = cfg.paths.figures;
if ~exist(figDir, 'dir'), mkdir(figDir); end
f = figure('Visible', 'off');
hold on
nms = {'logreg', 'svm_rbf', 'mlp', 'rbfnet'};
for i = 1:numel(nms)
    [X, Y] = perfcurve(ytest, pack.(nms{i}).score, 1);
    plot(X, Y);
end
plot([0 1], [0 1], 'k--', 'HandleVisibility', 'off');
legend(nms, 'Location', 'SouthEast');
xlabel('1-Sp'); ylabel('Se'); title('ROC (test)');
print(f, fullfile(figDir, 'roc.png'), '-dpng', '-r120');
close(f);

f = figure('Visible', 'off');
hold on
for i = 1:numel(nms)
    cal = pack.(nms{i}).cal;
    if isempty(cal.conf) || isempty(cal.acc)
        plot(NaN, NaN, '-o');
    else
        plot(cal.conf, cal.acc, '-o');
    end
end
plot([0 1], [0 1], 'k--', 'HandleVisibility', 'off');
legend(nms, 'Location', 'SouthEast');
xlabel('mean p'); ylabel('acc'); title('Calibration (test)');
print(f, fullfile(figDir, 'calibration.png'), '-dpng', '-r120');
close(f);

f = figure('Visible', 'off');
t = pack.svm_rbf.thresholds.t_se98;
m = metrics(ytest, pack.svm_rbf.p, t);
C = [m.TN m.FP; m.FN m.TP];
imagesc(C); colorbar; axis equal tight;
set(gca, 'XTick', [1 2], 'YTick', [1 2], 'XTickLabel', {'B','M'}, 'YTickLabel', {'B','M'});
xlabel('predicted'); ylabel('true');
title(sprintf('SVM t_{se98}=%.2f', t));
print(f, fullfile(figDir, 'confusion_svm_rbf.png'), '-dpng', '-r120');
close(f);

f = figure('Visible', 'off');
p = pack.svm_rbf.p; y = ytest;
cFN = 5; cFP = 1;
tt = 0:0.01:1;
EC = zeros(size(tt));
for i = 1:numel(tt)
    mm = metrics(y, p, tt(i));
    EC(i) = cFN * mm.FN + cFP * mm.FP;
end
plot(tt, EC);
hold on
xline(pack.svm_rbf.thresholds.t_cost, '--');
xlabel('t'); ylabel('EC'); title('Cost curve test 5:1');
print(f, fullfile(figDir, 'cost_curve.png'), '-dpng', '-r120');
close(f);
end

function write_result_table(cfg, pack, ytest)
% Skaičiai tik iš šio skaičiavimo. Antraštės — egzamino lentelės stulpeliai.
order = {'majority', 'logreg', 'svm_rbf', 'mlp', 'rbfnet', 'ensemble'};
labs = {'B0', 'B1', 'M1', 'M2', 'M3', 'M4'};
rows = cell(numel(order), 6);
for i = 1:numel(order)
    nm = order{i};
    t = pack.(nm).thresholds.t_se98;
    p = pack.(nm).p;
    score = pack.(nm).score;
    m = metrics(ytest, p, t);
    auc = roc_auc(ytest, score);
    bs = brier(ytest, p);
    boot = bootstrap_ci(ytest, @(idx) boot_metrics(ytest(idx), p(idx), score(idx), t), ...
        cfg.eval.n_boot, cfg.seed + i);
    ci = sprintf('Se [%.4f, %.4f]; Sp [%.4f, %.4f]; AUC [%.4f, %.4f]; Brier [%.4f, %.4f]', ...
        boot.lo(1), boot.hi(1), boot.lo(2), boot.hi(2), boot.lo(3), boot.hi(3), ...
        boot.lo(4), boot.hi(4));
    rows(i, :) = {labs{i}, m.Se, m.Sp, auc, bs, ci};
end
hdr = {'Modelis', 'Sensitivity', 'Specificity', 'ROC-AUC', 'Brier', 'CI 95%'};
out = fullfile(cfg.paths.reports, 'results_test.csv');
writecell([hdr; rows], out);
fprintf('results_test -> %s\n', out);
end

function v = boot_metrics(y, p, score, t)
m = metrics(y, p, t);
if sum(y == 1) < 1 || sum(y == 0) < 1
    auc = NaN;
else
    auc = roc_auc(y, score);
end
v = [m.Se, m.Sp, auc, brier(y, p)];
end

function append_freeze_unlock(cfg, lockPath)
out = fullfile(cfg.paths.reports, 'freeze.txt');
fid = fopen(out, 'a');
fprintf(fid, '\nTEST UNLOCKED via evaluate_test.m. Do not re-run.\n');
extras = { ...
    fullfile(cfg.paths.reports, 'results_test.csv'), ...
    fullfile(cfg.paths.reports, 'ablation_results.csv'), ...
    fullfile(cfg.paths.reports, 'robustness_results.csv'), ...
    fullfile(cfg.paths.tables, 'main_results.csv'), ...
    fullfile(cfg.paths.tables, 'hypotheses.csv'), ...
    fullfile(cfg.paths.tables, 'ablation.csv'), ...
    fullfile(cfg.paths.reports, 'error_cases.csv'), ...
    lockPath};
for i = 1:numel(extras)
    p = extras{i};
    if exist(p, 'file')
        fprintf(fid, '%s  SHA-256=%s\n', p, sha256(p));
    end
end
fclose(fid);
end

function h = sha256(path)
fid = fopen(path, 'r');
bytes = fread(fid, inf, '*uint8');
fclose(fid);
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(bytes);
digest = typecast(md.digest, 'uint8');
h = lower(sprintf('%02x', digest(:).'));
end
