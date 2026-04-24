clc; close all; clear

model_name = 'FullHopper_alt';

% the model must be loaded before running sim
w = warning('off','all');
load_system(model_name);

% do this outside the model. 
% if the model structure changes, FastRestart will not work
set_param(model_name, ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'on');

%%
K_shoes = optimizableVariable('K_shoe',[20000,70000]);
thicknesses = optimizableVariable('thickness', [0.01, 0.035]);

% do not pass params through global variable; does not work with parallel
results = bayesopt(@(params)eval_GRF(model_name, params),...
    [K_shoes, thicknesses],...
    'IsObjectiveDeterministic',true,...
    'UseParallel',true);


%%
set_param(model_name, 'FastRestart', 'off');
close_system(model_name,0);   


%% BO objective wrapper functions
% using global filename as function input is 
% probably only the optimizable variable 
% we can weight each term to find a compromise

function max_GRF = eval_GRF(model_name, params)
[max_GRF, ~, ~] = ...
    eval_all_objectives(model_name, params);

end





