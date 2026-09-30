function sel = select_features(Xtrain, ytrain, cfg)
%SELECT_FEATURES Plano 3.5 ir Rasool et al. (2022): mokymo skaidinyje,
%  jei |Pearsono r| > 0,95, iš poros šalinamas požymis, silpniau susijęs su klase.
%  Koreliacija skaičiuojama tik iš paduotos matricos. Testo eilučių čia nėra.

if nargin < 3 || isempty(cfg)
    cfg = config();
end
ytrain = ytrain(:);
if ~isnumeric(Xtrain) || ~ismatrix(Xtrain)
    error('WDBC:Select:NotNumeric', 'select_features: Xtrain turi buti skaitine matrica.');
end
[n, p] = size(Xtrain);
if n ~= numel(ytrain)
    error('WDBC:Select:Size', 'select_features: eiluciu skaicius nelygus numel(y).');
end
if n == 569
    error('WDBC:Select:FullMatrix', ...
        ['select_features: gauta visa 569 eiluciu matrica. ', ...
         'Požymiai renkami tik mokymo skaidinyje.']);
end
if n < 3
    error('WDBC:Select:TooFew', 'select_features: reikia bent 3 mokymo eiluciu.');
end
if any(~isfinite(Xtrain(:))) || any(~isfinite(ytrain))
    error('WDBC:Select:NaN', 'select_features: NaN/Inf draudziama. Imputacijos nera.');
end
if ~all(ismember(ytrain, [0 1]))
    error('WDBC:Select:Labels', 'select_features: y turi buti {0,1}.');
end

thr = 0.95;
if isfield(cfg, 'feat') && isfield(cfg.feat, 'pearson_max')
    thr = cfg.feat.pearson_max;
end

C = corr(Xtrain);
cy = abs(corr(Xtrain, ytrain));
C(~isfinite(C)) = 0;
cy(~isfinite(cy)) = 0;
C(1:p+1:end) = 1;

keep = true(1, p);
pairs = [];
[ii, jj] = find(triu(abs(C), 1) > thr);
strength = abs(C(sub2ind([p p], ii, jj)));
[~, ord] = sortrows([strength, ii, jj], [-1 2 3]);
ii = ii(ord);
jj = jj(ord);
strength = strength(ord);

for k = 1:numel(ii)
    a = ii(k);
    b = jj(k);
    if ~keep(a) || ~keep(b)
        continue
    end
    drop = b;
    if cy(a) < cy(b) - 1e-15
        drop = a;
    elseif abs(cy(a) - cy(b)) <= 1e-15 && a > b
        drop = a;
    end
    keep(drop) = false;
    pairs(end+1, :) = [a, b, drop, strength(k)]; %#ok<AGROW>
end

sel = struct();
sel.keep = find(keep);
sel.dropped = find(~keep);
sel.corr_y = cy(:)';
sel.threshold = thr;
sel.pairs = pairs;
sel.n = n;
sel.p = p;
end
