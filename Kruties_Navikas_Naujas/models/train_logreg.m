function mdl = train_logreg(Z, y, lambda, cfg)
%TRAIN_LOGREG B1. Kolokviumo 5.1 (be numerio): p=σ(w^T z+b), svertinis L2 log-nuostolis.
%  fitclinear Learner=logistic, ridge, svoriai 5:1. Z jau pagal (1).

y = y(:);
if size(Z, 1) ~= numel(y)
    error('train_logreg: eiluciu skaicius nelygus numel(y).');
end
if size(Z, 1) == 569
    error('WDBC:Logreg:FullSet', 'train_logreg: n=569 — tik mokymo dalis.');
end
w = class_weights(y, cfg);
Mdl = fitclinear(Z, y, ...
    'Learner', 'logistic', ...
    'Regularization', 'ridge', ...
    'Lambda', lambda, ...
    'ClassNames', [0 1], ...
    'Weights', w, ...
    'Solver', 'lbfgs');
mdl = struct();
mdl.kind = 'logreg';
mdl.Mdl = Mdl;
mdl.lambda = lambda;
mdl.Beta = Mdl.Beta;
mdl.Bias = Mdl.Bias;
end
