%% plot_fixed_height_Pmet_analysis
% For matched-height sweeps (height_*_objectives.mat), plot relationships
% between mean_Pmet, amplitude_res, peak GRF, and optional kinematic proxies.
%
% Fast path: load existing objectives matrix only (columns match gen_sweep_data).
% Extended path: re-run simulations at stored amplitude_res to compute
%   max |d(dp_Mass)/dt|, max |d(GRF)/dt|, and optionally a user-named logged signal.
%
% Usage:
%   cd MatlabCode
%   plot_fixed_height_Pmet_analysis
%
% Edit CONFIG block below as needed.

%% CONFIG
cfg.model_name = 'FullHopper_kb_splines';   % or 'FullHopper_kb_splines''FullHopper_kb'
cfg.generated_data_folder = 'generated_data';
cfg.matfile = '';  % leave empty to auto-build from load_params des_dp_Mass

cfg.rerun_sim = true;          % true: re-simulate (slow) for kin/muscle proxies
cfg.max_rerun_points = inf;     % limit grid points when rerun_sim is true
cfg.muscle_signal_name = 'm_FV';    % e.g. logged Simulink signal name; '' skips %'m_FV' mus Vel proxy

% Parallel rerun (requires Parallel Computing Toolbox). Uses Simulink parsim().
cfg.use_parallel = true;

cfg.export_figures = true;
cfg.export_dir = fullfile('generated_data', 'figures', 'heightPmetAnalysisFigures');

% Step C (stats): write correlation CSV(s) next to figures (see FINDINGS_AND_NEXT_STEPS.md).
cfg.save_stats = true;
cfg.save_stats_fast_path = true;  % if true and rerun_sim=false, still save objectives-only stats

%% Setup paths
root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root, 'helpers')));
addpath(genpath(fullfile(root, 'models')));

[~, ~, des_dp_Mass] = load_params();
data_dir = fullfile(root, cfg.generated_data_folder, cfg.model_name);

if isempty(cfg.matfile)
    matfile = fullfile(data_dir, ...
        strcat('height_', num2str(des_dp_Mass), '_objectives.mat'));
else
    matfile = cfg.matfile;
end

if ~isfile(matfile)
    error(['Missing file: %s\nRun gen_sweep_data(..., true, ...) first ', ...
        'for this model.'], matfile);
end

S = load(matfile);
out = S.out;
param_combinations = S.param_combinations;

max_GRF_col = out(:, 1);
max_dpMass_col = out(:, 2);
mean_Pmet_col = out(:, 3);
amplitude_res_col = out(:, 4);

n = size(out, 1);

%% --- Figures from saved objectives only ---
f1 = figure('Name', 'Fixed height: Pmet vs amplitude and GRF', ...
    'Color', 'w', 'Position', [80 80 1700 520]);

tiledlayout(1, 3, 'Padding', 'normal', 'TileSpacing', 'normal');

nexttile;
scatter(amplitude_res_col, mean_Pmet_col, 36, max_GRF_col, 'filled');
cb = colorbar; ylabel(cb, 'Peak GRF (N)');
cb.Location = 'southoutside';
xlabel('Resolved amplitude (-)', 'Interpreter', 'none');
ylabel('Mean Pmet (W/kg)', 'Interpreter', 'none');
title(sprintf('Pmet vs amplitude (color: Peak GRF)\n%s', cfg.model_name), ...
    'Interpreter', 'none');
set(gca, 'FontSize', 10);
set(cb, 'FontSize', 9);
grid on;

nexttile;
scatter(max_GRF_col, mean_Pmet_col, 36, amplitude_res_col, 'filled');
cb = colorbar; ylabel(cb, 'Resolved amplitude (-)');
cb.Location = 'southoutside';
xlabel('Peak GRF (N)');
ylabel('Mean Pmet (W/kg)', 'Interpreter', 'none');
title('Pmet vs Peak GRF', 'Interpreter', 'none');
set(gca, 'FontSize', 10);
set(cb, 'FontSize', 9);
grid on;

nexttile;
scatter(amplitude_res_col, max_GRF_col, 36, mean_Pmet_col, 'filled');
cb = colorbar; ylabel(cb, 'Mean Pmet (W/kg)', 'Interpreter', 'none');
cb.Location = 'southoutside';
xlabel('Resolved amplitude (-)', 'Interpreter', 'none');
ylabel('Peak GRF (N)');
title('Peak GRF vs amplitude', 'Interpreter', 'none');
set(gca, 'FontSize', 10);
set(cb, 'FontSize', 9);
grid on;

sgtitle(sprintf( ...
    'Matched height target dpMass \\approx %g m (check spread in next fig)', ...
    des_dp_Mass), 'Interpreter', 'tex');

