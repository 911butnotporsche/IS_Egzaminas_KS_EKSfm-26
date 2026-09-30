function S = delong_test(y, s1, s2)
%DELONG_TEST Dviejų AUC palyginimas tame pačiame y (DeLong et al., 1988).
%  s1, s2 – ranginiai balai. Grąžina AUC, skirtumą, SE, 95 % PI, p.

y = y(:);
s1 = s1(:);
s2 = s2(:);
if numel(unique(y)) ~= 2
    error('delong_test: reikia abieju klasiu.');
end
auc1 = roc_auc(y, s1);
auc2 = roc_auc(y, s2);
[v1, n1, n0] = delong_v(y, s1);
[v2, ~, ~] = delong_v(y, s2);
C = cov([v1.pos, v2.pos]) / n1 + cov([v1.neg, v2.neg]) / n0;
d = auc1 - auc2;
varD = C(1, 1) + C(2, 2) - 2 * C(1, 2);
se = sqrt(max(varD, 0));
z = 1.959963984540054;
if se == 0
    S.p = double(d ~= 0);
    lo = d;
    hi = d;
else
    zstat = d / se;
    S.p = 2 * (1 - 0.5 * erfc(-abs(zstat) / sqrt(2)));
    lo = d - z * se;
    hi = d + z * se;
end
S.auc1 = auc1;
S.auc2 = auc2;
S.diff = d;
S.se = se;
S.lo = lo;
S.hi = hi;
S.auc1_lo = auc1 - z * sqrt(max(C(1, 1), 0));
S.auc1_hi = auc1 + z * sqrt(max(C(1, 1), 0));
S.auc2_lo = auc2 - z * sqrt(max(C(2, 2), 0));
S.auc2_hi = auc2 + z * sqrt(max(C(2, 2), 0));
end

function [v, n1, n0] = delong_v(y, s)
pos = s(y == 1);
neg = s(y == 0);
n1 = numel(pos);
n0 = numel(neg);
v.pos = zeros(n1, 1);
v.neg = zeros(n0, 1);
for i = 1:n1
    v.pos(i) = (sum(pos(i) > neg) + 0.5 * sum(pos(i) == neg)) / n0;
end
for j = 1:n0
    v.neg(j) = (sum(pos > neg(j)) + 0.5 * sum(pos == neg(j))) / n1;
end
end
