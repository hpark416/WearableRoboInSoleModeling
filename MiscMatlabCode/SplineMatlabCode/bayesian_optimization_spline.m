%% Script that runs Bayesian Optimization with spline
clc; close all; clear

addpath('./helpers')

model_name = 'FullHopper_alt';
model_filename = strcat('./models/',model_name,'.slx');

w = warning('off','all');
load_system(model_filename);

set_param(model_name, ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'on');

%% Declare variables to optimize
[~, thicknesses, ~] = load_params();

thicknesses = optimizableVariable('thickness', [thicknesses(1), thicknesses(end)]);
x2_var = optimizableVariable('x2', [0.004, 0.010]);
F2_var = optimizableVariable('F2', [100,   1000]);
x3_var = optimizableVariable('x3', [0.011, 0.020]);
F3_var = optimizableVariable('F3', [1500,  2200]);

results = bayesopt(@(params)eval_GRF(model_name, params),...
    [thicknesses, x2_var, F2_var, x3_var, F3_var],...
    'IsObjectiveDeterministic', true,...
    'UseParallel', false,...
    'MaxObjectiveEvaluations', 30);

%% Save optimal parameters for use in other scripts
best = results.XAtMinObjective;
mkdir('./generated_data')
save('./generated_data/optimal_spline.mat', 'best');
disp('Optimal spline parameters saved to generated_data/optimal_spline.mat')

%%
set_param(model_name, 'FastRestart', 'off');
close_system(model_name, 0);

%% Objective function
function max_GRF = eval_GRF(model_name, params)

    % Enforce constraints
    if params.F3 < params.F2 + 500
        max_GRF = 9999;
        return
    end
    if params.x2 >= params.x3
        max_GRF = 9999;
        return
    end

    [force_table, disp_table] = generate_lookup(params.x2, params.F2, ...
                                                 params.x3, params.F3);
    [max_GRF, ~, ~, ~] = ...
        eval_all_objectives(model_name, ...
                            1, params.thickness, ...
                            1.0, force_table, disp_table);
end