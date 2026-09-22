function result = tune_cv(Xtrain, ytrain, cvInner, cfg, modelName, idxTrain, idxTest, saveName)
%TUNE_CV Hiperparametrai pagal vidutinį OOF ROC-AUC per 25 skaidinius (6.3).
%  Scaler fitinamas kiekviename folde iš naujo. idxTest tik assert — fit jo nemato.

ytrain = ytrain(:);
idxTrain = idxTrain(:);
idxTest = idxTest(:);
n = size(Xtrain, 1);
if n ~= numel(ytrain) || n ~= numel(idxTrain)
    error('tune_cv: Xtrain, ytrain, idxTrain ilgiai nesutampa.');
end
if n == 569
    error('WDBC:Tune:FullSet', 'tune_cv: n=569 — tik mokymo dalis.');
end
if any(ismember(idxTrain, idxTest))
    error('tune_cv: idxTrain persidengia su idxTest.');
end
if nargin < 8 || isempty(saveName)
    saveName = modelName;
end
if cvInner.nPartitions ~= 25
    error('tune_cv: reikia 25 vidiniu skaidiniu, gauta %d.', cvInner.nPartitions);
end

grid = hp_grid(modelName, cfg);
nG = numel(grid);
aucMean = zeros(nG, 1);
oofAll = zeros(n, nG);

fprintf('tune_cv %s: %d konfig. × 25 skaidiniai\n', modelName, nG);
for g = 1:nG
    hp = grid(g);
    foldAuc = zeros(cvInner.repeats, cvInner.k);
    oofSum = zeros(n, 1);
    oofCnt = zeros(n, 1);
    for r = 1:cvInner.repeats
        for f = 1:cvInner.k
            rng(cfg.seed + 1000 * r + f, 'twister');
            tr = training(cvInner.cv{r}, f);
            va = test(cvInner.cv{r}, f);
            usedAbs = idxTrain(tr);
            if any(ismember(usedAbs, idxTest))
                error('tune_cv: testo indeksas pateko i fit (r=%d f=%d).', r, f);
            end
            sc = fit_scaler(Xtrain(tr, :), cfg);
            Ztr = apply_scaler(Xtrain(tr, :), sc);
            Zva = apply_scaler(Xtrain(va, :), sc);
            scVa = fold_score(modelName, Ztr, ytrain(tr), Zva, hp, cfg, ...
                cvInner.seed_fold(r, f));
            foldAuc(r, f) = roc_auc(ytrain(va), scVa);
            oofSum(va) = oofSum(va) + scVa;
            oofCnt(va) = oofCnt(va) + 1;
        end
    end
    if any(oofCnt == 0)
        error('tune_cv: OOF nepadengia visos mokymo dalies.');
    end
    aucMean(g) = mean(foldAuc(:));
    oofAll(:, g) = oofSum ./ oofCnt;
    fprintf('  [%d/%d] auc=%.4f %s\n', g, nG, aucMean(g), hp_str(hp));
end

% 6.3: max OOF AUC; jei |ΔAUC| < 0,002 — paprastesnis (ne nuoseklus „pirmas paprastas“).
[maxAuc, ~] = max(aucMean);
idxCand = find(aucMean >= maxAuc - 0.002 - 1e-12);
bestG = idxCand(1);
for ii = 2:numel(idxCand)
    gNew = idxCand(ii);
    if is_simpler(grid(gNew), grid(bestG), modelName)
        bestG = gNew;
    elseif ~is_simpler(grid(bestG), grid(gNew), modelName) && aucMean(gNew) > aucMean(bestG)
        bestG = gNew;
    end
end
bestAuc = aucMean(bestG);
hpKeep = grid(bestG);
oofKeep = oofAll(:, bestG);

scaler = fit_scaler(Xtrain, cfg);
Zall = apply_scaler(Xtrain, scaler);
model = train_final(modelName, Zall, ytrain, hpKeep, cfg);

if strcmp(modelName, 'majority')
    pOof = zeros(n, 1);
    platt = struct();
    thr = struct('t_cost', 0.5, 't_se98', 0.5, 't_youden', 0.5, ...
        't_bayes', cfg.cost(2) / sum(cfg.cost));
else
    platt = calibrate_platt(oofKeep, ytrain);
    pOof = platt_apply(platt, oofKeep);
    if any(pOof <= 0 | pOof >= 1)
        error('tune_cv: OOF tikimybes turi buti (0,1).');
    end
    thr = choose_threshold(pOof, ytrain, cfg);
end
model.platt = platt;
model.thresholds = thr;
model.scaler = scaler;
model.kind = modelName;
if strcmp(modelName, 'svm_rbf')
    model.kind = 'svm_rbf';
elseif strcmp(modelName, 'svm_linear')
    model.kind = 'svm_linear';
end

result = struct();
result.model = model;
result.hp = hpKeep;
result.oof_score = oofKeep;
result.oof_p = pOof;
result.cv_auc_mean = bestAuc;
result.cv_auc_grid = aucMean;
result.thresholds = thr;
result.modelName = modelName;
result.saveName = saveName;
result.nTrain = n;

if ~exist(cfg.paths.models, 'dir')
    mkdir(cfg.paths.models);
end
outPath = fullfile(cfg.paths.models, [saveName '.mat']);
save(outPath, '-struct', 'result', '-v7');
result.path = outPath;
fprintf('tune_cv %s [%s]: geriausias AUC=%.4f %s -> %s\n', ...
    modelName, saveName, bestAuc, hp_str(hpKeep), outPath);
