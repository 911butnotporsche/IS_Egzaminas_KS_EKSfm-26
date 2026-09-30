function mdl = train_svm_poly(Z, y, C, s, d, cfg)
%TRAIN_SVM_POLY M4 narys. Kolokviumo (3): K(z,z')=(gamma*z·z'+r)^d,
%  d in {2,3}, r=1, gamma=1/s^2. Sprendimo funkcija — svm_poly_score.m:
%  f(z) = sum(alpha_i * y_i * (z^T * z_i + r)^d) + b
%  Cost 5:1, Standardize=false (Z jau pagal (1)).

y = y(:);
if size(Z, 1) ~= numel(y)
    error('train_svm_poly: eiluciu skaicius nelygus numel(y).');
end
if size(Z, 1) == 569
    error('WDBC:SVMPoly:FullSet', 'train_svm_poly: n=569 — tik mokymo dalis.');
end
if ~ismember(d, [2 3])
    error('train_svm_poly: laipsnis d turi buti 2 arba 3, gauta %g.', d);
end
Mdl = fitcsvm(Z, y, ...
    'KernelFunction', 'polynomial', ...
    'PolynomialOrder', d, ...
    'KernelScale', s, ...
    'BoxConstraint', C, ...
    'Cost', cfg.costMatrix, ...
    'ClassNames', [0 1], ...
    'Standardize', false);
mdl = struct();
mdl.kind = 'svm_poly';
mdl.Mdl = Mdl;
mdl.C = C;
mdl.scale = s;
mdl.degree = d;
mdl.r = 1;
mdl.Alpha = Mdl.Alpha;
mdl.Bias = Mdl.Bias;
mdl.SupportVectors = Mdl.SupportVectors;
mdl.SupportVectorLabels = Mdl.SupportVectorLabels;
end
