function mdl = train_svm_rbf(Z, y, C, s, cfg, kernel)
%TRAIN_SVM_RBF M1. Kolokviumo (2): K(z,z')=exp(−||z−z'||^2/s^2), γ=1/s^2.
%  (3): f(z)=Σ_{i∈S} α_i y_i K(z_i,z)+b, ŷ=sign(f(z)). Cost 5:1, Standardize=false.

if nargin < 6 || isempty(kernel)
    kernel = 'gaussian';
end
y = y(:);
if size(Z, 1) ~= numel(y)
    error('train_svm_rbf: eiluciu skaicius nelygus numel(y).');
end
if size(Z, 1) == 569
    error('WDBC:SVM:FullSet', 'train_svm_rbf: n=569 — tik mokymo dalis.');
end
args = {'KernelFunction', kernel, 'BoxConstraint', C, ...
    'Cost', cfg.costMatrix, 'ClassNames', [0 1], 'Standardize', false};
if ~strcmp(kernel, 'linear')
    args = [args, {'KernelScale', s}];
end
Mdl = fitcsvm(Z, y, args{:});
mdl = struct();
mdl.kind = 'svm_rbf';
if strcmp(kernel, 'linear')
    mdl.kind = 'svm_linear';
end
mdl.Mdl = Mdl;
mdl.C = C;
mdl.scale = s;
mdl.kernel = kernel;
mdl.Alpha = Mdl.Alpha;
mdl.Bias = Mdl.Bias;
mdl.SupportVectors = Mdl.SupportVectors;
end
