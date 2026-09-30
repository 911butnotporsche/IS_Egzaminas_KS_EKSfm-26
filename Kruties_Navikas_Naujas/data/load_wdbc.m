function S = load_wdbc(cfg, raw)
%LOAD_WDBC Skaito wdbc.data, tikrina 569×30 / 0 NaN / 212 M / 357 B, šalina ID.
%  Plano 1 etapas / 1 lentelė ir formulės kintamieji X, y, featNames, meta.
%  ID pašalinamas PRIEŠ bet kokį skaidymą. Tikrinimui nepraėjus — error(), ne taisymai.

if nargin < 1
    cfg = config();
end
if nargin < 2 || isempty(raw)
    raw.data_path = fullfile(cfg.paths.raw, 'wdbc.data');
    raw.names_path = fullfile(cfg.paths.raw, 'wdbc.names');
    raw.doi = cfg.meta.doi;
    raw.download_date = '';
    raw.sha256_data = '';
    raw.sha256_names = '';
    if exist(raw.data_path, 'file')
        raw.sha256_data = local_sha256(raw.data_path);
    end
end

if ~exist(raw.data_path, 'file')
    error('load_wdbc: nerastas %s — pirma paleiskite get_wdbc.', raw.data_path);
end

opts = delimitedTextImportOptions('NumVariables', 32, 'Delimiter', ',', ...
    'CommentStyle', '%', 'Encoding', 'UTF-8');
opts.VariableTypes = [repmat({'char'}, 1, 2), repmat({'double'}, 1, 30)];
opts.ExtraColumnsRule = 'error';
opts.EmptyLineRule = 'skip';

try
    T = readtable(raw.data_path, opts);
catch ME
    error('load_wdbc: nepavyko perskaityti %s kaip 32 stulpeliu CSV.\n%s', ...
        raw.data_path, ME.message);
end

if height(T) ~= 569
    error('load_wdbc: tikimasi 569 eiluciu, gauta %d. Jokio tylaus kirpimo.', height(T));
end
if width(T) ~= 32
    error('load_wdbc: tikimasi 32 stulpeliu (ID, diagnozė, 30 pozymiu), gauta %d.', width(T));
end

idCol = T{:, 1};
diagCol = strtrim(string(T{:, 2}));
X = T{:, 3:32};

if ~isnumeric(X) || ~ismatrix(X)
    error('load_wdbc: pozymiai turi buti skaitine 569×30 matrica.');
end
if ~isequal(size(X), [569 30])
    error('load_wdbc: size(X) turi buti [569 30], gauta [%d %d].', size(X, 1), size(X, 2));
end
if any(isnan(X(:)))
    error('load_wdbc: rasta NaN. Imputacija draudziama — vykdymas stabdomas.');
end
if ~all(isfinite(X(:)))
    error('load_wdbc: rasta nebaigtiniu (Inf) reiksmiu. Vykdymas stabdomas.');
end
if any(X(:) < 0)
    error('load_wdbc: rasta neigiamu pozymiu. Vykdymas stabdomas.');
end
% Oficialus WDBC turi nulių concavity / concave_points (stulpeliai 7,8,17,18,27,28).
% Tai matavimai, ne trūkstamos reikšmės — eilučių nemetame ir neimputuojame.

unknown = ~(diagCol == "M" | diagCol == "B");
if any(unknown)
    error('load_wdbc: nezinoma diagnozes zyme (ne M/B) eiluteje. Jokio spėjimo.');
end

y = double(diagCol == "M");   % M → 1, B → 0
nM = sum(y == 1);
nB = sum(y == 0);
if nM ~= 212 || nB ~= 357
    error('load_wdbc: tikimasi 212 M ir 357 B, gauta M=%d B=%d.', nM, nB);
end

% ID nera pozymis ir i X nepatenka. Papildomas saugiklis: ID nelygus jokiam stulpeliui.
idNum = str2double(string(idCol));
if any(isfinite(idNum))
    for j = 1:30
        if isequal(X(:, j), idNum)
            error('load_wdbc: ID stulpelis sutampa su pozymiu nr. %d — nutekejimo rizika.', j);
        end
    end
end

chars = { ...
    'radius', 'texture', 'perimeter', 'area', 'smoothness', ...
    'compactness', 'concavity', 'concave_points', 'symmetry', 'fractal_dimension'};
stats = {'mean', 'se', 'worst'};
featNames = cell(1, 30);
k = 1;
for s = 1:3
    for c = 1:10
        featNames{k} = sprintf('%s_%s', chars{c}, stats{s});
        k = k + 1;
    end
end

if ~exist(cfg.paths.processed, 'dir')
    mkdir(cfg.paths.processed);
end

meta = struct();
meta.n = 569;
meta.p = 30;
meta.n_malignant = nM;
meta.n_benign = nB;
meta.doi = raw.doi;
meta.uci_id = cfg.meta.uci_id;
meta.download_date = raw.download_date;
meta.sha256_data = raw.sha256_data;
meta.sha256_names = raw.sha256_names;
meta.source_data = raw.data_path;
meta.note = 'ID pasalintas pries skaidyma. Rezultatas nera klinikine diagnoze.';

outPath = fullfile(cfg.paths.processed, 'wdbc.mat');
save(outPath, 'X', 'y', 'featNames', 'meta', '-v7');

S = struct('X', X, 'y', y, 'featNames', {featNames}, 'meta', meta, 'path', outPath);
fprintf('load_wdbc: irasyta %s (X %dx%d, M=%d, B=%d)\n', outPath, size(X,1), size(X,2), nM, nB);
end

function h = local_sha256(path)
fid = fopen(path, 'r');
if fid < 0
    h = '';
    return
end
bytes = fread(fid, inf, '*uint8');
fclose(fid);
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(bytes);
digest = typecast(md.digest, 'uint8');
h = lower(sprintf('%02x', digest(:).'));
end
