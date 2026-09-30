function result = train_ensemble(Xtrain, ytrain, cvInner, cfg, idxTrain, idxTest, saveName, useSelection)
%TRAIN_ENSEMBLE M4. Nariai: polinominis SVM, MLP, logistine regresija.
%  Vidinėje kryžminėje patikroje — select_features (|r|>0.95) ir OOF balai.
%  Platt sigmoidė kiekvienam nariui tik iš OOF. Svoriai žingsniu 0,1
%  minimizuoja OOF empirinę kainą tarp variantų su Se >= 0,98. Formulė (8).

if nargin < 7 || isempty(saveName)
    saveName = 'ensemble';
end
if nargin < 8 || isempty(useSelection)
    useSelection = true;
end
ytrain = ytrain(:);
idxTrain = idxTrain(:);
idxTest = idxTest(:);
n = size(Xtrain, 1);
p = size(Xtrain, 2);
if n ~= numel(ytrain) || n ~= numel(idxTrain)
    error('train_ensemble: Xtrain, ytrain ir idxTrain ilgiai nesutampa.');
end
if n == 569
    error('WDBC:Ensemble:FullSet', 'train_ensemble: n=569 — tik mokymo dalis.');
end
if any(ismember(idxTrain, idxTest))
    error('train_ensemble: idxTrain persidengia su idxTest.');
end
if cvInner.n ~= n
    error('train_ensemble: cvInner.n=%d, o mokymo eiluciu %d.', cvInner.n, n);
end

hpLr = load_member_hp(cfg, 'logreg', n);
hpMlp = load_member_hp(cfg, 'mlp', n);
[grid, nG] = poly_grid(cfg);

fprintf('train_ensemble [%s] selection=%d: %d polinomo konfig. x %d skaidiniai\n', ...
    saveName, useSelection, nG, cvInner.nPartitions);

oofSvmSum = zeros(n, nG);
oofLrSum = zeros(n, 1);
oofMlpSum = zeros(n, 1);
oofCnt = zeros(n, 1);
foldAuc = zeros(cvInner.repeats, cvInner.k, nG);

for r = 1:cvInner.repeats
    for f = 1:cvInner.k
        rng(cfg.seed + 1000 * r + f, 'twister');
        tr = training(cvInner.cv{r}, f);
        va = test(cvInner.cv{r}, f);
        if any(ismember(idxTrain(tr), idxTest))
            error('train_ensemble: testo indeksas pateko i foldo fit.');
        end
        cols = columns_for_fold(Xtrain(tr, :), ytrain(tr), cfg, useSelection, p);
        sc = fit_scaler(Xtrain(tr, cols), cfg);
        Ztr = apply_scaler(Xtrain(tr, cols), sc);
        Zva = apply_scaler(Xtrain(va, cols), sc);
        ytr = ytrain(tr);
        mdlLr = train_logreg(Ztr, ytr, hpLr.lambda, cfg);
        oofLrSum(va) = oofLrSum(va) + (Zva * mdlLr.Beta + mdlLr.Bias);
        oofMlpSum(va) = oofMlpSum(va) + mlp_logit(Ztr, ytr, Zva, hpMlp, cfg);
        for g = 1:nG
            mdlS = train_svm_poly(Ztr, ytr, grid(g).C, grid(g).s, grid(g).d, cfg);
            scVa = svm_poly_score(mdlS, Zva);
            oofSvmSum(va, g) = oofSvmSum(va, g) + scVa;
            foldAuc(r, f, g) = roc_auc(ytrain(va), scVa);
        end
        oofCnt(va) = oofCnt(va) + 1;
        fprintf('  fold r=%d f=%d požymiai=%d\n', r, f, numel(cols));
    end
end
if any(oofCnt == 0)
    error('train_ensemble: OOF nepadengia visos mokymo dalies.');
end

aucMean = squeeze(mean(foldAuc, [1 2]));
aucMean = aucMean(:);
[maxAuc, ~] = max(aucMean);
idxCand = find(aucMean >= maxAuc - 0.002 - 1e-12);
bestG = idxCand(1);
for ii = 2:numel(idxCand)
    gNew = idxCand(ii);
    if is_simpler_poly(grid(gNew), grid(bestG))
        bestG = gNew;
    elseif ~is_simpler_poly(grid(bestG), grid(gNew)) && aucMean(gNew) > aucMean(bestG)
        bestG = gNew;
    end
