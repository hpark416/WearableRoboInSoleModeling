%% compare_fixed_vs_free_height_plots
% Aggregates free-height sweep outputs (amplitude = 1, one sim per k/maxcomp file)
% and compares them to fixed-height objectives from height_<des>_objectives.mat.
%
% Prerequisites:
%   - Run gen_sweep_data(model_name, false, use_curve) to produce k_*_maxcomp_*.mat
%   - Run gen_sweep_data(model_name, true, use_curve)  to produce height_*_objectives.mat
%
% Usage:
%   cd MatlabCode
%   compare_fixed_vs_free_height_plots

%% CONFIG
cfg.model_name = 'FullHopper_kb_splines';  % or 'FullHopper_kb'
cfg.generated_data_folder = 'generated_data';
cfg.export_figures = true;
cfg.export_dir = fullfile('generated_data', 'figures', 'fixed_vs_free_height');
% Write aggregated free-height matrix for reuse (skip re-reading all simouts).
cfg.save_free_objectives_cache = true;

%% Setup
root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root, 'helpers')));

data_dir = fullfile(root, cfg.generated_data_folder, cfg.model_name);
if ~isfolder(data_dir)
    error('Missing folder: %s', data_dir);
end

[~, ~, des_dp_Mass] = load_params();
fixed_mat = fullfile(data_dir, sprintf('height_%g_objectives.mat', des_dp_Mass));
if ~isfile(fixed_mat)
    error(['Missing %s\nRun gen_sweep_data(''%s'', true, ...).'], ...
        fixed_mat, cfg.model_name);
end

Sfix = load(fixed_mat, 'out', 'param_combinations');
out_fixed = Sfix.out;
param_fixed = Sfix.param_combinations;
n = size(out_fixed, 1);

%% Build / load free-height objectives (same grid order as fixed sweep)
cache_mat = fullfile(data_dir, 'free_height_objectives_cache.mat');
use_cache = false;
if isfile(cache_mat)
    Sc = load(cache_mat);
    if isfield(Sc, 'out_free') && isfield(Sc, 'param_combinations') && ...
            size(Sc.out_free, 1) == n && numel(Sc.param_combinations) == n
        out_free = Sc.out_free;
        use_cache = true;
        fprintf('Loaded cached free-height objectives: %s\n', cache_mat);
    end
end
if ~use_cache
    out_free = collect_free_height_objectives(data_dir, param_fixed, n);
    if cfg.save_free_objectives_cache
        param_combinations = param_fixed;
        save(cache_mat, 'out_free', 'param_combinations');
        fprintf('Wrote cache: %s\n', cache_mat);
    end
end

% Column semantics match height_*_objectives: [max_GRF, max_dpMass, mean_Pmet, amp]
% Free height: amplitude is always 1.
assert(size(out_free, 1) == n, 'Row count mismatch fixed vs free.');
ok = all(isfinite(out_fixed), 2) & all(isfinite(out_free), 2);
if ~all(ok)
    warning('compare_fixed_vs_free_height:NaNRows', ...
        '%d rows missing free-height simouts; plots use finite rows only.', ...
        sum(~ok));
end

meanP_fixed = out_fixed(:, 3);
meanP_free = out_free(:, 3);
dp_fixed = out_fixed(:, 2);
dp_free = out_free(:, 2);
grf_fixed = out_fixed(:, 1);
grf_free = out_free(:, 1);

%% --- Figure 1: achieved height histogram (overlay)
f1 = figure('Name', 'Fixed vs free: max_dpMass', 'Color', 'w', ...
    'Position', [80 80 900 420]);

hold on;
histogram(dp_fixed, 'FaceAlpha', 0.55, 'DisplayName', ...
    sprintf('Fixed height (target %.3g m)', des_dp_Mass));
histogram(dp_free(isfinite(dp_free)), 'FaceAlpha', 0.55, 'DisplayName', ...
    'Free height (amp = 1)');
xline(des_dp_Mass, 'r--', 'LineWidth', 1.8, 'DisplayName', 'Target height');
hold off;
grid on;
xlabel('max dpMass (m)');
ylabel('count');
title(sprintf('%s: peak COM lift - fixed-height sweep vs free-height sweep', ...
    cfg.model_name), 'Interpreter', 'none');
legend('Location', 'best');
set(gca, 'FontSize', 10);

%% --- Figure 2: Pmet vs achieved height (both protocols)
f2 = figure('Name', 'Fixed vs free: Pmet vs height', 'Color', 'w', ...
    'Position', [100 100 900 420]);

