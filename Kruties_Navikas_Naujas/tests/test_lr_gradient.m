function tests = test_lr_gradient
%TEST_LR_GRADIENT Kolokviumo 5.1: gradientas vs baigtiniai skirtumai;
%  lr_gradient_descent Beta,Bias vs fitclinear iki 1e-4.
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
sp = load(fullfile(cfg.paths.processed, 'split_idx.mat'), 'idxTrain');
Xtr = S.X(sp.idxTrain, :);
ytr = S.y(sp.idxTrain);
sc = fit_scaler(Xtr, cfg);
testCase.TestData.Z = apply_scaler(Xtr, sc);
testCase.TestData.y = ytr(:);
testCase.TestData.cfg = cfg;
end

function testFiniteDifferenceMatchesGradient(testCase)
Z = testCase.TestData.Z;
y = testCase.TestData.y;
cfg = testCase.TestData.cfg;
omega = class_weights(y, cfg);
lambda = 0.01;
rng(cfg.seed, 'twister');
p = size(Z, 2);
Beta = 0.01 * randn(p, 1);
Bias = 0.01 * randn();
[gW, gB] = formula_grad(Beta, Bias, Z, y, lambda, omega);
epsA = 1e-6;
dW = zeros(p, 1);
for j = 1:p
    e = zeros(p, 1); e(j) = epsA;
    Jp = nll(Beta + e, Bias, Z, y, lambda, omega);
    Jm = nll(Beta - e, Bias, Z, y, lambda, omega);
    dW(j) = (Jp - Jm) / (2 * epsA);
end
Jp = nll(Beta, Bias + epsA, Z, y, lambda, omega);
Jm = nll(Beta, Bias - epsA, Z, y, lambda, omega);
dB = (Jp - Jm) / (2 * epsA);
testCase.verifyEqual(gW, dW, 'AbsTol', 1e-6);
testCase.verifyEqual(gB, dB, 'AbsTol', 1e-6);
end

function testCoefficientsMatchFitclinear(testCase)
% Plano 5.1: sava realizacija sutampa su fitclinear iki 1e-4 (koeficientai, ne tik p).
Z = testCase.TestData.Z;
y = testCase.TestData.y;
cfg = testCase.TestData.cfg;
lambda = 0.01;
omega = class_weights(y, cfg);
[Beta, Bias] = lr_gradient_descent(Z, y, lambda, omega);
mdl = train_logreg(Z, y, lambda, cfg);
testCase.verifyEqual(Beta, mdl.Beta, 'AbsTol', 1e-4);
testCase.verifyEqual(Bias, mdl.Bias, 'AbsTol', 1e-4);
end

function J = nll(Beta, Bias, Z, y, lambda, omega)
n = size(Z, 1);
p1 = 1 ./ (1 + exp(-(Z * Beta + Bias)));
p1 = min(max(p1, 1e-15), 1 - 1e-15);
J = -(1/n) * sum(omega .* (y .* log(p1) + (1 - y) .* log(1 - p1))) ...
    + (lambda / 2) * (Beta' * Beta);
end

function [gW, gB] = formula_grad(Beta, Bias, Z, y, lambda, omega)
n = size(Z, 1);
p1 = 1 ./ (1 + exp(-(Z * Beta + Bias)));
res = omega .* (p1 - y);
gW = (Z' * res) / n + lambda * Beta;
gB = sum(res) / n;
end
