function tests = test_split
%TEST_SPLIT Plano 2 etapo priėmimas: disjoint 80/20, stratifikacija, rng(42).
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root, 'data'));
addpath(fullfile(root, 'prep'));
addpath(fullfile(root, 'tests'));
cfg = config();
wdbcPath = fullfile(cfg.paths.processed, 'wdbc.mat');
assert(exist(wdbcPath, 'file') == 2, 'test_split: nera wdbc.mat — pirma 1 etapas.');
S = load(wdbcPath, 'X', 'y');
testCase.TestData.cfg = cfg;
testCase.TestData.X = S.X;
testCase.TestData.y = S.y(:);
end

function testHoldOutSizesAndDisjoint(testCase)
cfg = testCase.TestData.cfg;
X = testCase.TestData.X;
y = testCase.TestData.y;
split = make_split(X, y, cfg);

n = size(X, 1);
testCase.verifyEqual(numel(split.idxTrain) + numel(split.idxTest), n);
testCase.verifyEmpty(intersect(split.idxTrain, split.idxTest));
testCase.verifyEmpty(setdiff((1:n)', union(split.idxTrain, split.idxTest)));
testCase.verifyEqual(numel(unique(split.idxTrain)), numel(split.idxTrain));
testCase.verifyEqual(numel(unique(split.idxTest)), numel(split.idxTest));

% 80/20 pagal plana: tiksliai 114 testavimo ir 455 mokymo atvejai.
testCase.verifyEqual(split.nTest, cfg.split.nTest);
testCase.verifyEqual(split.nTrain, 569 - cfg.split.nTest);
testCase.verifyEqual(split.nTrain, 455);
testCase.verifyEqual(split.nTest, 114);
end

function testStratifiedClassCounts(testCase)
cfg = testCase.TestData.cfg;
y = testCase.TestData.y;
split = make_split(testCase.TestData.X, y, cfg);

testCase.verifyEqual(split.nM_test, cfg.split.nTestM);
testCase.verifyEqual(split.nB_test, cfg.split.nTestB);
testCase.verifyEqual(split.nM_test, 42);
testCase.verifyEqual(split.nB_test, 72);
testCase.verifyEqual(split.nM_test + split.nB_test, split.nTest);
testCase.verifyEqual(split.nM_train + split.nB_train, split.nTrain);
testCase.verifyEqual(split.nM_train + split.nM_test, 212);
testCase.verifyEqual(split.nB_train + split.nB_test, 357);
end

function testSeed42Reproducible(testCase)
cfg = testCase.TestData.cfg;
X = testCase.TestData.X;
y = testCase.TestData.y;
s1 = make_split(X, y, cfg);
s2 = make_split(X, y, cfg);
testCase.verifyEqual(s1.idxTrain, s2.idxTrain);
testCase.verifyEqual(s1.idxTest, s2.idxTest);
end

function testSplitFileContainsOnlyIndices(testCase)
cfg = testCase.TestData.cfg;
split = make_split(testCase.TestData.X, testCase.TestData.y, cfg);
W = whos('-file', split.path);
names = {W.name};
testCase.verifyTrue(ismember('idxTrain', names));
testCase.verifyTrue(ismember('idxTest', names));
testCase.verifyFalse(ismember('X', names));
testCase.verifyFalse(ismember('Ztrain', names));
testCase.verifyFalse(ismember('Ztest', names));
S = load(split.path, 'idxTrain', 'idxTest');
testCase.verifyEqual(S.idxTrain, split.idxTrain);
testCase.verifyEqual(S.idxTest, split.idxTest);
end
