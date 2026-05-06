%% plot_BO_spline_profiles_comparison
% Overlay force–displacement curves from Bayesian optimization spline runs
% against linear-sole references from (K_shoe, thickness).
%
% Prerequisites: run bayesian_optimization_spline.m (or have the .mat files).
% Saves: generated_data/optimal_spline_GRF.mat, ..._Pmet.mat, ..._Normalized.mat
% Each file contains struct `best` with fields x2,x3,x4,F2,F3,F4 (see generate_lookup).
%
% Usage:
%   cd MatlabCode
%   plot_BO_spline_profiles_comparison

clc;
close all;

root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root, 'helpers')));

data_dir = fullfile(root, 'generated_data');
if ~isfolder(data_dir)
    error('Missing folder: %s\nRun bayesian_optimization_spline.m first.', data_dir);
end

bo_specs = {
    'GRF',        fullfile(data_dir, 'optimal_spline_GRF.mat'),         [0.85 0.33 0.10] % rust
    'Pmet',       fullfile(data_dir, 'optimal_spline_Pmet.mat'),        [0.00 0.45 0.74] % blue
    'Normalized', fullfile(data_dir, 'optimal_spline_Normalized.mat'),  [0.47 0.67 0.19] % green
    };

%% Linear references from sweep grid (same as load_params / gen_sweep_data)
[K_shoes, thicknesses, ~] = load_params();
linear_cases = {
    'linear: min K, min thickness', K_shoes(1),           thicknesses(1),           [0.6 0.6 0.6]
    'linear: max K, max thickness', K_shoes(end),        thicknesses(end),         [0.35 0.35 0.35]
    };

%% Figure
fig = figure('Name', 'BO splines vs linear soles', 'Color', 'w', ...
    'Position', [100 100 720 520]);
hold on;

% Dashed linear references (behind BO curves)
for k = 1:size(linear_cases, 1)
    label = linear_cases{k, 1};
    Ks = linear_cases{k, 2};
    th = linear_cases{k, 3};
    col = linear_cases{k, 4};
    [f_lin, d_lin] = straight_spline_tables_from_kb(Ks, th);
    plot(d_lin * 1000, f_lin, '--', 'Color', col, 'LineWidth', 1.5, ...
        'DisplayName', label);
end

% BO optimal profiles
for r = 1:size(bo_specs, 1)
    name = bo_specs{r, 1};
    matf = bo_specs{r, 2};
    col = bo_specs{r, 3};
    if ~isfile(matf)
        warning('plot_BO_spline_profiles_comparison:MissingFile', ...
            'Skipping %s — file not found:\n  %s', name, matf);
        continue
    end
    S = load(matf, 'best');
    if ~isfield(S, 'best')
        warning('plot_BO_spline_profiles_comparison:NoBest', ...
            'File has no variable ''best'': %s', matf);
        continue
    end
    [f_bo, d_bo] = generate_lookup(S.best);
    plot(d_bo * 1000, f_bo, '-', 'Color', col, 'LineWidth', 2.2, ...
        'DisplayName', ['BO: ' name]);
end

hold off;
grid on;
xlabel('Sole compression (mm)');
ylabel('Force (N)');
title('Force–displacement: BO splines vs linear reference soles');
legend('Location', 'northwest');
set(gca, 'FontSize', 11);

%% Optional export
export_png = true;
if export_png
    out_dir = fullfile(root, 'generated_data', 'figures');
    if ~isfolder(out_dir), mkdir(out_dir); end
    out_png = fullfile(out_dir, 'BO_splines_vs_linear_force_displacement.png');
    try
        exportgraphics(fig, out_png, 'Resolution', 200);
        fprintf('Wrote %s\n', out_png);
    catch ME
        warning('Export failed (%s). Save the figure manually.', ME.message);
    end
end
