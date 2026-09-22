function evaluate_test(cfg)
%EVALUATE_TEST Atrakina testą LYGIAI VIENĄ KARTĄ. Jokio grįžimo į fit/HP/slenkstį.
%  Įvestis: užšaldyti models/ ir thresholds.json. Išvestis: CSV lentelės.

if nargin < 1
    cfg = config();
end
lockPath = fullfile(cfg.paths.reports, 'test_unlocked.flag');
if exist(lockPath, 'file')
    error('WDBC:Eval:AlreadyUnlocked', ...
        'evaluate_test: testas jau atrakintas. Antras kvietimas draudziamas.');
end

names = {'majority', 'logreg', 'svm_rbf', 'mlp', 'rbfnet', ...
    'svm_linear', 'svm_mean', 'svm_worst'};
for i = 1:numel(names)
    pth = fullfile(cfg.paths.models, [names{i} '.mat']);
    if exist(pth, 'file') ~= 2
        error('evaluate_test: nera %s — pirma visos fit dalys.', pth);
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
assert(numel(ytest) == 113, 'evaluate_test: testas turi buti 113 eiluciu.');
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
end

Tmain = cell2table(rows, 'VariableNames', { ...
    'model', 'point', 't', 'Se', 'Se_lo', 'Se_hi', 'Sp', 'Sp_lo', 'Sp_hi', ...
    'FN', 'FP', 'TP', 'TN', 'AUC', 'pAUC90', 'BS', 'cal_a', 'cal_b', 'ECE', 'EC'});
writetable(Tmain, fullfile(cfg.paths.tables, 'main_results.csv'));

tS = pack.svm_rbf.thresholds.t_se98;
tL = pack.logreg.thresholds.t_se98;
mS = metrics(ytest, pack.svm_rbf.p, tS);
mL = metrics(ytest, pack.logreg.p, tL);
dSp = mS.Sp - mL.Sp;
DL = delong_test(ytest, pack.svm_rbf.score, pack.logreg.score);
dBS = pack.svm_rbf.bs - pack.logreg.bs;

boot = bootstrap_ci(ytest, @(idx) [ ...
    metrics(ytest(idx), pack.svm_rbf.p(idx), tS).Sp - ...
    metrics(ytest(idx), pack.logreg.p(idx), tL).Sp, ...
    brier(ytest(idx), pack.svm_rbf.p(idx)) - brier(ytest(idx), pack.logreg.p(idx)), ...
    calib_b(ytest(idx), pack.svm_rbf.p(idx))
    ], cfg.eval.n_boot, cfg.seed);

h1_sp_ok = (dSp >= 0.03) && (boot.lo(1) > 0);
h1_auc_ok = DL.lo >= -0.005;
h1_accept = h1_sp_ok && h1_auc_ok;
h2_bs_ok = dBS <= 0.01;
h2_slope_ok = (boot.hi(3) >= 0.8) && (boot.lo(3) <= 1.25);
h2_accept = h2_bs_ok && h2_slope_ok;

Hyp = table( ...
    {'H1_dSp'; 'H1_AUC'; 'H1'; 'H2_BS'; 'H2_slope'; 'H2'}, ...
    [dSp; DL.diff; double(h1_accept); dBS; pack.svm_rbf.cal.b; double(h2_accept)], ...
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
try
    write_figures(cfg, pack, ytest);
catch ME
    warning('evaluate_test: paveikslai neirasyti: %s', ME.message);
end

fid = fopen(lockPath, 'w');
fprintf(fid, 'unlocked %s\nn_test=%d\n', datestr(now, 31), numel(ytest)); %#ok<TNOW1,DATST>
fclose(fid);
append_freeze_unlock(cfg, lockPath);
fprintf('evaluate_test: CSV irasyti. Antras kvietimas bus atmestas.\n');
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

function append_freeze_unlock(cfg, lockPath)
out = fullfile(cfg.paths.reports, 'freeze.txt');
fid = fopen(out, 'a');
fprintf(fid, '\nTEST UNLOCKED via evaluate_test.m. Do not re-run.\n');
extras = { ...
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
