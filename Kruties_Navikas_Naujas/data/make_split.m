function split = make_split(X, y, cfg)
%MAKE_SPLIT Stratifikuotas 80/20, rng(cfg.seed): 455 mokymui, 114 testui
%  (42 piktybiniai, 72 gerybiniai). Išvestis — tik indeksai į split_idx.mat.
%  Požymių statistikos čia neskaičiuojamos.

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
% Plano n = 114 (42 piktybiniai + 72 gerybiniai). cvpartition HoldOut 0,20
% su stratifikacija šiai klasių sudėčiai grąžina 113 (42+71), nes kiekviena
% klasė apvalinama atskirai. Čia indeksai išrenkami rng(sėkla) būdu iki
% tikslaus plano dydžio, prieš bet kokį fit ir ne iš požymių statistikos.
nM_te = cfg.split.nTestM;
nB_te = cfg.split.nTestB;
if nM_te + nB_te ~= cfg.split.nTest
    error('make_split: nTestM+nTestB turi buti nTest.');
end
idxM = find(y == 1);
idxB = find(y == 0);
if numel(idxM) ~= 212 || numel(idxB) ~= 357
    error('make_split: tikimasi 212 piktybiniu ir 357 gerybiniu.');
end
if nM_te >= numel(idxM) || nB_te >= numel(idxB)
    error('make_split: testavimo skaicius per didelis.');
end
idxM = idxM(randperm(numel(idxM)));
idxB = idxB(randperm(numel(idxB)));
idxTest = sort([idxM(1:nM_te); idxB(1:nB_te)]);
idxTrain = sort([idxM(nM_te+1:end); idxB(nB_te+1:end)]);

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
