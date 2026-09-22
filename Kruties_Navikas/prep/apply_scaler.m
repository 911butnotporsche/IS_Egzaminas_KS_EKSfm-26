function Z = apply_scaler(X, scaler)
%APPLY_SCALER Kolokviumo (1) be perskaičiavimo: z_ij = (x_ij − μ_j) / σ_j.
%  μ, σ tik iš scaler (fit_scaler). Jokio mean/std ant paduotos matricos.

if nargin < 2 || ~isstruct(scaler) || ~isfield(scaler, 'mu') || ~isfield(scaler, 'sigma')
    error('WDBC:ApplyScaler:NoScaler', ...
        'apply_scaler: reikalingas scaler su laukais mu ir sigma (is fit_scaler).');
end
if ~isnumeric(X) || ~ismatrix(X)
    error('WDBC:ApplyScaler:NotNumeric', 'apply_scaler: X turi buti skaitine matrica.');
end
if size(X, 2) ~= numel(scaler.mu) || numel(scaler.mu) ~= numel(scaler.sigma)
    error('WDBC:ApplyScaler:Dim', ...
        'apply_scaler: size(X,2)=%d, numel(mu)=%d.', size(X, 2), numel(scaler.mu));
end

Xin = X;
if isfield(scaler, 'logCols') && ~isempty(scaler.logCols)
    Xin(:, scaler.logCols) = log1p(Xin(:, scaler.logCols));
end

Z = (Xin - scaler.mu) ./ scaler.sigma;
end
