function bs = brier(y, p)
%BRIER Kolokviumo (9): BS = (1/m) Σ (p_k − y_k)^2.
y = y(:);
p = p(:);
if numel(y) ~= numel(p)
    error('brier: y ir p ilgis nesutampa.');
end
bs = mean((p - y).^2);
end
