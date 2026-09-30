function f = svm_poly_score(mdl, Z)
%SVM_POLY_SCORE Kolokviumo (3)–(4). z_s = z / s, r = 1, gamma = 1/s^2:
%  (z_s^T * z_s,i + r)^d = (gamma * z^T * z_i + r)^d.
%  f(z) = sum(alpha_i * y_i * (z^T * z_i + r)^d) + b
Mdl = mdl.Mdl;
s = Mdl.KernelParameters.Scale;
d = Mdl.KernelParameters.Order;
r = 1;
SV = Mdl.SupportVectors;
alpha_i = Mdl.Alpha(:);
y_i = double(Mdl.SupportVectorLabels(:));
b = Mdl.Bias;
K = ((Z / s) * (SV / s)' + r) .^ d;
f = K * (alpha_i .* y_i) + b;
f = f(:);
end
