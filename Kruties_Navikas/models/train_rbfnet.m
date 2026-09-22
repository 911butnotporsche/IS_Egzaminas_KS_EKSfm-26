function mdl = train_rbfnet(Z, y, J, kappa, lambda, seed)
%TRAIN_RBFNET M3, Kolokviumo 3.4: φ_j=exp(−||z−c_j||^2/(2 s_j^2)), a=w0+Σ w_j φ_j,
%  w=(Φ^T Φ+λI)^{-1} Φ^T ỹ, ỹ∈{−1,+1}. Centrai tik iš Z mokymo.

if nargin < 6
    seed = 42;
end
y = y(:);
n = size(Z, 1);
if n ~= numel(y)
    error('train_rbfnet: eiluciu skaicius nelygus numel(y).');
end
if n == 569
    error('WDBC:RBF:FullSet', 'train_rbfnet: n=569 — tik mokymo dalis.');
end
if J >= n
    error('train_rbfnet: J=%d turi buti < n=%d.', J, n);
end

rng(seed, 'twister');
[~, centers] = kmeans(Z, J, 'Replicates', 5, 'MaxIter', 200);

D = squareform(pdist(centers));
D(1:J+1:end) = inf;
srt = sort(D, 2);
d2 = mean(srt(:, 1:min(2, J-1)), 2);
if any(~isfinite(d2)) || any(d2 <= 0)
    error('train_rbfnet: nulinis arba Inf centru atstumas — pločių negalima tyliai pataisyti.');
end
widths = kappa * d2;

Phi = rbf_phi(Z, centers, widths);
Phi1 = [ones(n, 1), Phi];
ytilde = 2 * y - 1;
A = Phi1' * Phi1 + lambda * eye(J + 1);
w = A \ (Phi1' * ytilde);

mdl = struct();
mdl.kind = 'rbfnet';
mdl.centers = centers;
mdl.widths = widths;
mdl.w = w;
mdl.J = J;
mdl.kappa = kappa;
mdl.lambda = lambda;
end

function Phi = rbf_phi(Z, centers, widths)
%RBF_PHI Kolokviumo 3.4: φ_j = exp(−||z−c_j||^2 / (2 s_j^2)).
J = size(centers, 1);
n = size(Z, 1);
Phi = zeros(n, J);
for j = 1:J
    d2 = sum((Z - centers(j, :)).^2, 2);
    Phi(:, j) = exp(-d2 ./ (2 * widths(j).^2));
end
end
