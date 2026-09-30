function make_report_plots()
%MAKE_REPORT_PLOTS Grafikai tik iš run_all rezultatų.
%  Skaito reports/results_test.csv (VariableNamingRule preserve) ir
%  data/processed/test_predictions.mat. Modelių nebemoko.

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'evalx'));
addpath(fullfile(root, 'models'));
addpath(fullfile(root, 'prep'));
figDir = fullfile(root, 'reports', 'figures');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
predFile = fullfile(root, 'data', 'processed', 'test_predictions.mat');
resFile = fullfile(root, 'reports', 'results_test.csv');
errFile = fullfile(root, 'reports', 'error_cases.csv');
wdbcFile = fullfile(root, 'data', 'processed', 'wdbc.mat');
for f = {predFile, resFile, errFile, wdbcFile}
    if exist(f{1}, 'file') ~= 2
        error('make_report_plots: nera %s. Pirma paleiskite run_all.', f{1});
    end
end

S = load(predFile, 'pack', 'ytest', 'Xtest', 'ytrain', 'Xtrain');
W = load(wdbcFile, 'featNames');
featNames = W.featNames;
if isrow(featNames)
    featNames = featNames(:)';
end
if isstring(featNames) || ischar(featNames)
    featNames = cellstr(featNames);
end
ytest = S.ytest(:);
pack = S.pack;
res = readtable(resFile, 'TextType', 'string', 'VariableNamingRule', 'preserve');
ixCP = find(strcmp(featNames, 'concave_points_worst'), 1);
if isempty(ixCP)
    error('make_report_plots: nera concave_points_worst.');
end

set(0, 'DefaultAxesFontSize', 12);
set(0, 'DefaultTextFontSize', 12);

plot_roc_comparison(figDir, pack, ytest, res);
plot_calibration(figDir, pack, ytest);
plot_fn(figDir, pack, ytest, S.Xtest, S.ytrain, S.Xtrain, ixCP);
plot_confusion_set(figDir, pack, ytest);
plot_cost(figDir, pack, ytest);
fprintf('make_report_plots: irasyta i %s\n', figDir);
end

function plot_roc_comparison(figDir, pack, ytest, res)
names = {'logreg', 'svm_rbf', 'mlp', 'rbfnet', 'ensemble'};
labs = {'B1', 'M1', 'M2', 'M3', 'M4'};
ids = {'B1', 'M1', 'M2', 'M3', 'M4'};
colors = [0.85 0.33 0.10; 0.93 0.69 0.13; 0.49 0.18 0.56; 0.47 0.67 0.19; 0.00 0.45 0.74];
f = figure('Visible', 'off', 'Color', 'w', 'Position', [80 80 1100 520]);
tl = tiledlayout(f, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
ax = nexttile(tl);
axz = nexttile(tl);
hold(ax, 'on');
hold(axz, 'on');
plot(ax, [0 1], [0 1], 'k--', 'LineWidth', 1, 'DisplayName', 'B0 (AUC = 0,5)');
for i = 1:numel(names)
    [x, y, ~, auc] = perfcurve(ytest, pack.(names{i}).score, 1);
    plot(ax, x, y, 'LineWidth', 1.6, 'Color', colors(i, :), ...
        'DisplayName', sprintf('%s, AUC = %.3f', labs{i}, auc));
    plot(axz, x, y, 'LineWidth', 1.8, 'Color', colors(i, :), 'HandleVisibility', 'off');
    t = pack.(names{i}).thresholds.t_se98;
    m = metrics(ytest, pack.(names{i}).p, t);
    csvSe = csv_metric(res, ids{i}, 'Sensitivity');
    csvSp = csv_metric(res, ids{i}, 'Specificity');
    if abs(m.Se - csvSe) > 1e-9 || abs(m.Sp - csvSp) > 1e-9
        error('make_report_plots: %s taskas nesutampa su results_test.csv.', ids{i});
    end
    plot(axz, 1 - m.Sp, m.Se, 'o', 'MarkerSize', 9, 'LineWidth', 1.4, ...
        'MarkerEdgeColor', colors(i, :), 'MarkerFaceColor', 'w', ...
        'DisplayName', sprintf('%s t_{se98}', labs{i}));
end
style_ax(ax, '1 - specifiškumas', 'jautrumas', 'Visa ROC kreivė');
legend(ax, 'Location', 'SouthEast', 'FontSize', 11);
axis(ax, [0 1 0 1]);
style_ax(axz, '1 - specifiškumas', 'jautrumas', 'Priartintas kampas');
xlim(axz, [0 0.2]);
ylim(axz, [0.8 1.0]);
grid(axz, 'on');
legend(axz, 'Location', 'SouthWest', 'FontSize', 11);
title(tl, 'ROC kreivės, testavimo aibė (n = 114)', 'FontSize', 14);
exportgraphics(f, fullfile(figDir, 'roc_comparison.png'), 'Resolution', 160);
close(f);
end

function plot_calibration(figDir, pack, ytest)
names = {'logreg', 'svm_rbf', 'ensemble'};
labs = {'B1', 'M1', 'M4'};
colors = [0.85 0.33 0.10; 0.93 0.69 0.13; 0.00 0.45 0.74];
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 760 560]);
ax = axes(f);
hold(ax, 'on');
plot(ax, [0 1], [0 1], 'k--', 'LineWidth', 1.2, 'DisplayName', 'idealas (y = x)');
for i = 1:numel(names)
    [conf, acc, cnt] = quantile_reliability(pack.(names{i}).p, ytest, 5);
    scatter(ax, conf, acc, 40 + 4 * cnt, colors(i, :), 'filled', ...
        'MarkerFaceAlpha', 0.85, 'DisplayName', labs{i});
