function run_all()
%RUN_ALL 1–5 etapai. Testas atrakinamas lygiai vieną kartą; tada predict_case.

root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'data'));
addpath(fullfile(root, 'prep'));
addpath(fullfile(root, 'models'));
addpath(fullfile(root, 'evalx'));
addpath(fullfile(root, 'app'));
addpath(fullfile(root, 'tests'));

cfg = config();
rng(cfg.seed, 'twister');

fprintf('\n=== 1 etapas: duomenu gavimas ===\n');
raw = get_wdbc(cfg);
S = load_wdbc(cfg, raw);

fprintf('\n=== 2 etapas: skaidymas ir preprocessing ===\n');
split = make_split(S.X, S.y, cfg);
Xtrain = S.X(split.idxTrain, :);
Xtest  = S.X(split.idxTest, :); %#ok<NASGU>
ytrain = S.y(split.idxTrain);
ytest  = S.y(split.idxTest); %#ok<NASGU>
scaler = fit_scaler(Xtrain, cfg);
Ztrain = apply_scaler(Xtrain, scaler); %#ok<NASGU>
Ztest = apply_scaler(S.X(split.idxTest, :), scaler); %#ok<NASGU>
cvInner = make_inner_cv(ytrain, cfg);
assert(cvInner.nPartitions == 25);

fprintf('\n=== Testai pries 4 etapa ===\n');
results = runtests(fullfile(root, 'tests'));
disp(table({results.Name}', [results.Passed]', [results.Failed]', ...
    'VariableNames', {'Name', 'Passed', 'Failed'}));
if any([results.Failed])
    error('run_all: testai nepraejo — testas neatrakinamas.');
end

needMain = exist(fullfile(cfg.paths.models, 'svm_rbf.mat'), 'file') ~= 2;
if needMain
    fprintf('\n=== 3 etapas (truksta modeliu) ===\n');
    names = {'majority', 'logreg', 'svm_rbf', 'mlp', 'rbfnet'};
    for i = 1:numel(names)
        tune_cv(Xtrain, ytrain, cvInner, cfg, names{i}, split.idxTrain, split.idxTest);
    end
end

fprintf('\n=== 4 etapas A: A2/A5 mokymas (testas dar uzrakintas) ===\n');
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

write_freeze(cfg, root, split);

fprintf('\n=== 4 etapas B: evaluate_test VIENA karta ===\n');
lockPath = fullfile(cfg.paths.reports, 'test_unlocked.flag');
if exist(lockPath, 'file') ~= 2
    evaluate_test(cfg);
else
    fprintf('evaluate_test praleista: test_unlocked.flag jau yra.\n');
end

write_one_case(cfg);

fprintf('\n=== 5 etapas: predict_case ===\n');
ex = fullfile(cfg.paths.examples, 'one_case.csv');
out = predict_case(ex, cfg);
fprintf('predict_case: decision=%s p=%.12g t=%.4f margin=%d ood=%d\n', ...
    out.decision, out.p_malignant, out.threshold, out.margin_flag, out.ood_flag);
fprintf('%s\n', out.disclaimer);
r5 = runtests(fullfile(root, 'tests', 'test_predict_case.m'));
if any([r5.Failed])
    error('run_all: test_predict_case nepraejo.');
end

if cfg.run.h3
    fprintf('\n=== H3 (po testo, H1 nekeicia): repeated_nested_cv ===\n');
    repeated_nested_cv(cfg);
end

fprintf('4 ir 5 etapai baigti.\n');
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
    fullfile(cfg.paths.models, 'svm_linear.mat'), ...
    fullfile(cfg.paths.models, 'svm_mean.mat'), ...
    fullfile(cfg.paths.models, 'svm_worst.mat'), ...
    fullfile(cfg.paths.models, 'thresholds.json')};
out = fullfile(cfg.paths.reports, 'freeze.txt');
fid = fopen(out, 'w');
assert(fid > 0);
fprintf(fid, 'ALL FITS DONE. Test still locked until evaluate_test.m.\n');
fprintf(fid, 'split: train=456 (170 M / 286 B), test=113 (42 M / 71 B)\n');
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
