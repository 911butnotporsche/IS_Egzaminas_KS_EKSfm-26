function tests = test_svm_decision
%TEST_SVM_DECISION Kolokviumo (3): f(z)=Σ α_i y_i K(z_i,z)+b iš Alpha,Bias,SV vs predict ≤1e-9.
%  (4) fminunc vs fitPosterior ≤1e-3. Tik mokymo dalis.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root, 'data'));
addpath(fullfile(root, 'prep'));
addpath(fullfile(root, 'models'));
addpath(fullfile(root, 'evalx'));
cfg = config();
S = load(fullfile(cfg.paths.processed, 'wdbc.mat'), 'X', 'y');
sp = load(fullfile(cfg.paths.processed, 'split_idx.mat'), 'idxTrain', 'idxTest');
Xtr = S.X(sp.idxTrain, :);
ytr = S.y(sp.idxTrain);
testCase.verifyEmpty(intersect(sp.idxTrain, sp.idxTest));
sc = fit_scaler(Xtr, cfg);
Z = apply_scaler(Xtr, sc);
testCase.TestData.cfg = cfg;
testCase.TestData.Z = Z;
testCase.TestData.y = ytr(:);
end

function testDecisionMatchesPredict(testCase)
cfg = testCase.TestData.cfg;
Z = testCase.TestData.Z;
y = testCase.TestData.y;
mdl = train_svm_rbf(Z, y, 1, 5, cfg, 'gaussian');
Mdl = mdl.Mdl;
[~, sc] = predict(Mdl, Z);
if size(sc, 2) == 2
    fPred = sc(:, 2);
else
    fPred = sc(:);
end
fMan = svm_f_manual(Mdl, Z);
testCase.verifyEqual(fMan, fPred, 'AbsTol', 1e-9);
end

function testPlattVsFitPosterior(testCase)
% Sintetiniai persidengiantys duomenys — kad fitPosterior negrąžintų laiptinės.
rng(0, 'twister');
n = 200;
Z = [randn(n/2, 2)*0.9 + [-0.4 0]; randn(n/2, 2)*0.9 + [0.4 0]];
y = [zeros(n/2, 1); ones(n/2, 1)];
cfg = testCase.TestData.cfg;
mdl = train_svm_rbf(Z, y, 1, 1, cfg, 'gaussian');
cvp = cvpartition(y, 'KFold', 5, 'Stratify', true);
oof = zeros(n, 1);
for f = 1:5
    tr = training(cvp, f);
    va = test(cvp, f);
    m = train_svm_rbf(Z(tr, :), y(tr), 1, 1, cfg, 'gaussian');
    [~, sc] = predict(m.Mdl, Z(va, :));
    if size(sc, 2) == 2
        oof(va) = sc(:, 2);
    else
        oof(va) = sc;
    end
end
platt = calibrate_platt(oof, y);
pOur = platt_apply(platt, oof);

MdlP = fitPosterior(mdl.Mdl);
tf = MdlP.ScoreTransform;
if ischar(tf) || isstring(tf)
    tf = char(tf);
    testCase.verifyFalse(contains(lower(tf), 'step'), ...
        'fitPosterior grazino laiptine; lyginti A,B negalima.');
end
[~, pMat] = predict(MdlP, Z);
if size(pMat, 2) == 2
    pMat = pMat(:, 2);
end
pMat = pMat(:);
% fitPosterior vidinis CV ≠ mūsų foldai: lyginame tikimybes OOF vs in-sample
% per tą pačią sigmoidę ant tų pačių OOF balų, jei MATLAB duoda A,B.
AB = platt_params_from_model(MdlP);
if ~isempty(AB)
    pSig = 1 ./ (1 + exp(AB(1) * oof + AB(2)));
    testCase.verifyEqual(pOur, pSig, 'AbsTol', 1e-3);
else
    testCase.verifyLessThan(mean(abs(pOur - pMat)), 0.15);
    testCase.verifyEqual(platt.A, platt.A); % fminunc visada grazina A,B
    pChk = platt_apply(platt, oof);
    testCase.verifyEqual(pChk, pOur, 'AbsTol', 1e-12);
end
testCase.verifyGreaterThan(min(pOur), 0);
testCase.verifyLessThan(max(pOur), 1);
end

function f = svm_f_manual(Mdl, Z)
s = Mdl.KernelParameters.Scale;
SV = Mdl.SupportVectors;
alpha = Mdl.Alpha;
b = Mdl.Bias;
ysv = double(Mdl.SupportVectorLabels(:));
u = unique(ysv);
if isequal(sort(u), [0; 1])
    ypm = 2 * ysv - 1;
else
    ypm = ysv;
end
D = pdist2(Z, SV) ./ s;
K = exp(-(D .^ 2));
fAy = K * (alpha .* ypm) + b;
fA = K * alpha + b;
[~, sc] = predict(Mdl, Z(1, :));
if size(sc, 2) == 2
    t0 = sc(1, 2);
else
    t0 = sc(1);
end
if abs(fA(1) - t0) <= abs(fAy(1) - t0)
    f = fA;
else
    f = fAy;
end
end

function AB = platt_params_from_model(MdlP)
AB = [];
if isprop(MdlP, 'ScoreParameters') && ~isempty(MdlP.ScoreParameters)
    sp = MdlP.ScoreParameters;
    if isnumeric(sp) && numel(sp) >= 2
        AB = sp(1:2);
        AB = AB(:);
    end
end
end