end
hpPoly = grid(bestG);
fprintf('  polinomas AUC=%.4f d=%g s=%g C=%g\n', aucMean(bestG), hpPoly.d, hpPoly.s, hpPoly.C);

oofSvm = oofSvmSum(:, bestG) ./ oofCnt;
oofLr = oofLrSum ./ oofCnt;
oofMlp = oofMlpSum ./ oofCnt;
plattS = calibrate_platt(oofSvm, ytrain);
plattM = calibrate_platt(oofMlp, ytrain);
plattL = calibrate_platt(oofLr, ytrain);
P = [platt_apply(plattS, oofSvm), platt_apply(plattM, oofMlp), platt_apply(plattL, oofLr)];

[wOpt, thrOpt, ecOpt] = choose_weights(P, ytrain, cfg);
cfgFit = cfg;
if ~thrOpt.se_target_met
    fprintf('train_ensemble: OOF Se < 0.98, 4.3 seka (C ir klasiu svoriai).\n');
    [hpPoly, P, plattS, plattM, plattL, wOpt, thrOpt, ecOpt, aucMean, bestG, cfgFit] = ...
        improve_sensitivity(Xtrain, ytrain, cvInner, cfg, idxTrain, idxTest, ...
        useSelection, hpLr, hpMlp, hpPoly);
end
wEq = [1 1 1] / 3;
cfgLoose = cfgFit;
cfgLoose.threshold.require_se = false;
thrEq = choose_threshold(P * wEq(:), ytrain, cfgLoose);

cols = columns_for_fold(Xtrain, ytrain, cfgFit, useSelection, p);
scaler = fit_scaler(Xtrain(:, cols), cfgFit);
Zall = apply_scaler(Xtrain(:, cols), scaler);
memberS = train_svm_poly(Zall, ytrain, hpPoly.C, hpPoly.s, hpPoly.d, cfgFit);
memberS.platt = plattS;
memberM = train_mlp_bundle(Zall, ytrain, hpMlp, cfgFit);
memberM.platt = plattM;
memberL = train_logreg(Zall, ytrain, hpLr.lambda, cfgFit);
memberL.platt = plattL;

model = struct();
model.kind = 'ensemble';
model.members = {memberS, memberM, memberL};
model.member_names = {'svm_poly', 'mlp', 'logreg'};
model.weights = wOpt;
model.weights_equal = wEq;
model.platt = [];
model.thresholds = thrOpt;
model.scaler = scaler;
model.feat_cols = cols;

pOof = P * wOpt(:);
result = struct();
result.model = model;
result.hp = hpPoly;
result.hp_logreg = hpLr;
result.hp_mlp = hpMlp;
result.oof_score = pOof;
result.oof_p = pOof;
result.oof_members = P;
result.cv_auc_mean = aucMean(bestG);
result.cv_auc_grid = aucMean;
result.thresholds = thrOpt;
result.thresholds_equal = thrEq;
result.weights = wOpt;
result.weights_equal = wEq;
result.ec_oof = ecOpt;
result.use_selection = logical(useSelection);
result.feat_cols = cols;
result.modelName = 'ensemble';
result.saveName = saveName;
result.nTrain = n;
result.se_target_met = logical(thrOpt.se_target_met);

if ~exist(cfg.paths.models, 'dir')
    mkdir(cfg.paths.models);
end
outPath = fullfile(cfg.paths.models, [saveName '.mat']);
save(outPath, '-struct', 'result', '-v7');
result.path = outPath;
fprintf('train_ensemble [%s] svoriai=[%.2f %.2f %.2f] t_se98=%.2f Se_ok=%d -> %s\n', ...
    saveName, wOpt(1), wOpt(2), wOpt(3), thrOpt.t_se98, result.se_target_met, outPath);
end

function cols = columns_for_fold(X, y, cfg, useSelection, pAll)
if useSelection
    sel = select_features(X, y, cfg);
    cols = sel.keep;
    if isempty(cols)
        error('train_ensemble: požymių atranka nepaliko nė vieno požymio.');
    end
else
    cols = 1:pAll;
