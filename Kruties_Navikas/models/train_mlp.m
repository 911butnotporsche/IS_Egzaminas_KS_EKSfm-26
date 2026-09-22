function mdl = train_mlp(Z, y, H, lambda, seed, cfg, valFrac)
%TRAIN_MLP M2, Kolokviumo 3.3: 30→H→1, h=tanh(W1 z+b1), p=σ(w2^T h+b2).
%  5 sėklų vidurkis tune_cv. Val. poaibis tik iš foldo mokymo (divideind), ne testas.

if nargin < 7 || isempty(valFrac)
    valFrac = 0.20;
end
y = y(:);
n = size(Z, 1);
if n ~= numel(y)
    error('train_mlp: eiluciu skaicius nelygus numel(y).');
end
if n == 569
    error('WDBC:MLP:FullSet', 'train_mlp: n=569 — tik mokymo dalis.');
end

rng(seed, 'twister');
cvp = cvpartition(y, 'HoldOut', valFrac, 'Stratify', true);
trInd = find(training(cvp));
vaInd = find(test(cvp));

net = patternnet(H, 'trainscg');
net.performParam.regularization = lambda;
net.trainParam.max_fail = cfg.mlp.max_fail;
net.trainParam.epochs = 250;
net.trainParam.showWindow = false;
net.trainParam.showCommandLine = false;
net.divideFcn = 'divideind';
net.divideParam.trainInd = trInd';
net.divideParam.valInd = vaInd';
net.divideParam.testInd = [];
net.inputs{1}.processFcns = {};
net.outputs{2}.processFcns = {};

T = y';
EW = class_weights(y, cfg)';
net = train(net, Z', T, {}, {}, EW, 'useParallel', 'no', 'showResources', 'no');

mdl = struct();
mdl.kind = 'mlp';
mdl.net = net;
mdl.H = H;
mdl.lambda = lambda;
mdl.seed = seed;
end
