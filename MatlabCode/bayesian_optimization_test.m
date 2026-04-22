clc; close all; clear

% params.K_shoe = 50000;
% params.thickness = 0.01;
global model_name
model_name = 'FullHopper_alt';
% if this does not work, pass as a single optimizableVariable
% or write a function handle passing in this name. see bayesopt docs.

% the model must be loaded before running sim
w = warning('off','all');
load_system(model_name);
%%

% [max_GRF, max_dpMass, mean_Pmet] = ...
%     eval_all_objectives(model_name, params);

% max_GRF = eval_GRF(params);


K_shoes = optimizableVariable('K_shoe',[20000,70000]);
thicknesses = optimizableVariable('thickness', [0.01, 0.035]);


results = bayesopt(@eval_GRF, [K_shoes, thicknesses],...
    'IsObjectiveDeterministic',true)

%%
close_system(model_name,0);   


%% BO objective wrapper functions
% using global filename as function input is 
% probably only the optimizable variable 
% we can weight each term to find a compromise

function max_GRF = eval_GRF(params)
global model_name
[max_GRF, ~, ~] = ...
    eval_all_objectives(model_name, params);

end





