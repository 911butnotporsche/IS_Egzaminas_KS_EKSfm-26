function split = make_split(X, y, cfg)
%MAKE_SPLIT Stratifikuotas 80/20 HoldOut, rng(cfg.seed). Plano 2 etapas / 1 lentelė.
%  cvpartition(y,'HoldOut',0.20,'Stratify',true). Išvestis — tik indeksai
%  (idxTrain, idxTest) į data/processed/split_idx.mat. Testo objektų
%  statistikos čia neskaičiuojamos.

if nargin < 3
    cfg = config();
end

y = y(:);
n = size(X, 1);
if n ~= numel(y)
    error('make_split: size(X,1)=%d nelygu numel(y)=%d.', n, numel(y));
end
if n ~= 569
    error('make_split: tikimasi 569 objektu (WDBC), gauta %d.', n);
end
if ~all(ismember(y, [0 1]))
    error('make_split: y turi buti {0,1}.');
end

rng(cfg.seed, 'twister');
cvp = cvpartition(y, 'HoldOut', cfg.test_size, 'Stratify', true);

idxTrain = find(training(cvp));
idxTest  = find(test(cvp));

if ~isempty(intersect(idxTrain, idxTest))
    error('make_split: idxTrain ir idxTest persidengia.');
end
if numel(idxTrain) + numel(idxTest) ~= n
    error('make_split: indeksai nepadengia visos imties.');
end
if ~isempty(setdiff((1:n)', union(idxTrain, idxTest)))
    error('make_split: liko nepriskirtu indeksu.');
end

nM_all = sum(y == 1);
nB_all = sum(y == 0);
nM_te = sum(y(idxTest) == 1);
nB_te = sum(y(idxTest) == 0);
% Plano priėmimas: testo klasių santykis = viso rinkinio ±1 atvejis.
expM = nM_all / n * numel(idxTest);
expB = nB_all / n * numel(idxTest);
if abs(nM_te - expM) > 1.0 + 1e-9 || abs(nB_te - expB) > 1.0 + 1e-9
    error(['make_split: stratifikacija nepavyko: teste M=%d B=%d, ', ...
           'tiketasi ~%.1f / ~%.1f (±1).'], nM_te, nB_te, expM, expB);
end

if ~exist(cfg.paths.processed, 'dir')
    mkdir(cfg.paths.processed);
end

seed = cfg.seed; %#ok<NASGU>
test_size = cfg.test_size; %#ok<NASGU>
outPath = fullfile(cfg.paths.processed, 'split_idx.mat');
save(outPath, 'idxTrain', 'idxTest', 'seed', 'test_size', '-v7');

split = struct();
split.idxTrain = idxTrain;
split.idxTest = idxTest;
split.path = outPath;
split.nTrain = numel(idxTrain);
split.nTest = numel(idxTest);
split.nM_train = sum(y(idxTrain) == 1);
split.nB_train = sum(y(idxTrain) == 0);
split.nM_test = nM_te;
split.nB_test = nB_te;

fprintf(['make_split: train=%d (M=%d B=%d), test=%d (M=%d B=%d), ', ...
         'idx irasyti i %s\n'], split.nTrain, split.nM_train, split.nB_train, ...
         split.nTest, split.nM_test, split.nB_test, outPath);
end
