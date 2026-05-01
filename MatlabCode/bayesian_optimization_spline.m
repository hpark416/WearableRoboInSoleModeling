%% Script that runs Bayesian Optimization with spline
clc; close all; clear

addpath('./helpers')

model_name = 'FullHopper_kb_splines';
model_filename = strcat('./models/',model_name,'.slx');

w = warning('off','all');
load_system(model_filename);

set_param(model_name, ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'off');
    % 'FastRestart', 'on');

%% Declare variables to optimize
[K_shoes, thicknesses, ~] = load_params();
% x_interval = [thicknesses(1), thicknesses(end)];
% F_interval = [thicknesses(1)*K_shoes(1), thicknesses(end)*K_shoes(end)];
max_endpoint = [thicknesses(end), thicknesses(end)*K_shoes(end)];

dx_interval = [0.001, max_endpoint(1)/2];
dF_interval = [100, max_endpoint(2)/2];

K_shoes_interval = [K_shoes(1), K_shoes(end)];

% normally cannot randomly roll out a fitting value.
% optimize "slopes" and "switch time interval" instead.

dx2_var = optimizableVariable('dx2', dx_interval);
dx3_var = optimizableVariable('dx3', dx_interval);
dx4_var = optimizableVariable('dx4', dx_interval);

dF2_var = optimizableVariable('dF2', dF_interval);
dF3_var = optimizableVariable('dF3', dF_interval);
dF4_var = optimizableVariable('dF4', dF_interval);

%% Choose objective here — change this line to switch objectives
% Options: @eval_minimize_GRF, @eval_minimize_Pmet, @eval_normalized_weighted
objective_fn = @eval_minimize_GRF;
objective_name = 'GRF'; % change to 'Pmet' or 'Normalized' to match above
%%
results = bayesopt(@(params)objective_fn(model_name, params),...
    [dx2_var, dF2_var, dx3_var, dF3_var, dx4_var, dF4_var],...
    'IsObjectiveDeterministic', true,...
    'UseParallel', true,...
    'MaxObjectiveEvaluations', 30,...
    'XConstraintFcn',@(params)profile_constraints(...
    params,max_endpoint,K_shoes_interval));


%% Save optimal parameters for use in other scripts
best = to_control_points(results.XAtMinObjective);
mkdir('./generated_data')
filename = strcat('./generated_data/optimal_spline_', objective_name, '.mat');
save(filename, 'best');
disp(strcat('Optimal spline parameters saved to ', filename))

%% Plot optimal spline shape
[force_table, disp_table] = generate_lookup(best);
figure
plot(disp_table * 1000, force_table)
xlabel('Displacement (mm)')
ylabel('Force (N)')
title(strcat('Optimal Spline Shape - ', objective_name))
grid on
%%
set_param(model_name, 'FastRestart', 'off');
close_system(model_name, 0);


%% conversion between two sets of parameters.
function ctrl_points_params = to_control_points(bo_params)
    % monotonic increase already satisfied 
    ctrl_points_params.x2 = bo_params.dx2;
    ctrl_points_params.x3 = ctrl_points_params.x2 + bo_params.dx3;
    ctrl_points_params.x4 = ctrl_points_params.x3 + bo_params.dx4;

    ctrl_points_params.F2 = bo_params.dF2;
    ctrl_points_params.F3 = ctrl_points_params.F2 + bo_params.dF3;
    ctrl_points_params.F4 = ctrl_points_params.F3 + bo_params.dF4;
end


%% Objective function
% [objective, constraints]
function max_GRF = eval_minimize_GRF(model_name, params)
    ctrl_points_params = to_control_points(params);
    [mat_params.force_table, mat_params.disp_table] = ...
                                generate_lookup(ctrl_points_params);
    [max_GRF, ~, ~, ~] = ...
        eval_all_objectives(model_name, mat_params, [0.8, 1.0], 0.04);
end

function mean_Pmet = eval_minimize_Pmet(model_name, params)
    ctrl_points_params = to_control_points(params);
    [mat_params.force_table, mat_params.disp_table] = ...
                                generate_lookup(ctrl_points_params);
    [~, ~, mean_Pmet, ~] = ...
        eval_all_objectives(model_name, mat_params, [0.8, 1.0], 0.04);
end

function objective = eval_normalized_weighted(model_name, params)
    ctrl_points_params = to_control_points(params);
    [mat_params.force_table, mat_params.disp_table] = ...
                                generate_lookup(ctrl_points_params);
    [max_GRF, ~, mean_Pmet, ~] = ...
        eval_all_objectives(model_name, mat_params, [0.8, 1.0], 0.04);

    GRF_baseline  = 1411.0673;
    Pmet_baseline = 158.204;

    objective = (max_GRF / GRF_baseline) + (mean_Pmet / Pmet_baseline);
end

%% Constraints

function satisfied = profile_constraints(params, max_endpoint, K_shoes_interval)


    ctrl_points_params = to_control_points(params);
    % just check if the last point is within range.
    is_endpoint_feasible = ctrl_points_params.x4 <= max_endpoint(1) & ...
                        ctrl_points_params.F4 <= max_endpoint(2);
    % 2. overall stiffness (connection of start and end) have to be within range.
    overall_k = ctrl_points_params.F4 ./ ctrl_points_params.x4;
    is_overall_k_feasible = (overall_k >= K_shoes_interval(1)) &...
                            (overall_k <= K_shoes_interval(2));

    satisfied = is_endpoint_feasible & is_overall_k_feasible;

end
