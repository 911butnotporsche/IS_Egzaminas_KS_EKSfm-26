function cfg = config()
%CONFIG Visos eksperimento konstantos vienoje strukturoje (plano 8 skyrius).
%  Hiperparametrai, kainos ir sėklos fiksuojami čia; testas jų niekada nekeičia.

thisDir = fileparts(mfilename('fullpath'));

cfg.seed = 42;
cfg.test_size = 0.20;
cfg.cv.k = 5;
cfg.cv.repeats = 5;
cfg.se_target = 0.98;

% [c_FN c_FP]; eilutė = tikroji klasė [B M] = [0 1]
cfg.cost = [5 1];
cfg.costMatrix = [0 1; 5 0];

cfg.prep.log_transform = false;
cfg.logreg.lambda = [1e-4 1e-3 1e-2 1e-1 1];

cfg.svm.C = [0.1 0.3 1 3 10 30 100];
cfg.svm.scale = [1 2 3 5 8 12 20];   % KernelScale s; gamma = 1/s^2
cfg.svm_linear.C = [0.01 0.03 0.1 0.3 1 3 10];
% Polinominis SVM (plano 8 lentele): d ir mastelis. C fiksuotas, kol OOF Se < 0,98.
cfg.svm_poly.degree = [2 3];
cfg.svm_poly.scale = [0.5 1 2 4];
cfg.svm_poly.C = 1;
cfg.svm_poly.r = 1;
cfg.feat.pearson_max = 0.95;
cfg.ensemble.weight_step = 0.1;
cfg.ensemble.members = {'svm_poly', 'mlp', 'logreg'};
cfg.split.nTest = 114;
cfg.split.nTestM = 42;
cfg.split.nTestB = 72;
cfg.threshold.require_se = true;
cfg.robust.noise_sigma = [0.10 0.25];
cfg.robust.missing_frac = [0.05 0.10];
cfg.robust.repeats = 5;
cfg.primary = 'ensemble';

cfg.mlp.H = [5 10 20];
cfg.mlp.lambda = [0 0.1 0.3];
cfg.mlp.seeds = 1:5;
cfg.mlp.max_fail = 10;

cfg.rbf.J = [10 20 40 80];
cfg.rbf.kappa = [0.5 1 2];
cfg.rbf.lambda = [1e-3 1e-1 1];

cfg.calib.kfold = 5;
cfg.eval.n_boot = 2000;
cfg.eval.bins = 10;
cfg.h3.outer_k = 5;
cfg.h3.outer_repeats = 10;

cfg.paths.root = thisDir;
cfg.paths.raw = fullfile(thisDir, 'data', 'raw');
cfg.paths.processed = fullfile(thisDir, 'data', 'processed');
cfg.paths.models = fullfile(thisDir, 'models');
cfg.paths.reports = fullfile(thisDir, 'reports');
cfg.paths.tables = fullfile(thisDir, 'reports', 'tables');
cfg.paths.figures = fullfile(thisDir, 'reports', 'figures');
cfg.paths.examples = fullfile(thisDir, 'data', 'examples');

cfg.urls.wdbc_data = 'https://archive.ics.uci.edu/ml/machine-learning-databases/breast-cancer-wisconsin/wdbc.data';
cfg.urls.wdbc_names = 'https://archive.ics.uci.edu/ml/machine-learning-databases/breast-cancer-wisconsin/wdbc.names';
cfg.meta.doi = '10.24432/C5DW2B';
cfg.meta.uci_id = 17;

% Vykdymo valdymas: 1–5 etapai. Testas atrakinamas vieną kartą evaluate_test.m.
cfg.run.stage = 5;
% H3 (10 x 5, M4 pries B1) paleidziama atskirai: repeated_nested_cv(cfg).
cfg.run.h3 = false;
end
