function write_exam_figures(cfg, pack, ytest, Xtest, ytrain, Xtrain, featNames)
%WRITE_EXAM_FIGURES ROC su t_se98, kalibracijos kreivė, FN pasiskirstymas.
figDir = cfg.paths.figures;
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
if isrow(featNames)
    featNames = featNames(:)';
end
if ischar(featNames) || isstring(featNames)
    featNames = cellstr(featNames);
end

names = {'logreg', 'svm_rbf', 'mlp', 'rbfnet', 'ensemble'};
labs = {'B1', 'M1', 'M2', 'M3', 'M4'};
f = figure('Visible', 'off');
hold on
for i = 1:numel(names)
    if ~isfield(pack, names{i})
        continue
    end
    [Xroc, Yroc, ~, auc] = perfcurve(ytest, pack.(names{i}).score, 1);
    plot(Xroc, Yroc, 'LineWidth', 1.2, 'DisplayName', ...
        sprintf('%s AUC=%.3f', labs{i}, auc));
    t = pack.(names{i}).thresholds.t_se98;
    m = metrics(ytest, pack.(names{i}).p, t);
    plot(1 - m.Sp, m.Se, 'o', 'MarkerSize', 7, 'HandleVisibility', 'off');
end
plot([0 1], [0 1], 'k--', 'HandleVisibility', 'off');
xlabel('1 - specifiškumas');
ylabel('jautrumas');
title('ROC kreivė, testavimo aibė; skritulys = t_{se98}');
legend('Location', 'SouthEast');
grid on
print(f, fullfile(figDir, 'roc_tse98.png'), '-dpng', '-r140');
print(f, fullfile(figDir, 'roc.png'), '-dpng', '-r140');
close(f);

f = figure('Visible', 'off');
hold on
for i = 1:numel(names)
    if ~isfield(pack, names{i})
        continue
    end
    cal = pack.(names{i}).cal;
    if isempty(cal.conf)
        continue
    end
    plot(cal.conf, cal.acc, '-o', 'LineWidth', 1.2, 'DisplayName', labs{i});
end
plot([0 1], [0 1], 'k--', 'HandleVisibility', 'off');
xlabel('vidutinė prognozuota tikimybė');
ylabel('stebėtas piktybinių dažnis');
title('Tikimybių kalibracijos kreivė (testavimo aibė)');
legend('Location', 'SouthEast');
grid on
print(f, fullfile(figDir, 'reliability.png'), '-dpng', '-r140');
print(f, fullfile(figDir, 'calibration.png'), '-dpng', '-r140');
close(f);

ix = find(strcmp(featNames, 'concave_points_worst'), 1);
if isempty(ix)
    return
end
primary = 'ensemble';
if ~isfield(pack, primary)
    primary = 'logreg';
end
t = pack.(primary).thresholds.t_se98;
p = pack.(primary).p;
fn = ytest == 1 & p < t;
f = figure('Visible', 'off');
hold on
histogram(Xtrain(ytrain == 0, ix), 20, 'Normalization', 'pdf', 'FaceAlpha', 0.35, ...
    'DisplayName', 'gerybiniai (mokymas)');
histogram(Xtrain(ytrain == 1, ix), 20, 'Normalization', 'pdf', 'FaceAlpha', 0.35, ...
    'DisplayName', 'piktybiniai (mokymas)');
if any(fn)
    xfn = Xtest(fn, ix);
    yl = ylim;
    plot(xfn, repmat(0.02 * yl(2), numel(xfn), 1), 'rv', 'MarkerFaceColor', 'r', ...
        'DisplayName', 'FN testavimo aibėje');
end
xlabel('concave\_points\_worst');
ylabel('tankis');
title('FN požymiai ir klasių pasiskirstymas');
legend('Location', 'NorthEast');
grid on
print(f, fullfile(figDir, 'fn_distribution.png'), '-dpng', '-r140');
close(f);
end