end
end

function [grid, nG] = poly_grid(cfg)
[DD, SS] = ndgrid(cfg.svm_poly.degree, cfg.svm_poly.scale);
d = DD(:);
s = SS(:);
nG = numel(d);
grid = repmat(struct('d', 0, 's', 0, 'C', cfg.svm_poly.C), nG, 1);
for i = 1:nG
    grid(i).d = d(i);
    grid(i).s = s(i);
    grid(i).C = cfg.svm_poly.C;
end
end

function tf = is_simpler_poly(a, b)
if a.d ~= b.d
    tf = a.d < b.d;
elseif a.C ~= b.C
    tf = a.C < b.C;
else
    tf = a.s > b.s;
end
end

function hp = load_member_hp(cfg, name, nTrain)
path = fullfile(cfg.paths.models, [name '.mat']);
if exist(path, 'file') ~= 2
    error('train_ensemble: nera %s. Pirma tune_cv(''%s'').', path, name);
end
R = load(path, 'hp', 'nTrain');
if ~isfield(R, 'nTrain') || R.nTrain ~= nTrain
    error('train_ensemble: %s apmokytas ant n=%s, o dabar n=%d.', ...
        name, mat2str(getfield_default(R, 'nTrain', NaN)), nTrain);
end
hp = R.hp;
end

function v = getfield_default(s, name, fallback)
if isfield(s, name)
    v = s.(name);
else
    v = fallback;
end
end

function z = mlp_logit(Ztr, ytr, Zva, hp, cfg)
seeds = cfg.mlp.seeds;
acc = zeros(size(Zva, 1), 1);
for i = 1:numel(seeds)
    mdl = train_mlp(Ztr, ytr, hp.H, hp.lambda, seeds(i), cfg);
    [p, ~, ~] = predict_proba(mdl, Zva, 0.5);
    acc = acc + p;
end
p = acc / numel(seeds);
p = min(max(p, 1e-15), 1 - 1e-15);
z = log(p ./ (1 - p));
end

function model = train_mlp_bundle(Z, y, hp, cfg)
seeds = cfg.mlp.seeds;
nets = cell(1, numel(seeds));
for i = 1:numel(seeds)
    tmp = train_mlp(Z, y, hp.H, hp.lambda, seeds(i), cfg);
    nets{i} = tmp.net;
end
model = struct('kind', 'mlp', 'nets', {nets}, 'H', hp.H, ...
    'lambda', hp.lambda, 'seeds', seeds);
end

function [wBest, thrBest, ecBest] = choose_weights(P, y, cfg)
step = cfg.ensemble.weight_step;
vals = 0:step:1;
cfgL = cfg;
cfgL.threshold.require_se = false;
bestKey = [inf, inf];
wBest = [1 1 1] / 3;
thrBest = choose_threshold(P * wBest(:), y, cfgL);
ecBest = inf;
for i = 1:numel(vals)
    for j = 1:numel(vals)
        for k = 1:numel(vals)
            w = [vals(i), vals(j), vals(k)];
            if sum(w) <= 0
                continue
            end
            w = w / sum(w);
            p = P * w(:);
            thr = choose_threshold(p, y, cfgL);
            if ~thr.se_target_met
                continue
            end
            spread = sum((w - 1/3).^2);
            key = [thr.EC_se98, spread];
            if key(1) < bestKey(1) - 1e-9 || ...
                    (abs(key(1) - bestKey(1)) <= 1e-9 && key(2) < bestKey(2))
                bestKey = key;
                wBest = w;
                thrBest = thr;
                ecBest = thr.EC_se98;
            end
        end
    end
end
if ~isfinite(ecBest)
    p = P * wBest(:);
    thrBest = choose_threshold(p, y, cfgL);
    ecBest = thrBest.EC_se98;
    thrBest.se_target_met = false;
end
end

function [hpPoly, P, plattS, plattM, plattL, wOpt, thrOpt, ecOpt, aucMean, bestG, cfgFit] = ...
        improve_sensitivity(Xtrain, ytrain, cvInner, cfg, idxTrain, idxTest, ...
        useSelection, hpLr, hpMlp, hpPoly)