end
style_ax(ax, 'vidutinė prognozuota tikimybė', 'stebėtas piktybinių dažnis', ...
    'Tikimybių kalibracija, 5 kvantilių rėžiai');
legend(ax, 'Location', 'NorthWest', 'FontSize', 11);
axis(ax, [0 1 0 1]);
exportgraphics(f, fullfile(figDir, 'calibration_curve.png'), 'Resolution', 160);
close(f);
end

function plot_fn(figDir, pack, ytest, Xtest, ytrain, Xtrain, ixCP)
t = pack.ensemble.thresholds.t_se98;
fn = find(ytest == 1 & pack.ensemble.p < t);
if numel(fn) ~= 3
    error('make_report_plots: M4 FN skaicius yra %d, tikimasi 3.', numel(fn));
end
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 760 560]);
ax = axes(f);
hold(ax, 'on');
histogram(ax, Xtrain(ytrain == 0, ixCP), 20, 'Normalization', 'pdf', ...
    'FaceAlpha', 0.35, 'DisplayName', 'gerybiniai (mokymas)');
histogram(ax, Xtrain(ytrain == 1, ixCP), 20, 'Normalization', 'pdf', ...
    'FaceAlpha', 0.35, 'DisplayName', 'piktybiniai (mokymas)');
xfn = Xtest(fn, ixCP);
yl = ylim(ax);
plot(ax, xfn, repmat(0.04 * max(yl(2), eps), numel(xfn), 1), 'rv', ...
    'MarkerFaceColor', 'r', 'MarkerSize', 9, 'DisplayName', 'M4 FN (3 atvejai)');
style_ax(ax, 'concave\_points\_worst', 'tankis', 'FN požymiai ir klasių pasiskirstymas');
legend(ax, 'Location', 'NorthEast', 'FontSize', 11);
exportgraphics(f, fullfile(figDir, 'fn_distribution.png'), 'Resolution', 160);
close(f);
end

function plot_confusion_set(figDir, pack, ytest)
specs = { ...
    'logreg', 'B1', 'confusion_b1.png'; ...
    'ensemble', 'M4', 'confusion_m4.png'};
for i = 1:size(specs, 1)
    t = pack.(specs{i, 1}).thresholds.t_se98;
    m = metrics(ytest, pack.(specs{i, 1}).p, t);
    C = [m.TN, m.FP; m.FN, m.TP];
    write_confusion(figDir, specs{i, 3}, C, numel(ytest), ...
        sprintf('%s painiavos matrica, t_{se98} = %.2f', specs{i, 2}, t));
