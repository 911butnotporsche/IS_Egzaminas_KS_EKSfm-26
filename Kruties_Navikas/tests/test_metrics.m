function tests = test_metrics
%TEST_METRICS Rankinis 8 objektų pavyzdys: Se, Sp, AUC (8), BS (9).
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root, 'evalx'));
end

function testHandEightCases(testCase)
y = [1; 1; 1; 1; 0; 0; 0; 0];
p = [0.9; 0.8; 0.4; 0.7; 0.2; 0.3; 0.6; 0.1];
t = 0.5;
m = metrics(y, p, t);
testCase.verifyEqual(m.TP, 3);
testCase.verifyEqual(m.FN, 1);
testCase.verifyEqual(m.FP, 1);
testCase.verifyEqual(m.TN, 3);
testCase.verifyEqual(m.Se, 0.75, 'AbsTol', 1e-12);
testCase.verifyEqual(m.Sp, 0.75, 'AbsTol', 1e-12);
bs = brier(y, p);
testCase.verifyEqual(bs, 0.125, 'AbsTol', 1e-12);
auc = roc_auc(y, p);
testCase.verifyEqual(auc, 15/16, 'AbsTol', 1e-12);
[~, ~, ~, aucP] = perfcurve(y, p, 1);
testCase.verifyEqual(auc, aucP, 'AbsTol', 1e-12);
end
