function [p, score, yhat] = predict_proba(model, Z, t)
%PREDICT_PROBA Viena sąsaja visiems modeliams. Z jau pagal to modelio scaler.
%  p = P(M|z) ∈ (0,1); score – ranginis balas; ŷ = 1[p ≥ t].

if nargin < 3 || isempty(t)
    t = 0.5;
    if isfield(model, 'thresholds') && isfield(model.thresholds, 't_cost')
        t = model.thresholds.t_cost;
    end
end
n = size(Z, 1);
kind = model.kind;
switch kind
    case 'majority'
        score = zeros(n, 1);
        p = zeros(n, 1) + model.pM;
    case 'logreg'
        score = Z * model.Mdl.Beta + model.Mdl.Bias;
        p = 1 ./ (1 + exp(-score));
    case {'svm_rbf', 'svm_linear'}
        [~, sc] = predict(model.Mdl, Z);
        score = svm_positive_score(sc);
        if isfield(model, 'platt') && ~isempty(model.platt)
            p = platt_apply(model.platt, score);
        else
            p = 1 ./ (1 + exp(-score));
        end
    case 'mlp'
        if isfield(model, 'nets') && ~isempty(model.nets)
            acc = zeros(n, 1);
            for i = 1:numel(model.nets)
                acc = acc + mlp_p(model.nets{i}, Z);
            end
            p = acc / numel(model.nets);
        else
            p = mlp_p(model.net, Z);
        end
        score = logit_clip(p);
        if isfield(model, 'platt') && ~isempty(model.platt)
            p = platt_apply(model.platt, score);
        end
    case 'rbfnet'
        Phi = rbf_eval(Z, model.centers, model.widths);
        score = [ones(n, 1), Phi] * model.w;
        p = 1 ./ (1 + exp(-score));
        if isfield(model, 'platt') && ~isempty(model.platt)
            p = platt_apply(model.platt, score);
        end
    otherwise
        error('predict_proba: nezinomas kind=%s.', kind);
end
p = min(max(p(:), 1e-15), 1 - 1e-15);
score = score(:);
yhat = double(p >= t);
end

function s = svm_positive_score(sc)
if size(sc, 2) == 2
    s = sc(:, 2);
else
    s = sc(:);
end
end

function p = mlp_p(net, Z)
out = net(Z')';
if size(out, 2) == 2
    p = out(:, 2);
else
    p = out(:, 1);
end
p = p(:);
end

function z = logit_clip(p)
p = min(max(p, 1e-15), 1 - 1e-15);
z = log(p ./ (1 - p));
end

function Phi = rbf_eval(Z, centers, widths)
J = size(centers, 1);
n = size(Z, 1);
Phi = zeros(n, J);
for j = 1:J
    d2 = sum((Z - centers(j, :)).^2, 2);
    Phi(:, j) = exp(-d2 ./ (2 * widths(j).^2));
end
end
