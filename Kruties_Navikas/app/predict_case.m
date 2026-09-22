function out = predict_case(xin, cfg)
%PREDICT_CASE 5 etapas. 1 lentelė: p_malignant, threshold, decision {B,M},
%  margin_flag, ood_flag, model_version, disclaimer. Be žodžio „diagnozė“
%  (išskyrus privalomą atsakomybės sakinį). Fit nedaromas.

if nargin < 1
    error('predict_case: truksta 1x30 ivesciai (vektorius, struct, lentele arba CSV kelias).');
end
if nargin < 2 || isempty(cfg)
    cfg = config();
end

lockPath = fullfile(cfg.paths.reports, 'test_unlocked.flag');
if exist(lockPath, 'file') ~= 2
    error('predict_case: testas dar neatrakintas — pirma evaluate_test.m.');
end

addpath(fullfile(cfg.paths.root, 'prep'));
addpath(fullfile(cfg.paths.root, 'models'));
addpath(fullfile(cfg.paths.root, 'evalx'));

W = load(fullfile(cfg.paths.processed, 'wdbc.mat'), 'featNames');
featNames = W.featNames;
if isrow(featNames)
    featNames = featNames(:)';
end
x = parse_case(xin, featNames);
if any(~isfinite(x))
    error('predict_case: NaN/Inf draudziama — jokios tylios imputacijos.');
end
if any(x < 0)
    error('predict_case: neigiamos pozymiu reiksmes neleidziamos.');
end

[modelName, tName] = choose_frozen_model(cfg);
R = load(fullfile(cfg.paths.models, [modelName '.mat']));
model = R.model;
cols = 1:30;
if isfield(R, 'feat_cols')
    cols = R.feat_cols(:)';
end
if numel(cols) ~= numel(model.scaler.mu)
    error('predict_case: scaler dimensija nesutampa su feat_cols.');
end
xUsed = x(cols);
Z = apply_scaler(xUsed, model.scaler);
t = R.thresholds.(tName);
[p, ~, yhat] = predict_proba(model, Z, t);
p = p(1);
yhat = yhat(1);

xmin = model.scaler.xmin;
xmax = model.scaler.xmax;
ood_flag = any(xUsed < xmin - 1e-12 | xUsed > xmax + 1e-12);
margin_flag = abs(p - t) < 0.10;

if yhat == 1
    decision = 'M';
else
    decision = 'B';
end

hp = '';
if isfield(R, 'hp')
    hp = hp_brief(R.hp);
end
out = struct();
out.p_malignant = p;
out.threshold = t;
out.decision = decision;
out.margin_flag = logical(margin_flag);
out.ood_flag = logical(ood_flag);
out.model_version = sprintf('%s@%s;%s', modelName, tName, hp);
out.disclaimer = ['Tai mokomasis sprendimo palaikymo prototipas. Rezultatas n', ...
    char(279), 'ra klinikin', char(279), ' diagnoz', char(279), ...
    ' ir nepakei', char(269), 'ia gydytojo sprendimo.'];
end

function x = parse_case(xin, featNames)
if ischar(xin) || (isstring(xin) && isscalar(xin))
    pth = char(xin);
    if exist(pth, 'file') ~= 2
        error('predict_case: nerastas failas %s.', pth);
    end
    T = readtable(pth);
    x = table_to_x(T, featNames);
    return
end
if istable(xin)
    x = table_to_x(xin, featNames);
    return
end
if isstruct(xin)
    x = zeros(1, 30);
    for j = 1:30
        nm = featNames{j};
        if ~isfield(xin, nm)
            error('predict_case: struct neturi lauko %s.', nm);
        end
        v = xin.(nm);
        if ~isscalar(v) || ~isnumeric(v)
            error('predict_case: laukas %s turi buti skaliaras.', nm);
        end
        x(j) = v;
    end
    return
end
if isnumeric(xin)
    x = double(xin(:)');
    if numel(x) ~= 30
        error('predict_case: vektorius turi buti 1x30, gauta %d.', numel(x));
    end
    return
end
error('predict_case: neatpazinta ivedimo forma.');
end

function x = table_to_x(T, featNames)
if height(T) < 1
    error('predict_case: lentele tuscia.');
end
if height(T) > 1
    T = T(1, :);
end
vn = T.Properties.VariableNames;
if width(T) == 30 && isempty(intersect(vn, featNames))
    x = table2array(T);
    x = double(x(1, :));
    return
end
x = zeros(1, 30);
for j = 1:30
    nm = featNames{j};
    if ~ismember(nm, vn)
        error('predict_case: lenteleje nera stulpelio %s.', nm);
    end
    v = T.(nm);
    if iscell(v), v = v{1}; end
    v = double(v(1));
    if ~isscalar(v) || ~isfinite(v)
        error('predict_case: stulpelis %s nera baigtinis skaicius.', nm);
    end
    x(j) = v;
end
end

function [modelName, tName] = choose_frozen_model(cfg)
tName = 't_se98';
modelName = 'svm_rbf';
hypPath = fullfile(cfg.paths.tables, 'hypotheses.csv');
if exist(hypPath, 'file') ~= 2
    error('predict_case: nera hypotheses.csv — pirma evaluate_test.m.');
end
H = readtable(hypPath);
ix = find(strcmp(H.hypothesis, 'H1'), 1);
if isempty(ix)
    error('predict_case: hypotheses.csv neturi H1 eilutes.');
end
if H.accepted(ix) == 1
    modelName = 'svm_rbf';
    return
end
modelName = 'logreg';
mainPath = fullfile(cfg.paths.tables, 'main_results.csv');
if exist(mainPath, 'file') ~= 2
    return
end
M = readtable(mainPath);
spLin = pick_sp(M, 'svm_linear', tName);
spLr = pick_sp(M, 'logreg', tName);
if ~isnan(spLin) && ~isnan(spLr) && spLin > spLr
    modelName = 'svm_linear';
end
end

function sp = pick_sp(M, modelName, tName)
sp = NaN;
if ~ismember('model', M.Properties.VariableNames)
    return
end
hit = strcmp(M.model, modelName) & strcmp(M.point, tName);
if any(hit)
    sp = M.Sp(find(hit, 1));
end
end

function s = hp_brief(hp)
if ~isstruct(hp) || isempty(hp)
    s = '';
    return
end
f = fieldnames(hp);
parts = cell(size(f));
for i = 1:numel(f)
    parts{i} = sprintf('%s=%g', f{i}, hp.(f{i}));
end
s = strjoin(parts, ',');
end
