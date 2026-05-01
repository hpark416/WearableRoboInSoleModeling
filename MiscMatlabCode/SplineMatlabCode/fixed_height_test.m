%% Sweeps through the parameters, while keeping the jump height around 0.035
clc; close all; clear

%%
folder_dir = "./generated_data/";
mkdir(folder_dir)
addpath(genpath('./helpers'))
addpath(genpath('./models'))

%% load model
model_name = 'FullHopper_alt';
model_filename = strcat('./models/',model_name,'.slx');

w = warning('off','all');
load_system(model_filename);
set_param(model_name, ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'on');

%% load parameters
[K_shoes, thicknesses, des_dp_Mass] = load_params();
amplitude_range = [0.9, 1];

%% Load optimal spline parameters from optimizer
d = load('./generated_data/optimal_spline.mat');
best = d.best;
[force_table, disp_table] = generate_lookup(best.x2, best.F2, best.x3, best.F3);

%% An example
K_shoe = 30000;
thickness = 0.02;

tic
[max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
    eval_all_objectives(model_name, ...
    K_shoe, thickness, ...
    amplitude_range, force_table, disp_table, des_dp_Mass);
toc

disp(max_GRF)
disp(mean_Pmet)
disp(max_dpMass)

%% sweep parameters in parfor
n_combinations = length(K_shoes) * length(thicknesses);
param_combinations = zeros(n_combinations, 2);
count = 1;
for K_shoe = K_shoes
    for thickness = thicknesses
        param_combinations(count,:) = [K_shoe, thickness];
        count = count + 1;
    end
end
out = zeros(n_combinations, 4);

%% Actual parfor loop
tic
parfor_progress(n_combinations)

parfor idx = 1:n_combinations
    params = param_combinations(idx,:);
    [max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
        eval_all_objectives(model_name, ...
                            params(1), ...
                            params(2), ...
                            amplitude_range, force_table, disp_table, des_dp_Mass);
    result = [max_GRF, max_dpMass, mean_Pmet, amplitude_res];
    out(idx,:) = result;
    parfor_progress
end
parfor_progress(0);
toc

%% save
filename = strcat(folder_dir,...
            'height_',num2str(des_dp_Mass),...
            '_objectives',...
            '.mat');
save(filename, "out", "param_combinations")

%% close system
set_param(model_name, 'FastRestart', 'off');
close_system(model_name,0);