f2 = figure('Name', 'Fixed height: achieved dpMass', 'Color', 'w');
histogram(max_dpMass_col);
xline(des_dp_Mass, 'r--', 'LineWidth', 1.5);
xlabel('max dpMass (m)');
ylabel('count');
title(sprintf('%s: distribution of achieved peak COM disp', cfg.model_name));
grid on;

%% --- Optional: re-run sims for extended proxies ---
if ~cfg.rerun_sim
    fprintf(['plot_fixed_height_Pmet_analysis: rerun_sim=false. ', ...
        'Kin/muscle scatter figures skipped.\n']);
    if isfield(cfg, 'save_stats') && cfg.save_stats && ...
            isfield(cfg, 'save_stats_fast_path') && cfg.save_stats_fast_path
        save_pmet_correlation_csv(root, cfg, mean_Pmet_col, ...
            [max_GRF_col, max_dpMass_col, amplitude_res_col], ...
            {'max_GRF', 'max_dpMass', 'amplitude_res'}, 'objectives_only');
    end
    if cfg.export_figures
        export_standard_figs(cfg, f1, f2);
    end
    return
end

model_filename = fullfile(root, 'models', strcat(cfg.model_name, '.slx'));
if ~isfile(model_filename)
    error('Model not found: %s', model_filename);
end

w = warning('off', 'all');
load_system(model_filename);
set_param(cfg.model_name, 'SimulationMode', 'accelerator');
use_curve = isfield(param_combinations(1), 'force_table');
if use_curve
    set_param(cfg.model_name, 'FastRestart', 'off');
else
    set_param(cfg.model_name, 'FastRestart', 'on');
end

n_run = min(n, cfg.max_rerun_points);
max_abs_ddpdt = nan(n_run, 1);
max_abs_dGRFdt = nan(n_run, 1);
muscle_mean_abs = nan(n_run, 1);

fprintf('Re-running %d / %d simulations for extended metrics...\n', n_run, n);

simInC = cell(n_run, 1);
for k = 1:n_run
    simInC{k} = build_sim_input_for_param(cfg.model_name, ...
        param_combinations(k), amplitude_res_col(k));
end
simInBatch = [simInC{:}];

can_parallel = cfg.use_parallel && ...
    license('test', 'Distrib_Computing_Toolbox') && ...
    exist('parsim', 'file') == 2;

if can_parallel
    try
        if isempty(gcp('nocreate'))
            parpool;
        end
    catch ME
        warning('plot_fixed_height_Pmet_analysis:NoPool', ...
            'Could not start parallel pool (%s). Using serial sim.', ME.message);
        can_parallel = false;
    end
end

if can_parallel
    if use_curve
        fastRestartOpt = 'off';  % align with gen_sweep_data for splines
    else
        fastRestartOpt = 'on';
    end
    fprintf('Using parsim() with UseFastRestart=%s.\n', fastRestartOpt);
    simOutBatch = parsim(simInBatch, ...
        'ShowProgress', 'on', ...
        'UseFastRestart', fastRestartOpt);
    for k = 1:n_run
        [~, ~, ~, kin] = analyze_sole_output_extended( ...
            simOutBatch(k), cfg.muscle_signal_name);
        max_abs_ddpdt(k) = kin.max_abs_ddpdt;
        max_abs_dGRFdt(k) = kin.max_abs_dGRFdt;
        muscle_mean_abs(k) = kin.muscle_mean_abs;
    end
else
    for k = 1:n_run
        simOut = sim(simInBatch(k));
        [~, ~, ~, kin] = analyze_sole_output_extended(simOut, ...
            cfg.muscle_signal_name);
        max_abs_ddpdt(k) = kin.max_abs_ddpdt;
        max_abs_dGRFdt(k) = kin.max_abs_dGRFdt;
        muscle_mean_abs(k) = kin.muscle_mean_abs;
        if mod(k, 20) == 0
            fprintf('  completed %d\n', k);
        end
    end
end

set_param(cfg.model_name, 'FastRestart', 'off');
close_system(cfg.model_name, 0);
warning(w);

Pmet_run = mean_Pmet_col(1:n_run);

if isfield(cfg, 'save_stats') && cfg.save_stats
    Xext = [amplitude_res_col(1:n_run), max_GRF_col(1:n_run), ...
        max_abs_ddpdt, max_abs_dGRFdt, muscle_mean_abs];
    pred = {'amplitude_res', 'max_GRF', 'max_abs_ddpdt', ...
        'max_abs_dGRFdt', 'muscle_mean_abs'};
    save_pmet_correlation_csv(root, cfg, Pmet_run, Xext, pred, 'extended');
end

