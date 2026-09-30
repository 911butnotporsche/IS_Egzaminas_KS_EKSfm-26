function audit_dump()
%AUDIT_DUMP Tikrina skaidini, metrikas ir M4 laukus. Nieko nepermoko.
root = fileparts(fileparts(mfilename('fullpath')));
if isempty(root) || ~exist(fullfile(root, 'config.m'), 'file')
    root = pwd;
end
addpath(root);
addpath(fullfile(root, 'data'));
addpath(fullfile(root, 'prep'));
addpath(fullfile(root, 'models'));
addpath(fullfile(root, 'evalx'));
cfg = config();
out = fullfile(cfg.paths.reports, 'audit_snapshot.txt');
fid = fopen(out, 'w');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>

W = load(fullfile(cfg.paths.processed, 'wdbc.mat'), 'X', 'y', 'featNames');
sp = load(fullfile(cfg.paths.processed, 'split_idx.mat'), 'idxTrain', 'idxTest', 'seed');
y = W.y(:);
tr = sp.idxTrain(:);
te = sp.idxTest(:);
fprintf(fid, 'seed_file=%g\n', sp.seed);
fprintf(fid, 'n=%d nTrain=%d nTest=%d overlap=%d\n', numel(y), numel(tr), numel(te), numel(intersect(tr, te)));
fprintf(fid, 'train M=%d B=%d\n', sum(y(tr)==1), sum(y(tr)==0));
fprintf(fid, 'test M=%d B=%d\n', sum(y(te)==1), sum(y(te)==0));
fprintf(fid, 'cover=%d\n', numel(union(tr, te)));

T = readtable(fullfile(cfg.paths.tables, 'main_results.csv'), 'TextType', 'string', 'VariableNamingRule', 'preserve');
fprintf(fid, '\n== main_results identity ==\n');
for i = 1:height(T)
    tp = T.TP(i); fn = T.FN(i); tn = T.TN(i); fp = T.FP(i);
    n = tp + fn + tn + fp;
    se = tp / max(tp + fn, 1);
    spv = tn / max(tn + fp, 1);
    dse = abs(se - T.Se(i));
    dsp = abs(spv - T.Sp(i));
    if dse > 1e-9 || dsp > 1e-9 || n ~= 114
        fprintf(fid, 'MISMATCH %s %s n=%d dSe=%.3g dSp=%.3g\n', T.model(i), T.point(i), n, dse, dsp);
    end
end
fprintf(fid, 'identity_rows=%d\n', height(T));

S = load(fullfile(cfg.paths.processed, 'test_predictions.mat'), 'pack', 'ytest');
ytest = S.ytest(:);
fprintf(fid, 'pred_n=%d pred_M=%d pred_B=%d\n', numel(ytest), sum(ytest==1), sum(ytest==0));
names = {'majority','logreg','svm_rbf','mlp','rbfnet','ensemble'};
fprintf(fid, '\n== recompute t_se98 ==\n');
for i = 1:numel(names)
    nm = names{i};
    t = S.pack.(nm).thresholds.t_se98;
    p = S.pack.(nm).p;
    m = metrics(ytest, p, t);
    auc = roc_auc(ytest, S.pack.(nm).score);
    bs = brier(ytest, p);
    fprintf(fid, '%s t=%.4f Se=%.6f Sp=%.6f FN=%d FP=%d TP=%d TN=%d n=%d AUC=%.6f BS=%.6f\n', ...
        nm, t, m.Se, m.Sp, m.FN, m.FP, m.TP, m.TN, m.n, auc, bs);
end
p0 = S.pack.majority.p;
fprintf(fid, 'B0_p_unique=%s prior_formula_170_455=%.6f BS_if_prior=%.6f BS_if_zero=%.6f\n', ...
    mat2str(unique(p0)', 6), 170/455, ...
    (42*(170/455-1)^2 + 72*(170/455)^2)/114, 42/114);

E = load(fullfile(cfg.paths.models, 'ensemble.mat'));
fprintf(fid, '\n== M4 ==\n');
fprintf(fid, 'nTrain=%d use_selection=%d\n', E.nTrain, E.use_selection);
fprintf(fid, 'weights=%s\n', mat2str(E.weights, 4));
fprintf(fid, 'weights_equal=%s\n', mat2str(E.weights_equal, 4));
fprintf(fid, 'hp d=%g s=%g C=%g\n', E.hp.d, E.hp.s, E.hp.C);
fprintf(fid, 'lr_lambda=%g mlp_H=%g mlp_lambda=%g\n', E.hp_logreg.lambda, E.hp_mlp.H, E.hp_mlp.lambda);
fprintf(fid, 't_se98=%g t_cost=%g se_target_met=%d\n', E.thresholds.t_se98, E.thresholds.t_cost, E.se_target_met);
fprintf(fid, 'feat_cols=%s\n', mat2str(E.feat_cols));
fn = W.featNames;
if isrow(fn), fn = fn(:)'; end
kept = fn(E.feat_cols);
fprintf(fid, 'kept=');
fprintf(fid, '%s ', kept{:});
fprintf(fid, '\n');
fprintf(fid, 'members=%s\n', strjoin(E.model.member_names, ','));
for k = 1:numel(E.model.members)
    mem = E.model.members{k};
    fprintf(fid, 'member %s kind=%s has_platt=%d\n', E.model.member_names{k}, mem.kind, isfield(mem, 'platt') && ~isempty(mem.platt));
    if isfield(mem, 'platt') && ~isempty(mem.platt)
        fprintf(fid, '  platt A=%g B=%g\n', mem.platt.A, mem.platt.B);
    end
end

files = {'majority','logreg','svm_rbf','mlp','rbfnet','svm_poly','ensemble','ensemble_noselect'};
fprintf(fid, '\n== model nTrain ==\n');
for i = 1:numel(files)
    R = load(fullfile(cfg.paths.models, [files{i} '.mat']), 'nTrain');
    fprintf(fid, '%s nTrain=%d\n', files{i}, R.nTrain);
end
fprintf('audit_dump -> %s\n', out);
end
