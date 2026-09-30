function error_analysis(cfg, pack, ytest, Xtest, ytrain, Xtrain, featNames, sp)
%ERROR_ANALYSIS Visi FN ir FP teste: požymiai, tikimybė, |p-t|, medianos.
%  Pagrindinis modelis — M4 (ansamblis), jei jis yra pakete.

if ischar(featNames) || isstring(featNames)
    featNames = cellstr(featNames);
end
if isrow(featNames)
    featNames = featNames(:)';
end
idxTest = sp.idxTest(:);
ixCP = find(strcmp(featNames, 'concave_points_worst'), 1);
ixAR = find(strcmp(featNames, 'area_worst'), 1);
if isempty(ixCP) || isempty(ixAR)
    error('error_analysis: nera concave_points_worst / area_worst featNames.');
end
medM = median(Xtrain(ytrain == 1, :), 1);
medB = median(Xtrain(ytrain == 0, :), 1);

if isfield(cfg, 'primary') && isfield(pack, cfg.primary)
    order = [{cfg.primary}, setdiff(fieldnames(pack)', {cfg.primary}, 'stable')];
else
    order = fieldnames(pack)';
end

rows = {};
fid = fopen(fullfile(cfg.paths.reports, 'error_profile.txt'), 'w');
for i = 1:numel(order)
    nm = order{i};
    if ~isfield(pack.(nm), 'p') || ~isfield(pack.(nm), 'thresholds')
        continue
    end
    t = pack.(nm).thresholds.t_se98;
    p = pack.(nm).p;
    score = pack.(nm).score;
    yhat = p >= t;
    fn = find(ytest == 1 & ~yhat);
    fp = find(ytest == 0 & yhat);
    rows = add_cases(rows, fn, 'FN', nm, ytest, p, score, t, Xtest, idxTest, medM, medB, ixCP, ixAR);
    rows = add_cases(rows, fp, 'FP', nm, ytest, p, score, t, Xtest, idxTest, medM, medB, ixCP, ixAR);
    fprintf(fid, '%s t_se98=%.4f FN=%d FP=%d\n', nm, t, numel(fn), numel(fp));
end
fprintf(fid, 'train median M: cp_worst=%.6g area_worst=%.6g\n', medM(ixCP), medM(ixAR));
fprintf(fid, 'train median B: cp_worst=%.6g area_worst=%.6g\n', medB(ixCP), medB(ixAR));
fclose(fid);

hdr = {'model', 'case_type', 'y_true', 'abs_idx', 'test_pos', 'p', 'score', 't', 'dist_to_t', ...
    'cp_minus_medM', 'ar_minus_medM', 'cp_minus_medB', 'ar_minus_medB'};
featHdr = cellfun(@(s) ['f_' s], featNames, 'UniformOutput', false);
hdr = [hdr, featHdr];
if isempty(rows)
    Tab = cell2table(cell(0, numel(hdr)), 'VariableNames', matlab.lang.makeValidName(hdr));
else
    Tab = cell2table(rows, 'VariableNames', matlab.lang.makeValidName(hdr));
end
writetable(Tab, fullfile(cfg.paths.reports, 'error_cases.csv'));
end

function rows = add_cases(rows, ix, typ, modelName, ytest, p, score, t, Xtest, idxTest, medM, medB, ixCP, ixAR)
for k = 1:numel(ix)
    i = ix(k);
    x = Xtest(i, :);
    rec = [{modelName, typ, ytest(i), idxTest(i), i, p(i), score(i), t, abs(p(i) - t), ...
        x(ixCP) - medM(ixCP), x(ixAR) - medM(ixAR), ...
        x(ixCP) - medB(ixCP), x(ixAR) - medB(ixAR)}, num2cell(x)];
    rows(end+1, :) = rec; %#ok<AGROW>
end
end
