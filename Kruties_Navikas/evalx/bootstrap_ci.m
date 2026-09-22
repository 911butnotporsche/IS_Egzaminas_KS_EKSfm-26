function out = bootstrap_ci(y, fun, nBoot, seed)
%BOOTSTRAP_CI Suporuotas bootstrap 2000: fun(y(idx), varargin per closure).
%  fun priima indeksų vektorių į y ir grąžina skaliarą arba eilutę.
if nargin < 3
    nBoot = 2000;
end
if nargin < 4
    seed = 42;
end
y = y(:);
n = numel(y);
v0 = fun((1:n)');
v0 = v0(:)';
B = zeros(nBoot, numel(v0));
rng(seed, 'twister');
for b = 1:nBoot
    idx = randi(n, n, 1);
    B(b, :) = fun(idx);
end
out.point = v0;
out.lo = prctile(B, 2.5, 1);
out.hi = prctile(B, 97.5, 1);
out.draws = B;
end
