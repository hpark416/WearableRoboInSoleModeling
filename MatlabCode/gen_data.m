%% Script that sweeps through parameters using parsim
% amplitude is precribed and will not adjust to obtain same jump height
% saves full time series data
clc; close all; clear

%%
% change this
% model_name = 'FullHopper_alt'; 
model_name = 'Copy_of_FullHopper_alt'; 


folder_dir = "./generated_data/";
model_experiment_folder_dir = strcat(folder_dir,"/",model_name,"/");
mkdir(folder_dir)
mkdir(model_experiment_folder_dir)
addpath(genpath('./helpers'))

%% record baseline value
baseline_model_name = 'models/FullHopper_baseline';
w = warning('off','all');
load_system(baseline_model_name);

simout = sim(baseline_model_name);    
% save time series
save(strcat(folder_dir,"baseline.mat"), "simout")

close_system(baseline_model_name,0);          
warning(w)

%% params sweep
[K_shoes, thicknesses, ~] =  load_params();
amplitude = 1; % default value for now.

%% actual simulation, preparation


model_filename = strcat('./models/',model_name,'.slx');
w = warning('off','all');
load_system(model_filename);
% should not be the path name
set_param(model_name, ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'off');

%% parallel simulation
tic

[simIn, param_combinations] = assemble_sim_inputs( ...
                               model_name, K_shoes, thicknesses, amplitude);
simouts = parsim(simIn);

toc

%% data saving for parallel simulation
% identify the corresponding parameters through param_combinations

n_sims = length(simIn);

for sim_idx = 1:n_sims % [K_shoe, thickness, amplitude]
        filename = strcat(model_experiment_folder_dir,...
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

