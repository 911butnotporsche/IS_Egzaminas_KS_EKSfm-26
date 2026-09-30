function thresholds = choose_threshold(p, y, cfg)
%CHOOSE_THRESHOLD Kolokviumo (5): t*=c_FP/(c_FP+c_FN)=1/6;
%  (6): EC(t)=c_FN·FN(t)+c_FP·FP(t), t_cost=arg min_t EC(t). OOF p, tinklelis 0,01.

p = p(:);
y = y(:);
if numel(p) ~= numel(y)
    error('choose_threshold: p ir y ilgis nesutampa.');
end
if numel(y) == 569
    error('WDBC:Thr:FullSet', 'choose_threshold: n=569 — tik OOF mokymo dalis.');
end
cFN = cfg.cost(1);
cFP = cfg.cost(2);
tgrid = 0:0.01:1;

requireSe = true;
if isfield(cfg, 'threshold') && isfield(cfg.threshold, 'require_se')
    requireSe = logical(cfg.threshold.require_se);
end

bestEC = inf;
t_cost = 0;
bestJ = -inf;
t_youden = 0;
t_se98 = 0;
foundSe = false;
bestSe = -inf;
t_maxSe = 0;
EC_se98 = NaN;

for i = 1:numel(tgrid)
    t = tgrid(i);
    yhat = p >= t;
    FN = sum(y == 1 & ~yhat);
    FP = sum(y == 0 & yhat);
    TP = sum(y == 1 & yhat);
    TN = sum(y == 0 & ~yhat);
    Se = TP / max(TP + FN, eps);
    Sp = TN / max(TN + FP, eps);
    EC = cFN * FN + cFP * FP;
    if EC < bestEC - 1e-12
        bestEC = EC;
        t_cost = t;
    end
    J = Se + Sp - 1;
    if J > bestJ + 1e-12
        bestJ = J;
        t_youden = t;
    end
    if Se > bestSe + 1e-12 || (abs(Se - bestSe) <= 1e-12 && t >= t_maxSe)
        bestSe = Se;
        t_maxSe = t;
    end
    if Se >= cfg.se_target
        t_se98 = t;
        foundSe = true;
        EC_se98 = EC;
    end
end
if ~foundSe
    % Plano 4.3: jei Se >= 0,98 nepasiekiamas, imamas didžiausio OOF Se slenkstis.
    t_se98 = t_maxSe;
    yhat = p >= t_se98;
    FN = sum(y == 1 & ~yhat);
    FP = sum(y == 0 & yhat);
    EC_se98 = cFN * FN + cFP * FP;
    if requireSe
        error('choose_threshold: joks t nedave OOF Se >= %.2f.', cfg.se_target);
    end
end

thresholds = struct();
thresholds.t_cost = t_cost;
thresholds.t_se98 = t_se98;
thresholds.t_youden = t_youden;
thresholds.t_bayes = cFP / (cFP + cFN);
thresholds.EC_cost = bestEC;
thresholds.EC_se98 = EC_se98;
thresholds.J_youden = bestJ;
thresholds.se_target_met = foundSe;
thresholds.se_at_t_se98 = bestSe;
if foundSe
    yhat = p >= t_se98;
    TP = sum(y == 1 & yhat);
    FN = sum(y == 1 & ~yhat);
    thresholds.se_at_t_se98 = TP / max(TP + FN, eps);
end
end
