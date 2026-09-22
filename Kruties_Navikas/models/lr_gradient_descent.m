function [Beta, Bias, hist] = lr_gradient_descent(Z, y, lambda, omega, eta, nIter)
%LR_GRADIENT_DESCENT Kolokviumo 5.1: J=−(1/n)Σ ω_i[y ln p+(1−y)ln(1−p)]+(λ/2)||w||^2,
%  ∇_w J=(1/n)Σ ω_i(p−y)z_i + λw, ∂J/∂b=(1/n)Σ ω_i(p−y). Turi sutapti su fitclinear iki 1e-4.

y = y(:);
omega = omega(:);
[n, p] = size(Z);
if nargin < 5 || isempty(eta)
    eta = 1.0;
end
if nargin < 6 || isempty(nIter)
    nIter = 20000;
end
Beta = zeros(p, 1);
Bias = 0;
hist = zeros(nIter, 1);
tol = 1e-12;
for t = 1:nIter
    [gW, gB, J] = lr_objgrad(Beta, Bias, Z, y, lambda, omega);
    hist(t) = J;
    gnorm = sqrt(gW' * gW + gB^2);
    if gnorm < tol
        hist = hist(1:t);
        return
    end
    step = eta;
    accepted = false;
    for k = 1:40
        BetaTry = Beta - step * gW;
        BiasTry = Bias - step * gB;
        [~, ~, Jtry] = lr_objgrad(BetaTry, BiasTry, Z, y, lambda, omega);
        if Jtry <= J - 1e-4 * step * (gnorm^2)
            Beta = BetaTry;
            Bias = BiasTry;
            accepted = true;
            break
        end
        step = step * 0.5;
    end
    if ~accepted
        error('lr_gradient_descent: linijine paieska nepavyko (t=%d, ||g||=%g).', t, gnorm);
    end
end
end

function [gW, gB, J] = lr_objgrad(Beta, Bias, Z, y, lambda, omega)
n = size(Z, 1);
p1 = 1 ./ (1 + exp(-(Z * Beta + Bias)));
p1 = min(max(p1, 1e-15), 1 - 1e-15);
res = omega .* (p1 - y);
gW = (Z' * res) / n + lambda * Beta;
gB = sum(res) / n;
J = -(1/n) * sum(omega .* (y .* log(p1) + (1 - y) .* log(1 - p1))) ...
    + (lambda / 2) * (Beta' * Beta);
end
