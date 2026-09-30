function cal = calibration_curve(y, p, nBins)
%CALIBRATION_CURVE a, b (logit P = a + b logit p) ir ECE, G=nBins (numatytai 10).
if nargin < 3 || isempty(nBins)
    nBins = 10;
end
y = y(:);
p = p(:);
p = min(max(p, 1e-15), 1 - 1e-15);
lp = log(p ./ (1 - p));
ws = warning('off', 'all');
cleanupObj = onCleanup(@() warning(ws));
b = glmfit(lp, y, 'binomial');
cal.a = b(1);
cal.b = b(2);
edges = linspace(0, 1, nBins + 1);
ece = 0;
m = numel(y);
acc = nan(nBins, 1);
conf = nan(nBins, 1);
cnt = zeros(nBins, 1);
for g = 1:nBins
    if g < nBins
        in = p >= edges(g) & p < edges(g + 1);
    else
        in = p >= edges(g) & p <= edges(g + 1);
    end
    cnt(g) = sum(in);
    if cnt(g) == 0
        continue
    end
    acc(g) = mean(y(in));
    conf(g) = mean(p(in));
    ece = ece + (cnt(g) / m) * abs(acc(g) - conf(g));
end
cal.ECE = ece;
cal.acc = acc;
cal.conf = conf;
cal.cnt = cnt;
cal.edges = edges;
end