end
end
function write_confusion(figDir, fileName, C, n, ttl)
f = figure('Visible', 'off', 'Color', 'w', 'Position', [120 80 640 560]);
ax = axes(f);
imagesc(ax, C);
colormap(ax, [0.86 0.92 0.86; 0.98 0.90 0.84; 0.98 0.84 0.84; 0.78 0.88 0.78]);
clim(ax, [0 max(C(:))]);
axis(ax, 'square');
set(ax, 'XTick', [1 2], 'YTick', [1 2], ...
    'XTickLabel', {'gerybinis', 'piktybinis'}, ...
    'YTickLabel', {'gerybinis', 'piktybinis'}, ...
    'FontSize', 12, 'TickLength', [0 0]);
xlabel(ax, 'Prognozė', 'FontSize', 13);
ylabel(ax, 'Tikroji klasė', 'FontSize', 13);
title(ax, ttl, 'FontSize', 14);
for r = 1:2
    for c = 1:2
        pct = 100 * C(r, c) / n;
        text(ax, c, r, sprintf('%d\n%.1f %%', C(r, c), pct), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontSize', 18, 'FontWeight', 'bold', 'Color', 'k');
    end
end
exportgraphics(f, fullfile(figDir, fileName), 'Resolution', 160);
close(f);
end

function plot_cost(figDir, pack, ytest)
names = {'logreg', 'ensemble'};
labs = {'B1', 'M4'};
colors = [0.85 0.33 0.10; 0.00 0.45 0.74];
tt = (0:0.01:1)';
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 760 560]);
ax = axes(f);
hold(ax, 'on');
ymax = 0;
for i = 1:numel(names)
    EC = zeros(size(tt));
    for k = 1:numel(tt)
        mm = metrics(ytest, pack.(names{i}).p, tt(k));
        EC(k) = 5 * mm.FN + 1 * mm.FP;
    end
    plot(ax, tt, EC, 'LineWidth', 1.8, 'Color', colors(i, :), 'DisplayName', labs{i});
    ymax = max(ymax, max(EC));
    t = pack.(names{i}).thresholds.t_se98;
    xline(ax, t, '--', 'Color', colors(i, :), 'LineWidth', 1.3, 'HandleVisibility', 'off');
    labels{i} = sprintf('%s: parinktas slenkstis t_{se98} = %.2f', labs{i}, t); %#ok<AGROW>
end
style_ax(ax, 'Slenkstis t', 'Empirinė kaina EC (santykis 5:1)', ...
    'Empirinė kaina testavimo aibėje');
ylim(ax, [0, ymax * 1.15]);
text(ax, 0.38, ymax * 0.95, labels{1}, 'Color', colors(1, :), ...
    'FontSize', 12, 'Interpreter', 'tex', 'VerticalAlignment', 'bottom');
text(ax, 0.38, ymax * 0.84, labels{2}, 'Color', colors(2, :), ...
    'FontSize', 12, 'Interpreter', 'tex', 'VerticalAlignment', 'bottom');
legend(ax, 'Location', 'NorthEast', 'FontSize', 11);
exportgraphics(f, fullfile(figDir, 'cost_curve.png'), 'Resolution', 160);
close(f);
end

function [conf, acc, cnt] = quantile_reliability(p, y, nBins)
p = p(:);
y = y(:);
[ps, ord] = sort(p);
ys = y(ord);
n = numel(ps);
edges = round(linspace(1, n + 1, nBins + 1));
conf = zeros(nBins, 1);
acc = zeros(nBins, 1);
cnt = zeros(nBins, 1);
for b = 1:nBins
    ix = edges(b):(edges(b + 1) - 1);
    cnt(b) = numel(ix);
    conf(b) = mean(ps(ix));
    acc(b) = mean(ys(ix));
end
end

function style_ax(ax, xlbl, ylbl, ttl)
xlabel(ax, xlbl, 'FontSize', 12);
ylabel(ax, ylbl, 'FontSize', 12);
title(ax, ttl, 'FontSize', 13);
grid(ax, 'on');
ax.FontSize = 12;
end

function v = csv_metric(res, modelId, field)
hit = strcmp(res.Modelis, modelId);
if ~any(hit)
    error('make_report_plots: results_test.csv neturi %s.', modelId);
end
raw = res.(field)(find(hit, 1));
if isstring(raw) || ischar(raw)
    v = str2double(strrep(char(raw), ',', '.'));
else
    v = double(raw);
end
end
