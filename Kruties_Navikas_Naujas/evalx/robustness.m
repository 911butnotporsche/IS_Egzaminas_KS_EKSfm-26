function robustness(cfg, ytest, Xtest, Xtrain)
%ROBUSTNESS Atsparumas po užšaldymo. Slenkstis ir modelis nebekeičiami.
%  Gauso triukšmas: x <- x + sigma * s_mok, s_mok tik iš mokymo.
%  Trūkstamos reikšmės: atsitiktinai 5–10 % testavimo langelių, užpildoma
%  mokymo mediana. Šis užpildymas yra tik atsparumo bandymas, ne pagrindinė grandinė.

if nargin < 1
    cfg = config();
end
names = {'majority', 'logreg', 'svm_rbf', 'mlp', 'rbfnet', 'ensemble'};
labels = {'B0', 'B1', 'M1', 'M2', 'M3', 'M4'};
rows = {};
sTrain = std(Xtrain, 0, 1);
medTrain = median(Xtrain, 1);

for i = 1:numel(names)
    path = fullfile(cfg.paths.models, [names{i} '.mat']);
    if exist(path, 'file') ~= 2
        error('robustness: nera %s.', path);
    end
    R = load(path);
    v0 = one_metrics(R, Xtest, ytest);
    rows(end+1, :) = {labels{i}, names{i}, 'none', 0, 1, v0(1), v0(2), v0(3), v0(4), v0(5), v0(6)}; %#ok<AGROW>

    for s = cfg.robust.noise_sigma
        acc = zeros(cfg.robust.repeats, 6);
        for rep = 1:cfg.robust.repeats
            rng(cfg.seed + 1000 * rep + round(100 * s), 'twister');
            Xn = Xtest + s * randn(size(Xtest)) .* sTrain;
            acc(rep, :) = one_metrics(R, Xn, ytest);
        end
        mu = mean(acc, 1);
        rows(end+1, :) = {labels{i}, names{i}, 'gaussian', s, cfg.robust.repeats, ...
            mu(1), mu(2), mu(3), mu(4), mu(5), mu(6)}; %#ok<AGROW>
    end

    for frac = cfg.robust.missing_frac
        acc = zeros(cfg.robust.repeats, 6);
        for rep = 1:cfg.robust.repeats
            rng(cfg.seed + 5000 * rep + round(1000 * frac), 'twister');
            Xn = Xtest;
            mask = rand(size(Xn)) < frac;
            Xn(mask) = NaN;
            for j = 1:size(Xn, 2)
                miss = isnan(Xn(:, j));
                Xn(miss, j) = medTrain(j);
            end
            acc(rep, :) = one_metrics(R, Xn, ytest);
        end
        mu = mean(acc, 1);
        rows(end+1, :) = {labels{i}, names{i}, 'missing', frac, cfg.robust.repeats, ...
            mu(1), mu(2), mu(3), mu(4), mu(5), mu(6)}; %#ok<AGROW>
    end
end

Tab = cell2table(rows, 'VariableNames', { ...
    'Modelis', 'model_id', 'Trikdis', 'Lygis', 'Pakartojimai', ...
    'Sensitivity', 'Specificity', 'ROC_AUC', 'Brier', 'FN', 'FP'});
out = fullfile(cfg.paths.reports, 'robustness_results.csv');
writetable(Tab, out);
fprintf('robustness -> %s\n', out);
end

function v = one_metrics(R, X, y)
cols = 1:size(X, 2);
if isfield(R, 'feat_cols') && ~isempty(R.feat_cols)
    cols = R.feat_cols(:)';
end
Z = apply_scaler(X(:, cols), R.model.scaler);
t = R.thresholds.t_se98;
[p, score] = predict_proba(R.model, Z, t);
m = metrics(y, p, t);
v = [m.Se, m.Sp, roc_auc(y, score), brier(y, p), m.FN, m.FP];
end
