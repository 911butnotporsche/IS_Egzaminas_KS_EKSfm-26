function m = metrics(y, p, t)
%METRICS Kolokviumo (7): Se, Sp, PPV, NPV iš TP/FN/TN/FP. Slenkstis t fiksuotas.
y = y(:);
p = p(:);
if numel(y) ~= numel(p)
    error('metrics: y ir p ilgis nesutampa.');
end
if nargin < 3
    error('metrics: reikia slenksčio t.');
end
yhat = p >= t;
m.TP = sum(y == 1 & yhat);
m.FN = sum(y == 1 & ~yhat);
m.FP = sum(y == 0 & yhat);
m.TN = sum(y == 0 & ~yhat);
m.n = numel(y);
m.t = t;
nPos = m.TP + m.FN;
nNeg = m.TN + m.FP;
m.Se = m.TP / max(nPos, eps);
m.Sp = m.TN / max(nNeg, eps);
m.PPV = m.TP / max(m.TP + m.FP, eps);
m.NPV = m.TN / max(m.TN + m.FN, eps);
m.acc = (m.TP + m.TN) / m.n;
[m.Se_lo, m.Se_hi] = wilson_interval(m.TP, nPos);
[m.Sp_lo, m.Sp_hi] = wilson_interval(m.TN, nNeg);
end

function [lo, hi] = wilson_interval(k, n)
if n <= 0
    lo = NaN;
    hi = NaN;
    return
end
z = 1.959963984540054;
p = k / n;
den = 1 + z^2 / n;
ctr = (p + z^2 / (2 * n)) / den;
marg = z * sqrt((p * (1 - p) + z^2 / (4 * n)) / n) / den;
lo = max(0, ctr - marg);
hi = min(1, ctr + marg);
end
