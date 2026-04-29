%% Script that sweeps through parameters using parsim
% amplitude is prescribed and will not adjust to obtain same jump height
% saves full time series data

clc; close all; clear

folder_dir = "./generated_data/";
mkdir(folder_dir)
addpath(genpath('./helpers'))

%% record baseline value
model_name = 'models/FullHopper_baseline';
w = warning('off','all');
load_system(model_name);

simout = sim(model_name);    
save(strcat(folder_dir,"baseline.mat"), "simout")

close_system(model_name,0);          
warning(w)

%% params sweep
[K_shoes, thicknesses, ~] = load_params();
amplitude = 1;

%% Load optimal spline parameters from optimizer
d = load('./generated_data/optimal_spline.mat');
best = d.best;
[force_table, disp_table] = generate_lookup(best.x2, best.F2, best.x3, best.F3);

%% actual simulation, preparation
model_name = 'FullHopper_alt';
model_filename = strcat('./models/',model_name,'.slx');
w = warning('off','all');
load_system(model_filename);
set_param(model_name, ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'on');

%% parallel simulation
tic

[simIn, param_combinations] = assemble_sim_inputs( ...
                               model_name, K_shoes, thicknesses, amplitude, ...
                               force_table, disp_table);
simouts = parsim(simIn);

toc

%% data saving for parallel simulation
n_sims = length(simIn);

for sim_idx = 1:n_sims
        filename = strcat(folder_dir,...
            'k_',num2str(param_combinations(sim_idx,1)),...
            '_maxcomp_',num2str(param_combinations(sim_idx,2)),...
            '.mat');
        
        simout = simouts(sim_idx);
        save(filename, "simout")
end

%%
set_param(model_name, 'FastRestart', 'off');
close_system(model_name,0);          
warning(w)