hold on;
scatter(dp_fixed(ok), meanP_fixed(ok), 36, [0.85 0.33 0.10], 'filled', ...
    'DisplayName', 'Fixed height');
scatter(dp_free(ok), meanP_free(ok), 36, [0.00 0.45 0.74], 'filled', ...
    'DisplayName', 'Free height');
xline(des_dp_Mass, 'r--', 'LineWidth', 1.2, 'DisplayName', 'Target');
hold off;
grid on;
xlabel('max dpMass (m)');
ylabel('mean Pmet (W/kg)');
title(sprintf('%s: metabolic proxy vs peak lift', cfg.model_name), ...
    'Interpreter', 'none');
legend('Location', 'best');
set(gca, 'FontSize', 10);

%% --- Figure 3: Pmet vs peak GRF (both protocols)
f3 = figure('Name', 'Fixed vs free: Pmet vs GRF', 'Color', 'w', ...
    'Position', [120 120 900 420]);

hold on;
scatter(grf_fixed(ok), meanP_fixed(ok), 36, [0.85 0.33 0.10], 'filled', ...
    'DisplayName', 'Fixed height');
scatter(grf_free(ok), meanP_free(ok), 36, [0.00 0.45 0.74], 'filled', ...
    'DisplayName', 'Free height');
hold off;
grid on;
xlabel('Peak GRF (N)');
ylabel('mean Pmet (W/kg)');
title(sprintf('%s: metabolic proxy vs peak GRF', cfg.model_name), ...
    'Interpreter', 'none');
legend('Location', 'best');
set(gca, 'FontSize', 10);

%% --- Figure 4: paired delta Pmet (same sole, two protocols)
dP = meanP_fixed - meanP_free;
f4 = figure('Name', 'Delta Pmet fixed minus free', 'Color', 'w', ...
    'Position', [140 140 520 380]);
histogram(dP(ok), 'FaceAlpha', 0.85);
grid on;
xlabel('\Delta mean Pmet = fixed - free (W/kg)');
ylabel('count');
title(sprintf('%s: per-grid-point comparison (n=%d)', cfg.model_name, n), ...
    'Interpreter', 'none');
set(gca, 'FontSize', 10);

%% Export
if cfg.export_figures
    out_dir = fullfile(root, cfg.export_dir);
    if ~isfolder(out_dir)
        mkdir(out_dir);
    end
    tag = cfg.model_name;
    exportgraphics(f1, fullfile(out_dir, sprintf('%s_fixed_vs_free_f1_dpMass.png', tag)), ...
        'Resolution', 200);
    exportgraphics(f2, fullfile(out_dir, sprintf('%s_fixed_vs_free_f2_Pmet_vs_height.png', tag)), ...
        'Resolution', 200);
    exportgraphics(f3, fullfile(out_dir, sprintf('%s_fixed_vs_free_f3_Pmet_vs_GRF.png', tag)), ...
        'Resolution', 200);
    exportgraphics(f4, fullfile(out_dir, sprintf('%s_fixed_vs_free_f4_delta_Pmet.png', tag)), ...
        'Resolution', 200);
    fprintf('Figures saved under %s\n', out_dir);
end

fprintf(['Done. Interpretation: fixed-height pins dpMass ~ target; ', ...
    'free-height varies peak lift with sole at amp=1.\n']);

%% --- Local
function out_free = collect_free_height_objectives( ...
    data_dir, param_fixed, n_expected)

out_free = nan(n_expected, 4);
missing = 0;

for k = 1:n_expected
    p = param_fixed(k);
    K = p.K_shoe;
    t = p.thickness;
    fname = fullfile(data_dir, ...
        strcat('k_', num2str(K), '_maxcomp_', num2str(t), '.mat'));

    if ~isfile(fname)
        warning('compare_fixed_vs_free_height:MissingSim', ...
            'Missing free-height file: %s', fname);
        missing = missing + 1;
        continue
    end

    S = load(fname, 'simout');
    if ~isfield(S, 'simout')
        warning('compare_fixed_vs_free_height:BadFile', ...
            'No simout in %s', fname);
        missing = missing + 1;
        continue
    end

    [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(S.simout);
    out_free(k, :) = [max_GRF, max_dpMass, mean_Pmet, 1];
end

if missing > 0
    warning('compare_fixed_vs_free_height:Incomplete', ...
        '%d / %d grid points missing free-height simouts.', missing, n_expected);
end

end
