function tests = test_result_consistency
%TEST_RESULT_CONSISTENCY Skaidinys, Se/Sp/n ir M1 abliacijos sutapimas.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root, 'data'));
addpath(fullfile(root, 'evalx'));
cfg = config();
testCase.TestData.cfg = cfg;
testCase.TestData.W = load(fullfile(cfg.paths.processed, 'wdbc.mat'), 'y');
testCase.TestData.sp = load(fullfile(cfg.paths.processed, 'split_idx.mat'), 'idxTrain', 'idxTest', 'seed');
end

function testSplit455114(testCase)
y = testCase.TestData.W.y(:);
tr = testCase.TestData.sp.idxTrain(:);
te = testCase.TestData.sp.idxTest(:);
testCase.verifyEqual(testCase.TestData.sp.seed, 42);
testCase.verifyEqual(numel(y), 569);
testCase.verifyEmpty(intersect(tr, te));
testCase.verifyEqual(numel(union(tr, te)), 569);
testCase.verifyEqual(numel(tr), 455);
testCase.verifyEqual(numel(te), 114);
testCase.verifyEqual(sum(y(tr) == 1), 170);
testCase.verifyEqual(sum(y(tr) == 0), 285);
testCase.verifyEqual(sum(y(te) == 1), 42);
testCase.verifyEqual(sum(y(te) == 0), 72);
end

function testMainResultsIdentity(testCase)
cfg = testCase.TestData.cfg;
T = readtable(fullfile(cfg.paths.tables, 'main_results.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
for i = 1:height(T)
    n = T.TP(i) + T.FN(i) + T.TN(i) + T.FP(i);
    se = T.TP(i) / (T.TP(i) + T.FN(i));
    sp = T.TN(i) / (T.TN(i) + T.FP(i));
    testCase.verifyEqual(n, 114, sprintf('%s %s n', T.model(i), T.point(i)));
    testCase.verifyEqual(se, T.Se(i), 'AbsTol', 1e-9);
    testCase.verifyEqual(sp, T.Sp(i), 'AbsTol', 1e-9);
end
end

function testAblationAll30MatchesM1(testCase)
cfg = testCase.TestData.cfg;
A = readtable(fullfile(cfg.paths.tables, 'ablation.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
M = readtable(fullfile(cfg.paths.tables, 'main_results.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
hitA = A.id == "A5" & A.setting == "all30_tse98";
hitM = M.model == "svm_rbf" & M.point == "t_se98";
testCase.verifyEqual(sum(hitA), 1);
testCase.verifyEqual(sum(hitM), 1);
testCase.verifyEqual(A.FP(hitA), M.FP(hitM));
testCase.verifyEqual(A.FN(hitA), M.FN(hitM));
testCase.verifyEqual(A.Sp(hitA), M.Sp(hitM), 'AbsTol', 1e-12);
testCase.verifyEqual(A.AUC(hitA), M.AUC(hitM), 'AbsTol', 1e-12);
% 71 gerybinio sena hipoteze: FP=5 duotu Sp=66/71. Dabartinis testas turi 72.
testCase.verifyEqual(A.FP(hitA), 4);
testCase.verifyEqual(double(A.Sp(hitA)), 68/72, 'AbsTol', 1e-9);
end

function testB0BrierIsNotTrainingPrior(testCase)
% p=0 ant 42 piktybiniu is 114: BS = 42/114. Prior 170/455 duotu kita BS.
y = [ones(42, 1); zeros(72, 1)];
bs0 = brier(y, zeros(114, 1));
prior = 170/455;
bsP = brier(y, prior * ones(114, 1));
testCase.verifyEqual(bs0, 42/114, 'AbsTol', 1e-12);
testCase.verifyGreaterThan(abs(bs0 - bsP), 0.1);
cfg = testCase.TestData.cfg;
R = readtable(fullfile(cfg.paths.reports, 'results_test.csv'), ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
b0 = R(R.Modelis == "B0", :);
testCase.verifyEqual(double(b0.Brier(1)), 42/114, 'AbsTol', 1e-6);
end
