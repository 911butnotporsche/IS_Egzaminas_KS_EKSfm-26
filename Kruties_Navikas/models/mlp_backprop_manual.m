function [W1, b1, w2, b2, hist] = mlp_backprop_manual(Z, y, H, lambda, eta, nIter, seed)
%MLP_BACKPROP_MANUAL Kolokviumo 3.3 / LD2: h=tanh(W1 z+b1), p=σ(w2^T h+b2),
%  δ^(2)=p−y, δ^(1)=(1−h⊙h)⊙(w2 δ^(2)). Palyginimui, ne HP paieškai.

if nargin < 7
    seed = 1;
end
rng(seed, 'twister');
y = y(:);
[n, p] = size(Z);
W1 = 0.1 * randn(H, p);
b1 = zeros(H, 1);
w2 = 0.1 * randn(H, 1);
b2 = 0;
hist = zeros(nIter, 1);
for t = 1:nIter
    a1 = W1 * Z' + b1;          % H × n
    h = tanh(a1);
    a2 = w2' * h + b2;          % 1 × n
    p1 = 1 ./ (1 + exp(-a2));
    p1 = min(max(p1, 1e-15), 1 - 1e-15);
    delta2 = p1 - y';           % 1 × n
    delta1 = (1 - h .^ 2) .* (w2 * delta2);  % H × n
    W1 = W1 - (eta / n) * (delta1 * Z) - eta * lambda * W1;
    b1 = b1 - (eta / n) * sum(delta1, 2);
    w2 = w2 - (eta / n) * (h * delta2') - eta * lambda * w2;
    b2 = b2 - (eta / n) * sum(delta2);
    hist(t) = -(1/n) * sum(y' .* log(p1) + (1 - y') .* log(1 - p1)) ...
        + (lambda / 2) * (sum(W1(:).^2) + sum(w2(:).^2));
end
end
