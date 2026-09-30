function cvInner = make_inner_cv(ytrain, cfg)
%MAKE_INNER_CV Plano 6.1: 5×5 = 25 stratifikuoti skaidiniai, atskiros sėklos.
%  Pakartojimas r: rng(cfg.seed + 1000*r). Foldo mokymas (tune_cv):
%  rng(cfg.seed + 1000*r + f). Indeksai reliatyvūs mokymo daliai, ne visam X.

if nargin < 2
    cfg = config();
end
ytrain = ytrain(:);
n = numel(ytrain);
if n == 569
    error('WDBC:InnerCV:FullSet', ...
        'make_inner_cv: gautos visos 569 zymes — vidinis CV tik ant mokymo dalies.');
end
if n < cfg.cv.k
    error('WDBC:InnerCV:TooFew', 'make_inner_cv: n=%d < k=%d.', n, cfg.cv.k);
end
if ~all(ismember(ytrain, [0 1]))
    error('WDBC:InnerCV:Labels', 'make_inner_cv: ytrain turi buti {0,1}.');
end

k = cfg.cv.k;
R = cfg.cv.repeats;
nM = sum(ytrain == 1);
nB = sum(ytrain == 0);

cvInner = struct();
cvInner.k = k;
cvInner.repeats = R;
cvInner.nPartitions = R * k;
cvInner.n = n;
cvInner.cv = cell(R, 1);
cvInner.seed_repeat = zeros(R, 1);
cvInner.seed_fold = zeros(R, k);

for r = 1:R
    seed_r = cfg.seed + 1000 * r;
    rng(seed_r, 'twister');
    cvp = cvpartition(ytrain, 'KFold', k, 'Stratify', true);
    cvInner.cv{r} = cvp;
    cvInner.seed_repeat(r) = seed_r;
    for f = 1:k
        cvInner.seed_fold(r, f) = cfg.seed + 1000 * r + f;
        tr = training(cvp, f);
        va = test(cvp, f);
        if any(tr & va)
            error('make_inner_cv: fold r=%d f=%d persidengia.', r, f);
        end
        if sum(tr) + sum(va) ~= n
            error('make_inner_cv: fold r=%d f=%d nepadengia mokymo dalies.', r, f);
        end
        nva = sum(va);
        nMva = sum(ytrain(va) == 1);
        nBva = sum(ytrain(va) == 0);
        expM = nM / n * nva;
        expB = nB / n * nva;
        if abs(nMva - expM) > 1.0 + 1e-9 || abs(nBva - expB) > 1.0 + 1e-9
            error(['make_inner_cv: fold r=%d f=%d nestratifikuotas: ', ...
                   'M=%d (tiketasi ~%.2f), B=%d (tiketasi ~%.2f).'], ...
                  r, f, nMva, expM, nBva, expB);
        end
    end
end

if cvInner.nPartitions ~= 25
    error('make_inner_cv: nPartitions=%d, plane 6.1 reikalaujama 25.', cvInner.nPartitions);
end
if numel(unique(cvInner.seed_repeat)) ~= R
    error('make_inner_cv: pakartojimu sekos nera unikalios.');
end
end
