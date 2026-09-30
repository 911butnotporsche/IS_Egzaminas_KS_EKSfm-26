function platt = calibrate_platt(f, y)
%CALIBRATE_PLATT Kolokviumo (4): P(M|z)=1/(1+exp(A f(z)+B)), OOF, fminunc.
%  t₊=(N₊+1)/(N₊+2), t₋=1/(N₋+2). Testo balai nepriimami.

f = f(:);
y = y(:);
if numel(f) ~= numel(y)
    error('calibrate_platt: f ir y ilgis nesutampa.');
end
if numel(y) == 569
    error('WDBC:Platt:FullSet', ...
        'calibrate_platt: n=569 — kalibracija tik is OOF mokymo dalies.');
end
if ~all(ismember(y, [0 1]))
    error('calibrate_platt: y turi buti {0,1}.');
end

Npos = sum(y == 1);
Nneg = sum(y == 0);
if Npos < 1 || Nneg < 1
    error('calibrate_platt: abieju klasiu OOF reikia.');
end
t = zeros(size(y));
t(y == 1) = (Npos + 1) / (Npos + 2);
t(y == 0) = 1 / (Nneg + 2);

x0 = [0; log((Nneg + 1) / (Npos + 1))];
opts = optimoptions('fminunc', 'Display', 'off', 'Algorithm', 'quasi-newton', ...
    'MaxFunctionEvaluations', 2000);
ab = fminunc(@(ab) platt_nll(ab, f, t), x0, opts);

platt = struct();
platt.A = ab(1);
platt.B = ab(2);
platt.t_pos = (Npos + 1) / (Npos + 2);
platt.t_neg = 1 / (Nneg + 2);
platt.n = numel(y);
end

function nll = platt_nll(ab, f, t)
p = 1 ./ (1 + exp(ab(1) .* f + ab(2)));
p = min(max(p, 1e-15), 1 - 1e-15);
nll = -sum(t .* log(p) + (1 - t) .* log(1 - p));
end