% 4.3 žingsnis 1: C ir kainų santykis aplink 5:1, kol OOF Se >= 0,98 arba tinklelis baigiasi.
Cgrid = cfg.svm.C;
ratios = [3 5 7 10];
bestPack = [];
bestSe = -inf;
cfgFit = cfg;
for ic = 1:numel(Cgrid)
    for ir = 1:numel(ratios)
        cfgC = cfg;
        cfgC.cost = [ratios(ir), 1];
        cfgC.costMatrix = [0, 1; ratios(ir), 0];
        cfgC.svm_poly.C = Cgrid(ic);
        fprintf('  4.3 C=%g santykis=%d:1\n', Cgrid(ic), ratios(ir));
        pack = oof_fixed_poly(Xtrain, ytrain, cvInner, cfgC, idxTrain, idxTest, ...
            useSelection, hpLr, hpMlp, hpPoly.d, hpPoly.s, Cgrid(ic));
        pack.cfg = cfgC;
        if pack.thr.se_target_met
            bestPack = pack;
            break
        end
        seNow = pack.thr.se_at_t_se98;
        if isempty(bestPack) || seNow > bestSe
            bestSe = seNow;
            bestPack = pack;
        end
    end
    if ~isempty(bestPack) && bestPack.thr.se_target_met
        break
    end
end
hpPoly = bestPack.hpPoly;
P = bestPack.P;
plattS = bestPack.plattS;
plattM = bestPack.plattM;
plattL = bestPack.plattL;
wOpt = bestPack.w;
thrOpt = bestPack.thr;
ecOpt = bestPack.thr.EC_se98;
aucMean = bestPack.aucMean;
bestG = 1;
cfgFit = bestPack.cfg;
if ~thrOpt.se_target_met
    fprintf('train_ensemble: Se riba OOF nepasiekta. Slenkstis = didziausias OOF Se.\n');
end
end

function pack = oof_fixed_poly(Xtrain, ytrain, cvInner, cfg, idxTrain, idxTest, ...
        useSelection, hpLr, hpMlp, d, s, C)
n = size(Xtrain, 1);
p = size(Xtrain, 2);
oofS = zeros(n, 1);
oofL = zeros(n, 1);
oofM = zeros(n, 1);
cnt = zeros(n, 1);
aucs = [];
for r = 1:cvInner.repeats
    for f = 1:cvInner.k
        tr = training(cvInner.cv{r}, f);
        va = test(cvInner.cv{r}, f);
        if any(ismember(idxTrain(tr), idxTest))
            error('train_ensemble: testo indeksas 4.3 folde.');
        end
        cols = columns_for_fold(Xtrain(tr, :), ytrain(tr), cfg, useSelection, p);
        sca = fit_scaler(Xtrain(tr, cols), cfg);
        Ztr = apply_scaler(Xtrain(tr, cols), sca);
        Zva = apply_scaler(Xtrain(va, cols), sca);
        ytr = ytrain(tr);
        mdlL = train_logreg(Ztr, ytr, hpLr.lambda, cfg);
        oofL(va) = oofL(va) + (Zva * mdlL.Beta + mdlL.Bias);
        oofM(va) = oofM(va) + mlp_logit(Ztr, ytr, Zva, hpMlp, cfg);
        mdlS = train_svm_poly(Ztr, ytr, C, s, d, cfg);
        scVa = svm_poly_score(mdlS, Zva);
        oofS(va) = oofS(va) + scVa;
        aucs(end+1, 1) = roc_auc(ytrain(va), scVa); %#ok<AGROW>
        cnt(va) = cnt(va) + 1;
    end
end
oofS = oofS ./ cnt;
oofL = oofL ./ cnt;
oofM = oofM ./ cnt;
plattS = calibrate_platt(oofS, ytrain);
plattM = calibrate_platt(oofM, ytrain);
plattL = calibrate_platt(oofL, ytrain);
P = [platt_apply(plattS, oofS), platt_apply(plattM, oofM), platt_apply(plattL, oofL)];
[w, thr, ~] = choose_weights(P, ytrain, cfg);
pack = struct('P', P, 'plattS', plattS, 'plattM', plattM, 'plattL', plattL, ...
    'w', w, 'thr', thr, 'hpPoly', struct('d', d, 's', s, 'C', C), ...
    'aucMean', mean(aucs));
end
