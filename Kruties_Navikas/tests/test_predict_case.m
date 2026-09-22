function tests = test_predict_case
%TEST_PREDICT_CASE data/examples/one_case.csv p sutampa su evaluate_test (1e-9).
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root, 'app'));
addpath(fullfile(root, 'evalx'));
addpath(fullfile(root, 'prep'));
addpath(fullfile(root, 'models'));
addpath(fullfile(root, 'data'));
testCase.TestData.cfg = config();
end

function testMatchesEvaluateTest(testCase)
cfg = testCase.TestData.cfg;
lockPath = fullfile(cfg.paths.reports, 'test_unlocked.flag');
assumeTrue(testCase, exist(lockPath, 'file') == 2);
ex = fullfile(cfg.paths.examples, 'one_case.csv');
assumeTrue(testCase, exist(ex, 'file') == 2);
predPath = fullfile(cfg.paths.processed, 'test_predictions.mat');
assumeTrue(testCase, exist(predPath, 'file') == 2);
idxPath = fullfile(cfg.paths.examples, 'one_case_idx.txt');
assumeTrue(testCase, exist(idxPath, 'file') == 2);

absIdx = load(idxPath);
S = load(predPath, 'pack', 'sp');
pos = find(S.sp.idxTest == absIdx, 1);
testCase.verifyNotEmpty(pos);

out = predict_case(ex, cfg);
modelName = strtok(out.model_version, '@');
pRef = S.pack.(modelName).p(pos);
testCase.verifyEqual(out.p_malignant, pRef, 'AbsTol', 1e-9);
testCase.verifyTrue(ismember(out.decision, {'B', 'M'}));
testCase.verifyTrue(contains(out.disclaimer, 'mokomasis'));
testCase.verifyFalse(contains(out.decision, 'diagnoz'));
testCase.verifyFalse(contains(out.model_version, 'diagnoz'));
end

function testRejectsBadShape(testCase)
cfg = testCase.TestData.cfg;
lockPath = fullfile(cfg.paths.reports, 'test_unlocked.flag');
assumeTrue(testCase, exist(lockPath, 'file') == 2);
threw = false;
try
    predict_case(ones(1, 29), cfg); %#ok<NASGU>
catch
    threw = true;
end
testCase.verifyTrue(threw);
end
