function w = class_weights(y, cfg)
%CLASS_WEIGHTS ω = c_FN jei M, c_FP jei B; normuota mean(ω)=1 (5.2 skyrius).
y = y(:);
w = zeros(size(y));
w(y == 1) = cfg.cost(1);
w(y == 0) = cfg.cost(2);
w = w / mean(w);
end
