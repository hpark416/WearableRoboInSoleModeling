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
cfg.model_name = 'FullHopper_kb';   % or 'FullHopper_kb_splines'
cfg.generated_data_folder = 'generated_data';
cfg.matfile = '';  % leave empty to auto-build from load_params des_dp_Mass

cfg.rerun_sim = false;          % true: re-simulate (slow) for kin/muscle proxies
cfg.max_rerun_points = inf;     % limit grid points when rerun_sim is true
cfg.muscle_signal_name = '';    % e.g. logged Simulink signal name; '' skips

cfg.export_figures = false;
cfg.export_dir = fullfile('generated_data', 'figures');

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
    'Color', 'w', 'Position', [100 100 1100 420]);

tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
scatter(amplitude_res_col, mean_Pmet_col, 36, max_GRF_col, 'filled');
cb = colorbar; ylabel(cb, 'max GRF');
xlabel('amplitude\_res');
ylabel('mean Pmet');
title(sprintf('Pmet vs amplitude (color=GRF)\n%s', cfg.model_name));
grid on;

nexttile;
scatter(max_GRF_col, mean_Pmet_col, 36, amplitude_res_col, 'filled');
cb = colorbar; ylabel(cb, 'amplitude\_res');
xlabel('max GRF');
ylabel('mean Pmet');
title('Pmet vs max GRF');
grid on;

nexttile;
scatter(amplitude_res_col, max_GRF_col, 36, mean_Pmet_col, 'filled');
cb = colorbar; ylabel(cb, 'mean Pmet');
xlabel('amplitude\_res');
ylabel('max GRF');
title('GRF vs amplitude');
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

for k = 1:n_run
    params = param_combinations(k);
    amp = amplitude_res_col(k);
    simIn = build_sim_input_for_param(cfg.model_name, params, amp);
    simOut = sim(simIn);
    [~, ~, ~, kin] = analyze_sole_output_extended(simOut, cfg.muscle_signal_name);
    max_abs_ddpdt(k) = kin.max_abs_ddpdt;
    max_abs_dGRFdt(k) = kin.max_abs_dGRFdt;
    muscle_mean_abs(k) = kin.muscle_mean_abs;
    if mod(k, 20) == 0
        fprintf('  completed %d\n', k);
    end
end

set_param(cfg.model_name, 'FastRestart', 'off');
close_system(cfg.model_name, 0);
warning(w);

Pmet_run = mean_Pmet_col(1:n_run);

f3 = figure('Name', 'Pmet vs kin proxies (re-run)', 'Color', 'w', ...
    'Position', [120 120 1000 400]);
tiledlayout(1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

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
