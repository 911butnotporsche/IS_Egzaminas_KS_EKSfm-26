function tests = test_svm_poly
%TEST_SVM_POLY f(z) = sum(alpha_i * y_i * (z^T * z_i + r)^d) + b sutampa su predict.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root, 'models'));
testCase.TestData.cfg = config();
end

function testDecisionMatchesPredict(testCase)
cfg = testCase.TestData.cfg;
rng(1, 'twister');
n = 80;
Z = randn(n, 4);
y = double(Z(:, 1) + 0.3 * Z(:, 2).^2 > 0);
mdl = train_svm_poly(Z, y, 1, 2, 2, cfg);
fMan = svm_poly_score(mdl, Z);
[~, sc] = predict(mdl.Mdl, Z);
if size(sc, 2) == 2
    fPred = sc(:, 2);
else
    fPred = sc(:);
end
testCase.verifyEqual(fMan, fPred, 'AbsTol', 1e-8);
src = fileread(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'models', 'svm_poly_score.m'));
testCase.verifyTrue(contains(src, 'f(z) = sum(alpha_i * y_i * (z^T * z_i + r)^d) + b'));
lineHit = find(contains(splitlines(src), 'f = K * (alpha_i .* y_i) + b'));
testCase.verifyNotEmpty(lineHit);
end
