function auc = roc_auc(y, scores)
%ROC_AUC Kolokviumo (8): AUC=P(f(Z_M)>f(Z_B))
%  =1/(n_M n_B) Σ_{i∈M} Σ_{k∈B} (1[f_i>f_k]+½·1[f_i=f_k]). Testo nenaudoja.

y = y(:);
scores = scores(:);
if numel(y) ~= numel(scores)
    error('roc_auc: y ir scores ilgis nesutampa.');
end
pos = scores(y == 1);
neg = scores(y == 0);
n1 = numel(pos);
n0 = numel(neg);
if n1 == 0 || n0 == 0
    error('roc_auc: abiejose klasese turi buti bent 1 objektas.');
end
nGreater = 0;
nEqual = 0;
for i = 1:n1
    nGreater = nGreater + sum(pos(i) > neg);
    nEqual = nEqual + sum(pos(i) == neg);
end
auc = (nGreater + 0.5 * nEqual) / (n1 * n0);
end
