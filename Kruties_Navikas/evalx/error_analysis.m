function error_analysis(cfg, pack, ytest, Xtest, ytrain, Xtrain, featNames, sp)
%ERROR_ANALYSIS FN/FP teste: požymiai, p, SVM balas, |p−t|; medianos vs M/B.
%  concave_points_worst, area_worst. Testo statistikos negrįžta į fit.

t = pack.svm_rbf.thresholds.t_se98;
p = pack.svm_rbf.p;
score = pack.svm_rbf.score;
yhat = p >= t;
idxTest = sp.idxTest(:);
if ischar(featNames) || isstring(featNames)
    featNames = cellstr(featNames);
end
if isrow(featNames)
    featNames = featNames(:)';
end
ixCP = find(strcmp(featNames, 'concave_points_worst'), 1);
ixAR = find(strcmp(featNames, 'area_worst'), 1);
ixTM = find(strcmp(featNames, 'texture_mean'), 1);
ixSW = find(strcmp(featNames, 'smoothness_worst'), 1);
if isempty(ixCP) || isempty(ixAR)
    error('error_analysis: nera concave_points_worst / area_worst featNames.');
end

medM = median(Xtrain(ytrain == 1, :), 1);
medB = median(Xtrain(ytrain == 0, :), 1);

fn = find(ytest == 1 & ~yhat);
fp = find(ytest == 0 & yhat);
rows = {};
rows = add_cases(rows, fn, 'FN', ytest, p, score, t, Xtest, idxTest, featNames, medM, medB, ixCP, ixAR);
rows = add_cases(rows, fp, 'FP', ytest, p, score, t, Xtest, idxTest, featNames, medM, medB, ixCP, ixAR);

if isempty(fn)
    [~, ord] = sort(p(ytest == 1), 'ascend');
    pos = find(ytest == 1);
    take = pos(ord(1:min(10, numel(ord))));
    rows = add_cases(rows, take, 'near_miss', ytest, p, score, t, Xtest, idxTest, featNames, medM, medB, ixCP, ixAR);
end

hdr = [{'case_type', 'abs_idx', 'p', 'svm_score', 't', 'dist_to_t', ...
    'cp_minus_medM', 'ar_minus_medM', 'cp_minus_medB', 'ar_minus_medB'}, featNames];
if isempty(rows)
    Tab = cell2table(cell(0, numel(hdr)), 'VariableNames', hdr);
else
    Tab = cell2table(rows, 'VariableNames', hdr);
end
writetable(Tab, fullfile(cfg.paths.reports, 'error_cases.csv'));

fid = fopen(fullfile(cfg.paths.reports, 'error_profile.txt'), 'w');
fprintf(fid, 't_se98=%.4f  FN=%d  FP=%d\n', t, numel(fn), numel(fp));
fprintf(fid, 'train median M: cp_worst=%.6g area_worst=%.6g', medM(ixCP), medM(ixAR));
if ~isempty(ixTM) && ~isempty(ixSW)
    fprintf(fid, ' texture_mean=%.6g smoothness_worst=%.6g', medM(ixTM), medM(ixSW));
end
fprintf(fid, '\n');
fprintf(fid, 'train median B: cp_worst=%.6g area_worst=%.6g', medB(ixCP), medB(ixAR));
if ~isempty(ixTM) && ~isempty(ixSW)
    fprintf(fid, ' texture_mean=%.6g smoothness_worst=%.6g', medB(ixTM), medB(ixSW));
end
fprintf(fid, '\n');
if ~isempty(fn)
    fprintf(fid, 'FN median: cp_worst=%.6g area_worst=%.6g\n', ...
        median(Xtest(fn, ixCP)), median(Xtest(fn, ixAR)));
end
if ~isempty(fp)
    fprintf(fid, 'FP median: cp_worst=%.6g area_worst=%.6g\n', ...
        median(Xtest(fp, ixCP)), median(Xtest(fp, ixAR)));
end
fclose(fid);
end

function rows = add_cases(rows, ix, typ, ytest, p, score, t, Xtest, idxTest, featNames, medM, medB, ixCP, ixAR) %#ok<INUSL>
for k = 1:numel(ix)
    i = ix(k);
    x = Xtest(i, :);
    rec = [{typ, idxTest(i), p(i), score(i), t, abs(p(i) - t), ...
        x(ixCP) - medM(ixCP), x(ixAR) - medM(ixAR), ...
        x(ixCP) - medB(ixCP), x(ixAR) - medB(ixAR)}, num2cell(x)];
    rows(end+1, :) = rec; %#ok<AGROW>
end
end
