function p = platt_apply(platt, f)
%PLATT_APPLY Kolokviumo (4): P=1/(1+exp(A f+B)) su jau išmoktais A, B.
f = f(:);
p = 1 ./ (1 + exp(platt.A .* f + platt.B));
p = min(max(p, 1e-15), 1 - 1e-15);
end
