function tests = test_no_leakage
%TEST_NO_LEAKAGE scaler.mu = mokymo vidurkis; fit nemato testo indeksų.
%  Tas pats tikrinama kiekviename vidinio 5×5 CV folde.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root, 'data'));
addpath(fullfile(root, 'prep'));
cfg = config();
S = load(fullfile(cfg.paths.processed, 'wdbc.mat'), 'X', 'y');
split = make_split(S.X, S.y, cfg);
testCase.TestData.cfg = cfg;
testCase.TestData.X = S.X;
testCase.TestData.y = S.y(:);
testCase.TestData.split = split;
testCase.TestData.root = root;
end

function testFitSignatureRejectsIndicesAndFullMatrix(testCase)
% fit_scaler argumentų sąraše nėra idx — testo indeksai fiziškai nepaduodami.
nIn = nargin('fit_scaler');
testCase.verifyEqual(nIn, 2, 'fit_scaler(Xtrain, cfg) — be indeksu.');

cfg = testCase.TestData.cfg;
X = testCase.TestData.X;
idxTrain = testCase.TestData.split.idxTrain;

testCase.verifyError(@() fit_scaler(X, idxTrain), 'WDBC:FitScaler:IndexArg');
testCase.verifyError(@() fit_scaler(X, cfg), 'WDBC:FitScaler:FullMatrix');
end

function testMuSigmaFromTrainOnly(testCase)
cfg = testCase.TestData.cfg;
X = testCase.TestData.X;
idxTrain = testCase.TestData.split.idxTrain;
idxTest = testCase.TestData.split.idxTest;

Xtrain = X(idxTrain, :);
Xtest  = X(idxTest, :);
scaler = fit_scaler(Xtrain, cfg);

muTr = mean(Xtrain, 1);
muAll = mean(X, 1);
sgTr = std(Xtrain, 0, 1);

testCase.verifyEqual(scaler.mu, muTr, 'AbsTol', 1e-12);
testCase.verifyEqual(scaler.sigma, sgTr, 'AbsTol', 1e-12);
testCase.verifyGreaterThan(max(abs(scaler.mu - muAll)), 1e-10, ...
    'scaler.mu neturi sutapti su mean(X) visos imties.');
testCase.verifyNotEqual(scaler.n, size(X, 1));
testCase.verifyEqual(scaler.n, size(Xtrain, 1));
testCase.verifyFalse(isfield(scaler, 'idxTest'));
testCase.verifyFalse(isfield(scaler, 'idxTrain'));

% apply_scaler nenaudoja testo statistiku: transformacija su train mu/sigma.
Zte = apply_scaler(Xtest, scaler);
Zte_manual = (Xtest - muTr) ./ sgTr;
testCase.verifyEqual(Zte, Zte_manual, 'AbsTol', 1e-12);

Ztr = apply_scaler(Xtrain, scaler);
testCase.verifyEqual(mean(Ztr, 1), zeros(1, 30), 'AbsTol', 1e-12);
end

function testApplyScalerSourceDoesNotFit(testCase)
src = fileread(fullfile(testCase.TestData.root, 'prep', 'apply_scaler.m'));
% Pašalinti komentarus, tada tikrinti, kad nėra mean/std fit.
lines = splitlines(src);
code = '';
for i = 1:numel(lines)
    t = regexprep(lines{i}, '%.*$', '');
    code = [code, newline, t]; %#ok<AGROW>
end
testCase.verifyEmpty(regexp(code, '\<mean\s*\(', 'once'), ...
    'apply_scaler.m neturi kviesti mean() — tai butu fit is paduotos matricos.');
testCase.verifyEmpty(regexp(code, '\<std\s*\(', 'once'), ...
    'apply_scaler.m neturi kviesti std().');
testCase.verifyEmpty(regexp(code, 'idxTest', 'once'));
end

function testFitScalerSourceHasNoIdxTest(testCase)
src = fileread(fullfile(testCase.TestData.root, 'prep', 'fit_scaler.m'));
testCase.verifyEmpty(regexp(src, 'idxTest', 'once'), ...
    'fit_scaler.m neturi tureti idxTest — testo indeksai nepasiekiami.');
end

function testInnerCvRefitsScalerEachFold(testCase)
% Kolokviumo (1) CV cikle: μ, σ tik iš to foldo mokymo poaibio.
cfg = testCase.TestData.cfg;
X = testCase.TestData.X;
y = testCase.TestData.y;
idxTrain = testCase.TestData.split.idxTrain;
idxTest = testCase.TestData.split.idxTest;

Xtrain = X(idxTrain, :);
ytrain = y(idxTrain);
cvInner = make_inner_cv(ytrain, cfg);

testCase.verifyEqual(cvInner.n, numel(idxTrain));
testCase.verifyEqual(cvInner.repeats, cfg.cv.repeats);
testCase.verifyEqual(cvInner.k, cfg.cv.k);
testCase.verifyEqual(cvInner.nPartitions, 25);
testCase.verifyEqual(numel(unique(cvInner.seed_repeat)), cfg.cv.repeats);
testCase.verifyFalse(isequal(find(test(cvInner.cv{1}, 1)), find(test(cvInner.cv{2}, 1))), ...
    'Pakartojimai 1 ir 2 turi buti skirtingi 5-fold skaidiniai.');

outerScaler = fit_scaler(Xtrain, cfg);
nChecked = 0;
for r = 1:cvInner.repeats
    cvp = cvInner.cv{r};
    for f = 1:cvp.NumTestSets
        trRel = training(cvp, f);
        vaRel = test(cvp, f);
        testCase.verifyEmpty(intersect(find(trRel), find(vaRel)));

        absTr = idxTrain(trRel);
        absVa = idxTrain(vaRel);
        testCase.verifyEmpty(intersect(absTr, idxTest), ...
            'Vidinio CV mokymas neturi testo indeksu.');
        testCase.verifyEmpty(intersect(absVa, idxTest), ...
            'Vidinio CV validacija neturi testo indeksu.');

        Xfold = Xtrain(trRel, :);
        sc = fit_scaler(Xfold, cfg);
        testCase.verifyEqual(sc.mu, mean(Xfold, 1), 'AbsTol', 1e-12);
        testCase.verifyEqual(sc.sigma, std(Xfold, 0, 1), 'AbsTol', 1e-12);

        % Foldo scaler ≠ išorinis scaler (kita imtis).
        testCase.verifyGreaterThan(max(abs(sc.mu - outerScaler.mu)), 0);

        % Validacijos eilutės nedalyvauja fit.
        Xtrval = Xtrain(trRel | vaRel, :);
        testCase.verifyGreaterThan(max(abs(sc.mu - mean(Xtrval, 1))), 0);

        nChecked = nChecked + 1;
    end
end
testCase.verifyEqual(nChecked, cfg.cv.k * cfg.cv.repeats);
end
