%% Script that runs Bayesian Optimization. 
% Currently jump height is not fixed

clc; close all; clear

model_name = 'FullHopper_alt';
model_filename = strcat('./models/',model_name,'.slx');

% the model must be loaded before running sim
w = warning('off','all');
load_system(model_filename);

% do this outside the model. 
% if the model structure changes, FastRestart will not work
set_param(model_name, ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'on');

%% Declare variables to obtimize and objective functions

[K_shoes, thicknesses, des_dp_Mass] = load_params();
K_shoes = optimizableVariable('K_shoe',[K_shoes(1),K_shoes(end)]);
thicknesses = optimizableVariable('thickness', [thicknesses(1), thicknesses(end)]);

% do not pass params through global variable; does not work with parallel
results = bayesopt(@(params)eval_GRF(model_name, params),...
    [K_shoes, thicknesses],...
    'IsObjectiveDeterministic',true,...
    'UseParallel',true);


%%
set_param(model_name, 'FastRestart', 'off');
close_system(model_name,0);   


%% BO objective wrapper functions
% we can weight each term to find a compromise
function max_GRF = eval_GRF(model_name, params)
    [max_GRF, ~, ~, ~] = ...
        eval_all_objectives(model_name, ...
                            params.K_shoe, params.thickness, ...
                            1.0); % amplitude is set to be 1
end





