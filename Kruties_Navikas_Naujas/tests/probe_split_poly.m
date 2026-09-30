% One-off probe: stratified holdout size and polynomial decision function.
cfg = config();
S = load(fullfile(cfg.paths.processed, 'wdbc.mat'), 'X', 'y');
y = S.y(:);
rng(42, 'twister');
cvp = cvpartition(y, 'HoldOut', 0.20, 'Stratify', true);
fprintf('cvpartition test=%d train=%d Mtest=%d Btest=%d\n', ...
    sum(test(cvp)), sum(training(cvp)), sum(y(test(cvp))==1), sum(y(test(cvp))==0));

rng(1, 'twister');
n = 80;
Z = randn(n, 4);
y2 = double(Z(:,1) + 0.3*Z(:,2).^2 > 0);
C = 1; s = 2; d = 2;
Mdl = fitcsvm(Z, y2, 'KernelFunction', 'polynomial', 'PolynomialOrder', d, ...
    'KernelScale', s, 'BoxConstraint', C, 'ClassNames', [0 1], 'Standardize', false);
[~, sc] = predict(Mdl, Z);
if size(sc,2)==2
    fPred = sc(:,2);
else
    fPred = sc(:);
end
SV = Mdl.SupportVectors;
alpha = Mdl.Alpha(:);
b = Mdl.Bias;
labs = double(Mdl.SupportVectorLabels(:));
fprintf('label set: %s\n', mat2str(unique(labs)'));
fprintf('KernelScale=%g Order=%g Bias=%g nSV=%d\n', ...
    Mdl.KernelParameters.Scale, Mdl.KernelParameters.Order, b, size(SV,1));
r = 1;
Zs = Z / s;
SVs = SV / s;
K = (Zs * SVs' + r) .^ d;
ypm = labs;
if isequal(sort(unique(labs)), [0; 1])
    ypm = 2*labs - 1;
end
fAy = K * (alpha .* ypm) + b;
fA = K * alpha + b;
fprintf('max|fA-pred|=%.3e max|fAy-pred|=%.3e\n', max(abs(fA-fPred)), max(abs(fAy-fPred)));
fprintf('Alpha(1:3)=%s y(1:3)=%s\n', mat2str(alpha(1:min(3,end))',4), mat2str(ypm(1:min(3,end))',4));
