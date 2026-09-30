function tests = test_select_features
%TEST_SELECT_FEATURES |r|>0.95 tik mokymo matricoje; silpnesnis poros narys šalinamas.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root, 'prep'));
testCase.TestData.cfg = config();
end

function testDropsWeakerMemberOfCollinearPair(testCase)
cfg = testCase.TestData.cfg;
n = 80;
y = [zeros(40, 1); ones(40, 1)];
x1 = y + 0.01 * (1:n)' / n;
x2 = x1;
x3 = randn(n, 1);
X = [x1, x2, x3];
sel = select_features(X, y, cfg);
testCase.verifyEqual(sel.keep, [1 3]);
testCase.verifyEqual(sel.dropped, 2);
testCase.verifyGreaterThan(sel.pairs(1, 4), 0.95);
end

function testRejectsFullWdbcMatrix(testCase)
cfg = testCase.TestData.cfg;
X = rand(569, 30);
y = [ones(212, 1); zeros(357, 1)];
testCase.verifyError(@() select_features(X, y, cfg), 'WDBC:Select:FullMatrix');
end

function testTrainRowsOnlyChangeTheChoice(testCase)
cfg = testCase.TestData.cfg;
n = 60;
y = [zeros(30, 1); ones(30, 1)];
x1 = y;
x2 = x1;
X = [x1, x2, randn(n, 1)];
selTr = select_features(X, y, cfg);
y2 = y;
y2(1) = 1;
x2b = x1;
x2b(1) = x2b(1) + 5;
X2 = [x1, x2b, X(:, 3)];
selOther = select_features(X2, y2, cfg);
testCase.verifyEqual(selTr.keep, [1 3]);
testCase.verifyNotEqual(selOther.pairs, selTr.pairs);
end