f3 = figure('Name', 'Pmet vs kin proxies (re-run)', 'Color', 'w', ...
    'Position', [120 120 1200 400]);
tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'normal');

nexttile;
scatter(max_abs_ddpdt, Pmet_run, 'filled');
xlabel('max |d(dp\_Mass)/dt| (m/s)');
ylabel('mean Pmet');
title('COM speed proxy');
grid on;

nexttile;
scatter(max_abs_dGRFdt, Pmet_run, 'filled');
xlabel('max |d(GRF)/dt| (N/s)');
ylabel('mean Pmet');
title('Force-rate proxy');
grid on;

nexttile;
if all(isnan(muscle_mean_abs))
    text(0.1, 0.5, sprintf( ...
        ['No muscle signal "%s" in simOut.\nSet cfg.muscle_signal_name ', ...
        'to a logged variable name.'], cfg.muscle_signal_name), ...
        'Units', 'normalized', 'FontSize', 11);
    axis off;
else
    scatter(muscle_mean_abs, Pmet_run, 'filled');
    xlabel(sprintf('mean |%s| (last cycle)', cfg.muscle_signal_name));
    ylabel('mean Pmet');
    title('Logged muscle proxy');
    grid on;
end

sgtitle(sprintf('%s: extended metrics (n=%d)', cfg.model_name, n_run));

if cfg.export_figures
    export_standard_figs(cfg, f1, f2, f3);
end

%% --- Local helpers ---
function save_pmet_correlation_csv(root, cfg, y, X, pred_names, tag)

out_dir = fullfile(root, cfg.export_dir);
if ~isfolder(out_dir)
    mkdir(out_dir);
end
fname = fullfile(out_dir, sprintf('%s_Pmet_stats_%s.csv', cfg.model_name, tag));
fid = fopen(fname, 'w');
if fid < 0
    warning('plot_fixed_height_Pmet_analysis:StatsFile', ...
        'Could not write stats file: %s', fname);
    return
end
fprintf(fid, ['predictor,n_valid,r_pearson,p_pearson,r_spearman\n']);

for j = 1:numel(pred_names)
    xj = X(:, j);
    ok = ~isnan(y(:)) & ~isnan(xj(:));
    n_ok = sum(ok);
    if n_ok < 5
        fprintf(fid, '%s,%d,NaN,NaN,NaN\n', pred_names{j}, n_ok);
        continue
    end
    yy = y(ok);
    xx = xj(ok);
    [C, P] = corrcoef(yy, xx);
    r_p = C(1, 2);
    p_p = P(1, 2);
    r_s = NaN;
    try
        r_s = corr(yy, xx, 'type', 'Spearman', 'rows', 'complete');
    catch
        r_s = NaN;
    end
    fprintf(fid, '%s,%d,%.6g,%.6g,%.6g\n', pred_names{j}, n_ok, r_p, p_p, r_s);
end
fclose(fid);
fprintf('Wrote correlation table: %s\n', fname);

end

function simIn = build_sim_input_for_param(model_name, params, amplitude)

if isfield(params, 'force_table') && isfield(params, 'disp_table')
    simIn = Simulink.SimulationInput(model_name);
    simIn = simIn.setVariable('force_table', params.force_table, ...
        'Workspace', model_name);
    simIn = simIn.setVariable('disp_table', params.disp_table, ...
        'Workspace', model_name);
    simIn = simIn.setVariable('amplitude', amplitude, ...
        'Workspace', model_name);
elseif contains(model_name, 'splines', 'IgnoreCase', true)
    % height_*_objectives.mat stores linear K_shoe/thickness only; rebuild tables
    [ft, dt] = straight_spline_tables_from_kb(params.K_shoe, params.thickness);
    simIn = Simulink.SimulationInput(model_name);
    simIn = simIn.setVariable('force_table', ft, 'Workspace', model_name);
    simIn = simIn.setVariable('disp_table', dt, 'Workspace', model_name);
    simIn = simIn.setVariable('amplitude', amplitude, 'Workspace', model_name);
else
    material_params.K_shoe = params.K_shoe;
    material_params.thickness = params.thickness;
    [simIn, ~] = assemble_sim_inputs(model_name, material_params, amplitude);
end

end

function export_standard_figs(cfg, varargin)

out_dir = fullfile(fileparts(mfilename('fullpath')), cfg.export_dir);
if ~isfolder(out_dir)
    mkdir(out_dir);
end
tag = cfg.model_name;
for fi = 1:numel(varargin)
    f = varargin{fi};
    if isvalid(f)
        fname = fullfile(out_dir, sprintf('%s_Pmet_analysis_f%d.png', tag, fi));
        exportgraphics(f, fname, 'Resolution', 200);
    end
end
fprintf('Figures saved under %s\n', out_dir);

end
