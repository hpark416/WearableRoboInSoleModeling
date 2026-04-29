%% Sweeps through the parameters, while keeping the jump height around 0.035
clc; close all; clear

%%
folder_dir = "./generated_data/";
mkdir(folder_dir)

addpath(genpath('./helpers'))
addpath(genpath('./models')) % or parfor cannot access

%% load model
% model_name = 'FullHopper_alt';
model_name = 'Copy_of_FullHopper_alt'; 

model_filename = strcat('./models/',model_name,'.slx');

model_experiment_folder_dir = strcat(folder_dir,"/",model_name,"/");
mkdir(model_experiment_folder_dir)

w = warning('off','all');
load_system(model_filename);
set_param(model_name, ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'on');
% FastRestart might cause problems when changing T_stims
% because the pulse block might not update.
% but not when changing amplitude.

% following does not work in parfor. Model is changed instead.
% w = warning('off','all');
% set_param(model_name, ...
%     'UnconnectedInputMsg','none', ...
%     'UnconnectedOutputMsg','none'); % surpress in parfor

%% load parameters
[K_shoes, thicknesses, des_dp_Mass] =  load_params();
amplitude_range = [0.8, 1]; % might adjust the lower bound for speed

%% An example
% change the following to see effects
K_shoe = 30000;
% thickness = 0.025;
thickness = 0.005;

tic
[max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
    eval_all_objectives(model_name, ...
    K_shoe, ...
    thickness, ...
    amplitude_range, des_dp_Mass);
toc

% disp(max_GRF)
% disp(mean_Pmet)
disp(max_dpMass)
disp(amplitude_res)

% % sanity check
% [max_GRF_1, max_dpMass_1, mean_Pmet_1, amplitude_res_1] = ...
%     eval_all_objectives(model_name, K_shoe, thickness, amplitude_res);


%% sweep parameters in parfor
% since I am unsure how to properly write results to files in parfor,
% I will only keep the objectives.
% takes 4 minutes to run on my machine

% assemble 2D params
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

parfor idx = 1:n_combinations % nesting is not allowed in parfor
    params = param_combinations(idx,:);
    [max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
        eval_all_objectives(model_name, ...
                            params(1), ...
                            params(2), ...
                            amplitude_range, des_dp_Mass);
    result = [max_GRF, max_dpMass, mean_Pmet, amplitude_res]; 
    out(idx,:) = result; % index only once
    parfor_progress
end
parfor_progress(0);
toc


%% save the objectives only as .mat file

filename = strcat(model_experiment_folder_dir,...
            'height_',num2str(des_dp_Mass),...
            '_objectives',...
            '.mat');

save(filename, "out", "param_combinations")


%% close system
set_param(model_name, 'FastRestart', 'off');
close_system(model_name,0);          
