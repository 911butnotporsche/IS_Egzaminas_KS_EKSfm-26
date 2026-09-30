function scaler = fit_scaler(Xtrain, cfg)
%FIT_SCALER Kolokviumo (1): z_ij=(x_ij-μ_j)/σ_j, μ_j=(1/n_tr)Σ_{i∈Tr} x_ij,
%  σ_j^2=(1/(n_tr-1))Σ_{i∈Tr}(x_ij-μ_j)^2. Tr = tik paduota mokymo matrica.

if nargin < 1
    error('WDBC:FitScaler:NoData', 'fit_scaler: truksta Xtrain.');
end
if nargin >= 2 && isnumeric(cfg)
    error('WDBC:FitScaler:IndexArg', ...
        ['fit_scaler nepriima indeksu kaip argumento. ', ...
         'Pateikite jau iskirpta matrica Xtrain = X(idxTrain,:), ne (X, idx).']);
end
if nargin < 2 || isempty(cfg)
    cfg = config();
end
if ~isnumeric(Xtrain) || ~ismatrix(Xtrain)
    error('WDBC:FitScaler:NotNumeric', 'fit_scaler: Xtrain turi buti skaitine matrica.');
end

[n, p] = size(Xtrain);
if n < 2
    error('WDBC:FitScaler:TooFew', 'fit_scaler: reikia bent 2 eiluciu sigma (n-1).');
end
if n == 569
    error('WDBC:FitScaler:FullMatrix', ...
        ['fit_scaler: gauta visa 569 eiluciu WDBC matrica. ', ...
         'Testo objektai butu fit viduje. Pateikite tik mokymo poaibi.']);
end
if any(isnan(Xtrain(:))) || any(~isfinite(Xtrain(:)))
    error('WDBC:FitScaler:NaN', 'fit_scaler: Xtrain turi NaN/Inf. Imputacija draudziama.');
end

logCols = zeros(1, 0);
Xfit = Xtrain;
if isfield(cfg, 'prep') && isfield(cfg.prep, 'log_transform') && cfg.prep.log_transform
    sk = skewness(Xtrain, 0, 1);
    logCols = find(sk > 1);
    Xfit(:, logCols) = log1p(Xfit(:, logCols));
end

mu = mean(Xfit, 1);
sigma = std(Xfit, 0, 1);   % 1/(n_tr-1), formulė (1)
if any(sigma == 0)
    error('WDBC:FitScaler:ZeroSigma', ...
        'fit_scaler: sigma=0 pozymyje %s. Tyliai nekeiciama i 1.', ...
        mat2str(find(sigma == 0)));
end

scaler = struct();
scaler.mu = mu;
scaler.sigma = sigma;
scaler.logCols = logCols;
scaler.xmin = min(Xtrain, [], 1);
scaler.xmax = max(Xtrain, [], 1);
scaler.n = n;
scaler.p = p;
end
