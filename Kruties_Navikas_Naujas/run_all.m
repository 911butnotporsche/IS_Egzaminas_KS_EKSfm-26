function run_all(mode)
%RUN_ALL Viena komanda: duomenys, 455/114 skaidinys, mokymas, testas, CSV, grafikai.
%  Kiekvienas paleidimas išvalo test_unlocked.flag. Ankstesnė evaluate_test
%  versija mesdavo WDBC:Eval:AlreadyUnlocked, jei vėliavėlė jau buvo, todėl
%  antras run_all lūždavo arba praleisdavo testą ir palikdavo senus grafikus.
%
%  run_all        — švarūs rezultatai; modeliai permokomi, jei jų nėra
%  run_all('clean') — ištrina models/*.mat ir permoko viską iš naujo

if nargin < 1 || isempty(mode)
    mode = 'run';
end
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'data'));
addpath(fullfile(root, 'prep'));
addpath(fullfile(root, 'models'));
addpath(fullfile(root, 'evalx'));
addpath(fullfile(root, 'app'));
addpath(fullfile(root, 'tests'));

cfg = config();
rng(cfg.seed, 'twister');
prepare_clean_run(cfg, mode);

fprintf('\n=== a) duomenu patikra ===\n');
raw = get_wdbc(cfg);
S = load_wdbc(cfg, raw);
if ~isequal(size(S.X), [569 30]) || sum(S.y == 1) ~= 212 || sum(S.y == 0) ~= 357
    error('run_all: WDBC turi buti 569 x 30, 212 piktybiniai, 357 gerybiniai.');
end

fprintf('\n=== b) skaidymas 455/114, rng(42) ===\n');
split = make_split(S.X, S.y, cfg);
if split.nTrain ~= 455 || split.nTest ~= 114
    error('run_all: skaidinys turi buti 455/114, gauta %d/%d.', split.nTrain, split.nTest);
end

fprintf('\n=== c) skaliatorius tik is mokymo ===\n');
Xtrain = S.X(split.idxTrain, :);
ytrain = S.y(split.idxTrain);
scaler = fit_scaler(Xtrain, cfg);
apply_scaler(Xtrain, scaler);
apply_scaler(S.X(split.idxTest, :), scaler);
cvInner = make_inner_cv(ytrain, cfg);
assert(cvInner.nPartitions == 25);

fprintf('\n=== vieneto testai (testas dar nevertinamas) ===\n');
results = runtests(fullfile(root, 'tests'));
if any([results.Failed])
    error('run_all: testai nepraejo — testavimas nestabdomas klaidinga grandine.');
end

fprintf('\n=== d) modeliu mokymas ===\n');
names = {'majority', 'logreg', 'svm_rbf', 'mlp', 'rbfnet', 'svm_poly'};
for i = 1:numel(names)
    if exist(fullfile(cfg.paths.models, [names{i} '.mat']), 'file') ~= 2
        tune_cv(Xtrain, ytrain, cvInner, cfg, names{i}, split.idxTrain, split.idxTest);
    end
end
if exist(fullfile(cfg.paths.models, 'svm_linear.mat'), 'file') ~= 2
    res = tune_cv(Xtrain, ytrain, cvInner, cfg, 'svm_linear', ...
        split.idxTrain, split.idxTest, 'svm_linear');
    res.feat_cols = 1:30;
    save(res.path, '-struct', 'res', '-v7');
end
if exist(fullfile(cfg.paths.models, 'svm_mean.mat'), 'file') ~= 2
    cols = 1:10;
    res = tune_cv(Xtrain(:, cols), ytrain, cvInner, cfg, 'svm_rbf', ...
        split.idxTrain, split.idxTest, 'svm_mean');
    res.feat_cols = cols;
    save(res.path, '-struct', 'res', '-v7');
end
if exist(fullfile(cfg.paths.models, 'svm_worst.mat'), 'file') ~= 2
    cols = 21:30;
    res = tune_cv(Xtrain(:, cols), ytrain, cvInner, cfg, 'svm_rbf', ...
        split.idxTrain, split.idxTest, 'svm_worst');
    res.feat_cols = cols;
    save(res.path, '-struct', 'res', '-v7');
end
if exist(fullfile(cfg.paths.models, 'ensemble.mat'), 'file') ~= 2
    train_ensemble(Xtrain, ytrain, cvInner, cfg, split.idxTrain, split.idxTest, ...
        'ensemble', true);
end
if exist(fullfile(cfg.paths.models, 'ensemble_noselect.mat'), 'file') ~= 2
    train_ensemble(Xtrain, ytrain, cvInner, cfg, split.idxTrain, split.idxTest, ...
        'ensemble_noselect', false);
end

write_freeze(cfg, root, split);

fprintf('\n=== e-f) testavimas 114 atveju ir CSV ===\n');
evaluate_test(cfg);

fprintf('\n=== g) grafikai ===\n');
make_report_plots();

write_one_case(cfg);
fprintf('\n=== prototipas ===\n');
ex = fullfile(cfg.paths.examples, 'one_case.csv');
out = predict_case(ex, cfg);
fprintf('predict_case: decision=%s p=%.12g t=%.4f margin=%d ood=%d\n', ...
    out.decision, out.p_malignant, out.threshold, out.margin_flag, out.ood_flag);
fprintf('%s\n', out.disclaimer);
r5 = runtests(fullfile(root, 'tests', 'test_predict_case.m'));
if any([r5.Failed])
    error('run_all: test_predict_case nepraejo.');
end

fprintf('run_all baigtas be klaidu. Testas n=%d.\n', split.nTest);
end

function prepare_clean_run(cfg, mode)
lockPath = fullfile(cfg.paths.reports, 'test_unlocked.flag');
if exist(lockPath, 'file') == 2
    delete(lockPath);
    fprintf('pasalinta %s\n', lockPath);
end
stale = { ...
    fullfile(cfg.paths.tables, 'h3_nested.csv'), ...
    fullfile(cfg.paths.processed, 'h3.mat')};
for i = 1:numel(stale)
    if exist(stale{i}, 'file') == 2
        delete(stale{i});
        fprintf('pasalintas senas H3 likutis %s\n', stale{i});
    end
end
if strcmpi(mode, 'clean')
    mats = dir(fullfile(cfg.paths.models, '*.mat'));
    for i = 1:numel(mats)
        delete(fullfile(mats(i).folder, mats(i).name));
    end
    fprintf('run_all(''clean''): models/*.mat istrinti, bus permokyti.\n');
end
end

function write_one_case(cfg)
if ~exist(cfg.paths.examples, 'dir')
    mkdir(cfg.paths.examples);
end
W = load(fullfile(cfg.paths.processed, 'wdbc.mat'), 'X', 'featNames');
sp = load(fullfile(cfg.paths.processed, 'split_idx.mat'), 'idxTest');
absIdx = sp.idxTest(1);
x = W.X(absIdx, :);
featNames = W.featNames;
if isrow(featNames)
    featNames = featNames(:)';
end
T = array2table(x, 'VariableNames', featNames);
writetable(T, fullfile(cfg.paths.examples, 'one_case.csv'));
fid = fopen(fullfile(cfg.paths.examples, 'one_case_idx.txt'), 'w');
fprintf(fid, '%d\n', absIdx);
fclose(fid);
end

function write_freeze(cfg, root, split)
paths = { ...
    fullfile(root, 'reports', 'preregistration.md'), ...
    split.path, ...
    fullfile(root, 'config.m'), ...
    fullfile(cfg.paths.models, 'majority.mat'), ...
    fullfile(cfg.paths.models, 'logreg.mat'), ...
    fullfile(cfg.paths.models, 'svm_rbf.mat'), ...
    fullfile(cfg.paths.models, 'mlp.mat'), ...
    fullfile(cfg.paths.models, 'rbfnet.mat'), ...
    fullfile(cfg.paths.models, 'svm_poly.mat'), ...
    fullfile(cfg.paths.models, 'ensemble.mat'), ...
    fullfile(cfg.paths.models, 'ensemble_noselect.mat'), ...
    fullfile(cfg.paths.models, 'svm_linear.mat'), ...
    fullfile(cfg.paths.models, 'svm_mean.mat'), ...
    fullfile(cfg.paths.models, 'svm_worst.mat'), ...
    fullfile(cfg.paths.models, 'thresholds.json')};
out = fullfile(cfg.paths.reports, 'freeze.txt');
fid = fopen(out, 'w');
assert(fid > 0);
fprintf(fid, 'ALL FITS DONE. Test still locked until evaluate_test.m.\n');
fprintf(fid, 'split: train=%d (M=%d B=%d), test=%d (M=%d B=%d)\n', ...
    split.nTrain, split.nM_train, split.nB_train, split.nTest, split.nM_test, split.nB_test);
fprintf(fid, 'cost=5:1  H1_dSp=0.03  se_target=0.98  inner_cv=25\n');
for i = 1:numel(paths)
    p = paths{i};
    if exist(p, 'file')
        fprintf(fid, '%s  SHA-256=%s\n', p, file_sha256(p));
    else
        fprintf(fid, '%s  MISSING\n', p);
    end
end
fclose(fid);
fprintf('freeze.txt -> %s\n', out);
end

function h = file_sha256(path)
fid = fopen(path, 'r');
bytes = fread(fid, inf, '*uint8');
fclose(fid);
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(bytes);
digest = typecast(md.digest, 'uint8');
h = lower(sprintf('%02x', digest(:).'));
end