end

function grid = hp_grid(modelName, cfg)
switch modelName
    case 'majority'
        grid = struct('dummy', {1});
    case 'logreg'
        v = cfg.logreg.lambda;
        grid = struct('lambda', num2cell(v));
    case 'svm_rbf'
        [CC, ss] = ndgrid(cfg.svm.C, cfg.svm.scale);
        grid = struct('C', num2cell(CC(:)), 's', num2cell(ss(:)));
    case 'svm_linear'
        v = cfg.svm_linear.C;
        grid = struct('C', num2cell(v));
    case 'mlp'
        [HH, ll] = ndgrid(cfg.mlp.H, cfg.mlp.lambda);
        grid = struct('H', num2cell(HH(:)), 'lambda', num2cell(ll(:)));
    case 'rbfnet'
        [JJ, kk, ll] = ndgrid(cfg.rbf.J, cfg.rbf.kappa, cfg.rbf.lambda);
        grid = struct('J', num2cell(JJ(:)), 'kappa', num2cell(kk(:)), ...
            'lambda', num2cell(ll(:)));
    otherwise
        error('tune_cv: nezinomas modelis %s.', modelName);
end
grid = grid(:);
end

function sc = fold_score(modelName, Ztr, ytr, Zva, hp, cfg, seed)
switch modelName
    case 'majority'
        sc = zeros(size(Zva, 1), 1);
    case 'logreg'
        mdl = train_logreg(Ztr, ytr, hp.lambda, cfg);
        sc = Zva * mdl.Mdl.Beta + mdl.Mdl.Bias;
    case 'svm_rbf'
        mdl = train_svm_rbf(Ztr, ytr, hp.C, hp.s, cfg, 'gaussian');
        sc = svm_score_pos(mdl, Zva);
    case 'svm_linear'
        mdl = train_svm_rbf(Ztr, ytr, hp.C, 1, cfg, 'linear');
        sc = svm_score_pos(mdl, Zva);
    case 'mlp'
        acc = zeros(size(Zva, 1), 1);
        seeds = cfg.mlp.seeds;
        for i = 1:numel(seeds)
            mdl = train_mlp(Ztr, ytr, hp.H, hp.lambda, seeds(i), cfg);
            [p, ~, ~] = predict_proba(mdl, Zva, 0.5);
            acc = acc + p;
        end
        sc = acc / numel(seeds);
    case 'rbfnet'
        mdl = train_rbfnet(Ztr, ytr, hp.J, hp.kappa, hp.lambda, seed);
        nva = size(Zva, 1);
        Phi = zeros(nva, mdl.J);
        for j = 1:mdl.J
            d2 = sum((Zva - mdl.centers(j, :)).^2, 2);
            Phi(:, j) = exp(-d2 ./ (2 * mdl.widths(j).^2));
        end
        sc = [ones(nva, 1), Phi] * mdl.w;
    otherwise
        error('fold_score: %s', modelName);
end
sc = sc(:);
end

function model = train_final(modelName, Z, y, hp, cfg)
switch modelName
    case 'majority'
        model = train_majority(y);
    case 'logreg'
        model = train_logreg(Z, y, hp.lambda, cfg);
    case 'svm_rbf'
        model = train_svm_rbf(Z, y, hp.C, hp.s, cfg, 'gaussian');
    case 'svm_linear'
        model = train_svm_rbf(Z, y, hp.C, 1, cfg, 'linear');
    case 'mlp'
        seeds = cfg.mlp.seeds;
        nets = cell(1, numel(seeds));
        for i = 1:numel(seeds)
            tmp = train_mlp(Z, y, hp.H, hp.lambda, seeds(i), cfg);
            nets{i} = tmp.net;
        end
        model = struct('kind', 'mlp', 'nets', {nets}, 'H', hp.H, ...
            'lambda', hp.lambda, 'seeds', seeds);
    case 'rbfnet'
        model = train_rbfnet(Z, y, hp.J, hp.kappa, hp.lambda, cfg.seed);
    otherwise
        error('train_final: %s', modelName);
end
end

function tf = is_simpler(a, b, modelName)
switch modelName
    case 'logreg'
        tf = a.lambda > b.lambda;
    case 'svm_rbf'
        if a.C ~= b.C
            tf = a.C < b.C;
        else
            tf = a.s > b.s;
        end
    case 'svm_linear'
        tf = a.C < b.C;
    case 'mlp'
        if a.H ~= b.H
            tf = a.H < b.H;
        else
            tf = a.lambda > b.lambda;
        end
    case 'rbfnet'
        if a.J ~= b.J
            tf = a.J < b.J;
        else
            tf = a.lambda > b.lambda;
        end
    otherwise
        tf = false;
end
end

function sc = svm_score_pos(mdl, Z)
[~, raw] = predict(mdl.Mdl, Z);
if size(raw, 2) == 2
    sc = raw(:, 2);
else
    sc = raw(:);
end
end

function s = hp_str(hp)
if isempty(hp)
    s = '(none)';
    return
end
f = fieldnames(hp);
parts = cell(size(f));
for i = 1:numel(f)
    parts{i} = sprintf('%s=%g', f{i}, hp.(f{i}));
end
s = strjoin(parts, ', ');
end
