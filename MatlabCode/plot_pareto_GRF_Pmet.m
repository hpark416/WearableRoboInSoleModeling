%% plot_pareto_GRF_Pmet
% Pareto-style scatter: max_GRF vs mean_Pmet for the fixed-height stiffness grid
% plus Bayesian-optimized spline soles (re-evaluated at the same des_dp_Mass).
%
% Prerequisites:
%   - height_<des_dp_Mass>_objectives.mat from gen_sweep_data(..., true, ...)
%   - optimal_spline_GRF.mat, optimal_spline_Pmet.mat, optimal_spline_Normalized.mat
%     from bayesian_optimization_spline.m (optional; missing files skipped with warning)
%
% Usage:
%   cd MatlabCode
%   plot_pareto_GRF_Pmet

%% CONFIG
cfg.model_name = 'FullHopper_kb_splines';
cfg.generated_data_folder = 'generated_data';
cfg.export_figures = true;
cfg.export_dir_matlab = fullfile('generated_data', 'figures');
cfg.export_png_to_data_for_report = true;
cfg.data_for_report_figures = fullfile('..', 'DataForReport', 'figures');
cfg.out_basename = 'pareto_GRF_vs_meanPmet';

%% Setup
root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root, 'helpers')));

[~, ~, des_dp_Mass] = load_params();
data_dir = fullfile(root, cfg.generated_data_folder, cfg.model_name);
fixed_mat = fullfile(data_dir, sprintf('height_%g_objectives.mat', des_dp_Mass));
if ~isfile(fixed_mat)
    error('Missing %s\nRun gen_sweep_data(''%s'', true, ...).', ...
        fixed_mat, cfg.model_name);
end

S = load(fixed_mat, 'out');
out = S.out;
grf_sweep = out(:, 1);
pmet_sweep = out(:, 3);

%% BO optima: full objective vector at same task height as sweep
bo_tags = {'GRF', 'Pmet', 'Normalized'};
bo_colors = [0.85 0.33 0.10; 0.00 0.45 0.74; 0.47 0.67 0.19];
bo_grf = nan(3, 1);
bo_pmet = nan(3, 1);
bo_ok = false(3, 1);

for b = 1:3
    matf = fullfile(root, cfg.generated_data_folder, ...
        sprintf('optimal_spline_%s.mat', bo_tags{b}));
    if ~isfile(matf)
        warning('plot_pareto_GRF_Pmet:MissingBO', ...
            'Skipping BO candidate %s — file not found:\n  %s', bo_tags{b}, matf);
        continue
    end
    Sb = load(matf, 'best');
    if ~isfield(Sb, 'best')
        warning('plot_pareto_GRF_Pmet:NoBest', 'No variable best in %s', matf);
        continue
    end
    [ft, dt] = generate_lookup(Sb.best);
    mat_params.force_table = ft;
    mat_params.disp_table = dt;
    [max_GRF, ~, mean_Pmet, ~] = eval_all_objectives(cfg.model_name, ...
        mat_params, [0.8, 1.0], des_dp_Mass);
    bo_grf(b) = max_GRF;
    bo_pmet(b) = mean_Pmet;
    bo_ok(b) = true;
end

%% Figure
fig = figure('Name', 'Pareto-style: GRF vs Pmet', 'Color', 'w', ...
    'Position', [100 100 720 560]);

hold on;
scatter(grf_sweep, pmet_sweep, 28, [0.65 0.65 0.65], 'filled', ...
    'MarkerFaceAlpha', 0.65, 'DisplayName', ...
    sprintf('Sweep (fixed height, n=%d)', size(out, 1)));

for b = 1:3
    if ~bo_ok(b)
        continue
    end
    scatter(bo_grf(b), bo_pmet(b), 120, bo_colors(b, :), 'filled', ...
        'MarkerEdgeColor', 'k', 'LineWidth', 0.6, ...
        'DisplayName', ['BO: ' bo_tags{b}]);
end

hold off;
grid on;
xlabel('Peak GRF (N)');
ylabel('Mean Pmet (W/kg)');
title(sprintf(['%s: impact vs metabolic proxy (fixed-height sweep + BO splines)\n', ...
    'Task: max dpMass \\approx %g m'], cfg.model_name, des_dp_Mass), ...
    'Interpreter', 'tex');
legend('Location', 'northeast');
set(gca, 'FontSize', 11);

%% Export
if cfg.export_figures
    out_dir = fullfile(root, cfg.export_dir_matlab);
    if ~isfolder(out_dir)
        mkdir(out_dir);
    end
    fname = fullfile(out_dir, [cfg.out_basename '_' cfg.model_name '.png']);
    exportgraphics(fig, fname, 'Resolution', 200);
    fprintf('Wrote %s\n', fname);

    if cfg.export_png_to_data_for_report
        dfr = fullfile(root, cfg.data_for_report_figures);
        if ~isfolder(dfr)
            mkdir(dfr);
        end
        fname2 = fullfile(dfr, 'fig_pareto_GRF_vs_meanPmet.png');
        exportgraphics(fig, fname2, 'Resolution', 200);
        fprintf('Wrote %s\n', fname2);
    end
end
