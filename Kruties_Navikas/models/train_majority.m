function mdl = train_majority(y)
%TRAIN_MAJORITY B0: visada B (y=0). Plano atskaita, A0 sanity.
%  Tikimybė p(M)=0; AUC su konstantiniu balu = 0,5. Fit nenaudoja požymių.

y = y(:);
if numel(y) == 569
    error('WDBC:Majority:FullSet', 'train_majority: n=569 — tik mokymo dalis.');
end
mdl = struct();
mdl.kind = 'majority';
mdl.pM = 0;
mdl.priorM = mean(y == 1);
mdl.n = numel(y);
end
