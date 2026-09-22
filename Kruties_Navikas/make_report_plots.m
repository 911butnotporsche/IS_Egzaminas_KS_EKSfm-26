function make_report_plots()
%MAKE_REPORT_PLOTS  Aiškūs grafikai PDF pristatymui. Paleisti iš Command Window:
%    make_report_plots
%    % arba:  run make_report_plots
%
%  Skaičiai (Se, Sp, PI, TP/FN, H1, slenksčiai, EC taškuose) — TIK iš
%  reports/tables/*.csv. Modeliai NEPERMOKAMI, evaluate_test / tune_cv /
%  run_all NEKVIEČIAMI.
%
%  ROC, kalibracijos dėžutės ir tanki EC(t) kreivė CSV nėra (evaluate_test
%  įrašė tik PNG). Todėl kreivių FORMA imama iš jau užšaldyto
%  data/processed/test_predictions.mat (p, score, ytest, cal) — tos pačios
%  testo tikimybės, ne naujas eksperimentas. Jei .mat nėra, piešiama tai,
%  kas įmanoma iš CSV (operaciniai taškai / 3 EC taškai).
%
%  Langai paliekami ATIDARYTI (nėra Visible=off, nėra close po išsaugojimo).
%  Išvestis: reports/figures_clean/  (senų reports/figures/ neperrašo).

root = fileparts(mfilename('fullpath'));
tabDir = fullfile(root, 'reports', 'tables');
outDir = fullfile(root, 'reports', 'figures_clean');
predFile = fullfile(root, 'data', 'processed', 'test_predictions.mat');

if ~exist(tabDir, 'dir')
    error('make_report_plots: nera %s', tabDir);
end
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% Ankstesnio šio skripto paleidimo langai — kad nekauptųsi dublikatai.
old = findall(groot, 'Type', 'figure', 'Tag', 'wdbc_report_plot');
if ~isempty(old)
    delete(old);
end

T = readtable(fullfile(tabDir, 'main_results.csv'), 'TextType', 'string');
H = readtable(fullfile(tabDir, 'hypotheses.csv'), 'TextType', 'string');
T.model = string(T.model);
T.point = string(T.point);
H.hypothesis = string(H.hypothesis);

hasPred = exist(predFile, 'file') == 2;
pack = struct();
ytest = [];
if hasPred
    Spred = load(predFile, 'pack', 'ytest');
    pack = Spred.pack;
    ytest = Spred.ytest(:);
end

sty = model_style();
saved = {};

% --- 1. Kalibracija: 2x2 subplotai, taškai = dėžučių vidurkiai ---
fig1 = newfig('Kalibracija (testas)', 1);
plot_calibration(fig1, T, pack, ytest, hasPred, sty);
saved{end+1} = keep_save(fig1, fullfile(outDir, 'calibration.png')); %#ok<AGROW>

% --- 2. ROC su brūkšniais + viršutinio kairio kampo inset ---
fig2 = newfig('ROC (testas)', 2);
plot_roc(fig2, T, pack, ytest, hasPred, sty);
saved{end+1} = keep_save(fig2, fullfile(outDir, 'roc.png')); %#ok<AGROW>

% --- 3. Kainos kreivė: SVM vs logistinė regresija ---
fig3 = newfig('Kainos kreive SVM vs LR', 3);
plot_cost(fig3, T, pack, ytest, hasPred, sty, tabDir);
saved{end+1} = keep_save(fig3, fullfile(outDir, 'cost_curve.png')); %#ok<AGROW>

% --- 4. Painiavos matrica su skaičiais ---
fig4 = newfig('Painiavos matrica SVM-RBF', 4);
plot_confusion(fig4, T);
saved{end+1} = keep_save(fig4, fullfile(outDir, 'confusion_svm_rbf.png')); %#ok<AGROW>

% --- 5. Se / Sp stulpeliai su 95 % PI ---
fig5 = newfig('Jautrumas ir specifiškumas t_se98', 5);
plot_se_sp_bars(fig5, T, sty);
saved{end+1} = keep_save(fig5, fullfile(outDir, 'se_sp_tse98.png')); %#ok<AGROW>

% --- 6. H1 sprendimas: ΔSp ir ΔAUC ---
fig6 = newfig('H1 sprendimas', 6);
plot_h1(fig6, H);
saved{end+1} = keep_save(fig6, fullfile(outDir, 'h1_sprendimas.png')); %#ok<AGROW>

n = numel(saved);
fprintf('\n========================================\n');
fprintf('make_report_plots: sugeneruota %d grafiku.\n', n);
fprintf('Issaugota: %s\n', outDir);
if ~hasPred
    fprintf(['Pastaba: nera test_predictions.mat — ROC/kalibracija/EC(t) ', ...
             'piešti tik iš CSV operacinių taškų.\n']);
end
for i = 1:n
    fprintf('  %d) %s\n', i, saved{i});
end
fprintf('Figure langai palikti atidaryti (niekas neuždaryta).\n');
fprintf('========================================\n');
end

% =====================================================================
function plot_calibration(fig, T, pack, ytest, hasPred, sty)
nms = {'logreg', 'svm_rbf', 'mlp', 'rbfnet'};
tl = tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
title(tl, 'Kalibracija teste (10 tikimybės dėžučių)', ...
    'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');
ax1 = [];
for i = 1:4
    ax = nexttile(tl);
    if i == 1, ax1 = ax; end
    hold(ax, 'on');
    nm = nms{i};
    s = sty.(nm);
    r = pick(T, nm, 't_se98');
    [conf, acc, cnt] = calib_bins(pack, ytest, hasPred, nm);
    plot(ax, [0 1], [0 1], ':', 'Color', [0.00 0.00 0.00], 'LineWidth', 1.0);
    ok = isfinite(conf) & isfinite(acc) & cnt > 0;
    if any(ok)
        cs = conf(ok); asv = acc(ok); ns = cnt(ok);
        [cs, ix] = sort(cs);
        asv = asv(ix); ns = ns(ix);
        fade = 0.40 * s.color + 0.60;
        if numel(cs) >= 3
            plot(ax, cs, movmean(asv, 3), '-', 'Color', fade, 'LineWidth', 1.6);
        elseif numel(cs) >= 2
            plot(ax, cs, asv, '-', 'Color', fade, 'LineWidth', 1.2);
        end
        ms = 36 + 70 * sqrt(ns / max(max(ns), 1));
        scatter(ax, cs, asv, ms, s.color, 'filled', s.marker, ...
            'MarkerEdgeColor', [0.15 0.15 0.15], 'LineWidth', 0.8);
    end
    % Platt / logit tinklo kreivė iš CSV cal_a, cal_b (glodi, ne šokinėjanti)
    a = r.cal_a; b = r.cal_b;
    if isfinite(a) && isfinite(b)
        pg = linspace(0.02, 0.98, 80);
        lg = log(pg ./ (1 - pg));
        accHat = 1 ./ (1 + exp(-(a + b * lg)));
        plot(ax, pg, accHat, '--', 'Color', s.color, 'LineWidth', 1.1);
    end
    grid(ax, 'on');
    set(ax, 'Color', 'w', 'GridColor', [0.85 0.85 0.85], 'Layer', 'top');
    xlim(ax, [0 1]); ylim(ax, [0 1]); axis(ax, 'square');
    title(ax, sprintf('%s   ECE = %.3f', s.lt, r.ECE), 'Interpreter', 'none', ...
        'Color', s.color, 'FontSize', 11);
    xlabel(ax, 'Vidutinė prognozuota P(piktybinis)', 'Interpreter', 'none');
    ylabel(ax, 'Faktinė piktybinių dalis dėžutėje', 'Interpreter', 'none');
end
lg = legend(ax1, {'Idealas y = x', 'Slenkantis vidurkis', ...
    'Dėžutės vidurkis (dydis ~ n)', 'Logit kreivė (cal_a, cal_b)'}, ...
    'Interpreter', 'none', 'FontSize', 9, 'Box', 'off', 'NumColumns', 4);
lg.Layout.Tile = 'south';
end

function plot_roc(fig, T, pack, ytest, hasPred, sty)
nms = {'logreg', 'svm_rbf', 'mlp', 'rbfnet'};
ax = axes(fig, 'Position', [0.08 0.12 0.50 0.78]);
hold(ax, 'on');
plot(ax, [0 1], [0 1], ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.1, ...
    'DisplayName', 'Atsitiktinis klasifikatorius');
for i = 1:numel(nms)
    nm = nms{i};
    s = sty.(nm);
    r = pick(T, nm, 't_se98');
    [fpr, tpr] = roc_from_frozen(pack, ytest, hasPred, nm, T);
    plot(ax, fpr, tpr, 'LineStyle', s.line, 'Color', s.color, ...
        'LineWidth', 2.0, 'DisplayName', sprintf('%s  (AUC = %.3f)', s.lt, r.AUC));
    plot(ax, 1 - r.Sp, r.Se, s.marker, 'Color', s.color, ...
        'MarkerFaceColor', s.color, 'MarkerSize', 9, ...
        'MarkerEdgeColor', [0.1 0.1 0.1], 'HandleVisibility', 'off');
end
grid(ax, 'on');
set(ax, 'Color', 'w', 'GridColor', [0.85 0.85 0.85]);
xlim(ax, [0 1]); ylim(ax, [0 1]); axis(ax, 'square');
xlabel(ax, '1 − Specifiškumas  (klaidingai piktybiniai)', 'Interpreter', 'none');
ylabel(ax, 'Jautrumas  (teisingai piktybiniai)', 'Interpreter', 'none');
title(ax, 'ROC kreivės teste (brūkšniai skiriasi ir nespalvotai)', ...
    'Interpreter', 'none', 'FontSize', 13, 'FontWeight', 'bold');
lg = legend(ax, 'Interpreter', 'none', 'Box', 'off', 'FontSize', 9);
lg.Units = 'normalized';
lg.Position = [0.60 0.10 0.36 0.28];
lg.Color = 'w';

% Inset dešinėje viršuje — neuždengia legendos ir neuždengia kairiojo kampo
axIn = axes(fig, 'Position', [0.60 0.46 0.36 0.40]);
hold(axIn, 'on');
plot(axIn, [0 1], [0 1], ':', 'Color', [0.45 0.45 0.45], 'LineWidth', 0.8);
for i = 1:numel(nms)
    nm = nms{i};
    s = sty.(nm);
    r = pick(T, nm, 't_se98');
    [fpr, tpr] = roc_from_frozen(pack, ytest, hasPred, nm, T);
    plot(axIn, fpr, tpr, 'LineStyle', s.line, 'Color', s.color, 'LineWidth', 2.0);
    plot(axIn, 1 - r.Sp, r.Se, s.marker, 'Color', s.color, ...
        'MarkerFaceColor', s.color, 'MarkerSize', 8, ...
        'MarkerEdgeColor', [0.1 0.1 0.1]);
end
xlim(axIn, [0 0.22]); ylim(axIn, [0.86 1.005]);
grid(axIn, 'on');
set(axIn, 'Color', [0.97 0.97 0.97], 'FontSize', 9, 'Box', 'on', ...
    'LineWidth', 1.1);
xlabel(axIn, '1 − Specifiškumas', 'Interpreter', 'none', 'FontSize', 9);
ylabel(axIn, 'Jautrumas', 'Interpreter', 'none', 'FontSize', 9);
title(axIn, 'Padidinta: viršutinis kairys kampas', ...
    'Interpreter', 'none', 'FontSize', 10, 'FontWeight', 'bold');
end

function plot_cost(fig, T, pack, ytest, hasPred, sty, ~)
ax = axes(fig);
hold(ax, 'on');
tgrid = 0:0.01:1;
cFN = 5; cFP = 1;
pair = {'logreg', 'svm_rbf'};
for i = 1:2
    nm = pair{i};
    s = sty.(nm);
    r98 = pick(T, nm, 't_se98');
    rc = pick(T, nm, 't_cost');
    if hasPred && isfield(pack, nm)
        EC = ec_from_p(ytest, pack.(nm).p(:), tgrid, cFN, cFP);
        plot(ax, tgrid, EC, 'LineStyle', s.line, 'Color', s.color, ...
            'LineWidth', 2.2, 'DisplayName', sprintf('%s (testas)', s.lt));
    else
        pts = T(T.model == nm, :);
        [tt, ix] = unique(pts.t);
        plot(ax, tt, pts.EC(ix), 'LineStyle', s.line, 'Color', s.color, ...
            'LineWidth', 2.0, 'Marker', s.marker, 'MarkerFaceColor', s.color, ...
            'DisplayName', sprintf('%s (3 CSV taškai)', s.lt));
    end
    xline(ax, r98.t, 'LineStyle', s.line, 'Color', s.color, 'LineWidth', 1.4, ...
        'Label', sprintf('t_{se98} %s = %.2f', s.short, r98.t), ...
        'LabelVerticalAlignment', 'top', 'HandleVisibility', 'off');
    plot(ax, rc.t, rc.EC, s.marker, 'Color', s.color, 'MarkerSize', 10, ...
        'MarkerFaceColor', s.color, 'MarkerEdgeColor', [0.1 0.1 0.1], ...
        'HandleVisibility', 'off');
end
grid(ax, 'on');
set(ax, 'Color', 'w', 'GridColor', [0.85 0.85 0.85]);
xlabel(ax, 'Slenkstis t', 'Interpreter', 'none');
ylabel(ax, 'Tikėtina kaina   EC = 5·FN + 1·FP', 'Interpreter', 'none');
title(ax, 'Kainos kreivė teste: SVM-RBF ir logistinė regresija (5:1)', ...
    'Interpreter', 'none', 'FontSize', 13, 'FontWeight', 'bold');
legend(ax, 'Location', 'northeast', 'Interpreter', 'none', 'Box', 'off');
xlim(ax, [0 1]);
end

function plot_confusion(fig, T)
r = pick(T, 'svm_rbf', 't_se98');
C = [r.TN, r.FP; r.FN, r.TP];
labs = {sprintf('TN\nteisingai\ngerybinis'), sprintf('FP\nklaidingai\npiktybinis'); ...
        sprintf('FN\nklaidingai\ngerybinis'), sprintf('TP\nteisingai\npiktybinis')};
ax = axes(fig);
imagesc(ax, C);
axis(ax, 'equal', 'tight');
cmap = [linspace(0.95, 0.20, 64)', linspace(0.96, 0.40, 64)', linspace(0.98, 0.75, 64)'];
colormap(ax, cmap);
cb = colorbar(ax);
cb.Label.String = 'Atvejų skaičius (testas n = 113)';
cb.Label.Interpreter = 'none';
set(ax, 'XTick', [1 2], 'YTick', [1 2], ...
    'XTickLabel', {'Gerybinis (B)', 'Piktybinis (M)'}, ...
    'YTickLabel', {'Gerybinis (B)', 'Piktybinis (M)'}, ...
    'FontSize', 12, 'TickLength', [0 0]);
xlabel(ax, 'Nuspėtas', 'Interpreter', 'none', 'FontSize', 13, 'FontWeight', 'bold');
ylabel(ax, 'Tikrasis', 'Interpreter', 'none', 'FontSize', 13, 'FontWeight', 'bold');
title(ax, sprintf(['SVM-RBF painiavos matrica   t_{se98} = %.2f', ...
    '   (Se = %.3f,  Sp = %.3f)'], r.t, r.Se, r.Sp), ...
    'Interpreter', 'tex', 'FontSize', 13, 'FontWeight', 'bold');
mx = max(C(:));
for i = 1:2
    for j = 1:2
        if C(i, j) > 0.55 * mx
            tc = 'w';
        else
            tc = [0.05 0.05 0.08];
        end
        text(ax, j, i, sprintf('%d\n%s', C(i, j), labs{i, j}), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontSize', 13, 'FontWeight', 'bold', 'Color', tc, ...
            'Interpreter', 'none');
    end
end
end

function plot_se_sp_bars(fig, T, sty)
order = {'majority', 'logreg', 'svm_rbf', 'mlp', 'rbfnet'};
n = numel(order);
Se = zeros(n, 1); SeLo = Se; SeHi = Se;
Sp = zeros(n, 1); SpLo = Sp; SpHi = Sp;
lbl = strings(n, 1);
for i = 1:n
    r = pick(T, order{i}, 't_se98');
    Se(i) = r.Se; SeLo(i) = r.Se_lo; SeHi(i) = r.Se_hi;
    Sp(i) = r.Sp; SpLo(i) = r.Sp_lo; SpHi(i) = r.Sp_hi;
    lbl(i) = sty.(order{i}).lt;
end
ax = axes(fig);
hold(ax, 'on');
cats = categorical(cellstr(lbl), cellstr(lbl), 'Ordinal', true);
b = bar(ax, cats, [Se, Sp], 'grouped');
b(1).FaceColor = [0.20 0.45 0.70];
b(1).EdgeColor = 'none';
b(1).DisplayName = 'Jautrumas (Se)';
b(2).FaceColor = [0.85 0.45 0.13];
b(2).EdgeColor = 'none';
b(2).DisplayName = 'Specifiškumas (Sp)';
errorbar(ax, b(1).XEndPoints, Se, Se - SeLo, SeHi - Se, 'k', ...
    'LineStyle', 'none', 'LineWidth', 1.2, 'CapSize', 8, 'HandleVisibility', 'off');
errorbar(ax, b(2).XEndPoints, Sp, Sp - SpLo, SpHi - Sp, 'k', ...
    'LineStyle', 'none', 'LineWidth', 1.2, 'CapSize', 8, 'HandleVisibility', 'off');
yline(ax, 0.98, '--', 'Color', [0.15 0.15 0.15], 'LineWidth', 1.0, ...
    'Label', 'Se tikslas 0,98', 'Interpreter', 'none', 'HandleVisibility', 'off');
ylim(ax, [0 1.05]);
ylabel(ax, 'Tikslumas grupėje (jautrumas / specifiškumas)', 'Interpreter', 'none');
xlabel(ax, 'Modelis  (taškas t_{se98}, testas n = 113)', 'Interpreter', 'tex');
title(ax, 'Jautrumas ir specifiškumas su 95 % Wilson intervalais', ...
    'Interpreter', 'none', 'FontSize', 13, 'FontWeight', 'bold');
grid(ax, 'on');
set(ax, 'YGrid', 'on', 'XGrid', 'off', 'Color', 'w', ...
    'GridColor', [0.85 0.85 0.85]);
legend(ax, 'Location', 'eastoutside', 'Interpreter', 'none', 'Box', 'off');
for i = 1:n
    ySe = min(1.02, max(Se(i), SeHi(i)) + 0.025);
    if Se(i) < 0.12
        ySe = SeHi(i) + 0.06;
    end
    text(ax, b(1).XEndPoints(i), ySe, sprintf('%.2f', Se(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 8, 'Interpreter', 'none', ...
        'Color', [0.2 0.3 0.5]);
    text(ax, b(2).XEndPoints(i), min(1.02, SpHi(i) + 0.025), sprintf('%.2f', Sp(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 8, 'Interpreter', 'none', ...
        'Color', [0.55 0.28 0.05]);
end
end

function plot_h1(fig, H)
dSp = H(H.hypothesis == "H1_dSp", :);
dAu = H(H.hypothesis == "H1_AUC", :);
h1  = H(H.hypothesis == "H1", :);
tl = tiledlayout(fig, 2, 1, 'Padding', 'compact', 'TileSpacing', 'compact');
if h1.accepted == 0
    h1txt = 'H1 ATMESTA  (reikia abiejų dalių: ΔSp IR AUC)';
else
    h1txt = 'H1 PRIIMTA';
end
title(tl, h1txt, 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'none');

ax1 = nexttile(tl);
hold(ax1, 'on');
errorbar(ax1, dSp.point, 1, dSp.point - dSp.ci_lo, dSp.ci_hi - dSp.point, ...
    'horizontal', 'o', 'Color', [0.85 0.33 0.10], 'MarkerFaceColor', [0.85 0.33 0.10], ...
    'MarkerSize', 10, 'LineWidth', 2.0, 'CapSize', 12);
xline(ax1, 0, ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.0);
xline(ax1, 0.03, '--', 'Color', [0.10 0.35 0.65], 'LineWidth', 1.6, ...
    'Label', 'Riba  0,03', 'Interpreter', 'none', 'LabelOrientation', 'horizontal');
if dSp.accepted == 1
    st = 'ΔSp dalis PRIIMTA (PI apačia > 0 ir taškas ≥ 0,03)';
else
    st = 'ΔSp dalis ATMESTA';
end
title(ax1, sprintf('%s.  ΔSp = %.3f,  95%% PI [%.3f; %.3f]', ...
    st, dSp.point, dSp.ci_lo, dSp.ci_hi), 'Interpreter', 'none', 'FontSize', 11);
xlabel(ax1, 'Sp(SVM-RBF) − Sp(logistinė)  taške t_{se98}', 'Interpreter', 'tex');
yticks(ax1, 1); yticklabels(ax1, {'ΔSp'});
ylim(ax1, [0.4 1.6]);
xlim(ax1, [-0.05 0.55]);
grid(ax1, 'on');
set(ax1, 'Color', 'w', 'GridColor', [0.88 0.88 0.88]);

ax2 = nexttile(tl);
hold(ax2, 'on');
errorbar(ax2, dAu.point, 1, dAu.point - dAu.ci_lo, dAu.ci_hi - dAu.point, ...
    'horizontal', 's', 'Color', [0.00 0.45 0.74], 'MarkerFaceColor', [0.00 0.45 0.74], ...
    'MarkerSize', 10, 'LineWidth', 2.0, 'CapSize', 12);
xline(ax2, 0, ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.0);
xline(ax2, -0.005, '--', 'Color', [0.70 0.15 0.15], 'LineWidth', 1.6, ...
    'Label', 'Riba  −0,005', 'Interpreter', 'none', 'LabelOrientation', 'horizontal');
if dAu.accepted == 1
    st2 = 'AUC ne-prastesnumas PRIIMTAS (PI apačia ≥ −0,005)';
else
    st2 = 'AUC ne-prastesnumas ATMESTAS (PI apačia < −0,005)  →  H1 krenta čia';
end
title(ax2, sprintf('%s.  ΔAUC = %.4f,  95%% PI [%.4f; %.4f]', ...
    st2, dAu.point, dAu.ci_lo, dAu.ci_hi), 'Interpreter', 'none', 'FontSize', 11);
xlabel(ax2, 'AUC(SVM-RBF) − AUC(logistinė)  (DeLong)', 'Interpreter', 'none');
yticks(ax2, 1); yticklabels(ax2, {'ΔAUC'});
ylim(ax2, [0.4 1.6]);
xlim(ax2, [-0.012 0.008]);
grid(ax2, 'on');
set(ax2, 'Color', 'w', 'GridColor', [0.88 0.88 0.88]);
end

% ----- pagalbinės -----
function r = pick(T, model, point)
ix = T.model == string(model) & T.point == string(point);
if nnz(ix) ~= 1
    error('make_report_plots: nera vienos eilutes %s / %s (gauta %d).', ...
        model, point, nnz(ix));
end
r = T(ix, :);
end

function [conf, acc, cnt] = calib_bins(pack, ytest, hasPred, nm)
nBins = 10;
conf = nan(nBins, 1); acc = conf; cnt = zeros(nBins, 1);
if hasPred && isfield(pack, nm) && isfield(pack.(nm), 'cal') ...
        && isfield(pack.(nm).cal, 'conf') && ~isempty(pack.(nm).cal.conf)
    conf = pack.(nm).cal.conf(:);
    acc = pack.(nm).cal.acc(:);
    if isfield(pack.(nm).cal, 'cnt')
        cnt = pack.(nm).cal.cnt(:);
    else
        cnt = ones(size(conf));
        cnt(~isfinite(conf)) = 0;
    end
    return
end
if ~(hasPred && isfield(pack, nm) && isfield(pack.(nm), 'p'))
    return
end
p = pack.(nm).p(:);
y = ytest(:);
edges = linspace(0, 1, nBins + 1);
for g = 1:nBins
    if g < nBins
        in = p >= edges(g) & p < edges(g + 1);
    else
        in = p >= edges(g) & p <= edges(g + 1);
    end
    cnt(g) = sum(in);
    if cnt(g) == 0
        continue
    end
    acc(g) = mean(y(in));
    conf(g) = mean(p(in));
end
end

function [fpr, tpr] = roc_from_frozen(pack, ytest, hasPred, nm, T)
if hasPred && isfield(pack, nm) && isfield(pack.(nm), 'score')
    [fpr, tpr] = local_roc(ytest, pack.(nm).score(:));
    return
end
% CSV: trys operaciniai taškai + kampai (ne visos kreivės, tik kas yra lenteleje)
pts = T(T.model == string(nm), :);
xy = [1 - pts.Sp, pts.Se];
xy = unique(xy, 'rows');
xy = sortrows(xy, 1);
fpr = [0; xy(:, 1); 1];
tpr = [0; xy(:, 2); xy(end, 2)];
end

function [fpr, tpr] = local_roc(y, s)
y = double(y(:)); s = double(s(:));
nPos = sum(y == 1); nNeg = sum(y == 0);
[ss, ord] = sort(s, 'descend');
ys = y(ord);
tp = cumsum(ys == 1);
fp = cumsum(ys == 0);
endTie = [ss(1:end-1) ~= ss(2:end); true];
fpr = [0; fp(endTie) / max(nNeg, eps)];
tpr = [0; tp(endTie) / max(nPos, eps)];
if fpr(end) < 1 - 1e-12
    fpr = [fpr; 1];
    tpr = [tpr; 1];
end
end

function EC = ec_from_p(y, p, tgrid, cFN, cFP)
y = y(:); p = p(:);
EC = zeros(size(tgrid));
for i = 1:numel(tgrid)
    yhat = p >= tgrid(i);
    FN = sum(y == 1 & ~yhat);
    FP = sum(y == 0 & yhat);
    EC(i) = cFN * FN + cFP * FP;
end
end

function sty = model_style()
% Pastovi spalvų / žymenų / brūkšnių sistema visiems grafikams.
sty = struct();
sty.majority = mk([0.45 0.45 0.45], 'd', ':',  'Dauguma (B0)',           'B0');
sty.logreg   = mk([0.00 0.45 0.74], 'o', '-',  'Logistinė regresija (B1)', 'LR');
sty.svm_rbf  = mk([0.85 0.33 0.10], 's', '--', 'SVM-RBF (M1)',            'SVM');
sty.mlp      = mk([0.93 0.69 0.13], '^', ':',  'MLP (M2)',                 'MLP');
sty.rbfnet   = mk([0.49 0.18 0.56], 'p', '-.', 'RBF tinklas (M3)',         'RBF');
sty.svm_linear = mk([0.20 0.60 0.40], 'v', '-', 'Tiesinis SVM',            'lin');
end

function s = mk(color, marker, line, lt, short)
s.color = color;
s.marker = marker;
s.line = line;
s.lt = lt;
s.short = short;
end

function fig = newfig(name, k)
fig = figure('Name', name, 'Color', 'w', 'Visible', 'on', ...
    'NumberTitle', 'on', 'Tag', 'wdbc_report_plot', ...
    'Position', [50 + 28 * k, 40 + 18 * k, 1000, 680], ...
    'InvertHardcopy', 'on');
set(fig, 'DefaultAxesFontName', 'Segoe UI', ...
    'DefaultTextFontName', 'Segoe UI', ...
    'DefaultAxesFontSize', 11, ...
    'DefaultAxesColor', 'w', ...
    'DefaultFigureColor', 'w');
end

function outPath = keep_save(fig, outPath)
drawnow;
if ~isempty(which('exportgraphics'))
    exportgraphics(fig, outPath, 'Resolution', 200, 'BackgroundColor', 'white');
else
    set(fig, 'PaperPositionMode', 'auto');
    print(fig, outPath, '-dpng', '-r200');
end
% Langas LIEKA atidarytas — jokių close / Visible off.
end
