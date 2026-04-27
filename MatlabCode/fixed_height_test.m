clc; close all; clear

%%
folder_dir = "./generated_data/";
mkdir(folder_dir)
addpath(genpath('./helpers'))

%%
model_name = 'models/FullHopper_alt';
w = warning('off','all');
load_system(model_name);
set_param(model_name, ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'off');
% FastRestart might cause problems when changing T_stims
% because the pulse block might not update.

% following does not work in parfor. Model is changed instead.
% w = warning('off','all');
% set_param(model_name, ...
%     'UnconnectedInputMsg','none', ...
%     'UnconnectedOutputMsg','none'); % surpress in parfor

%%
% minimum dp_Mass is 0.0186
% use 0.02 for now, as search error thresh is 0.005
des_dp_Mass = 0.02;

K_shoes = 20000:2500:70000;
thicknesses = 0.01:0.0025:0.035; % not very interesting

freq_stims = 2.2:0.1:3.2;
T_stims = 1./freq_stims - mod(1./freq_stims, 0.01);

T_stim_range = [min(T_stims), max(T_stims)];


%% An example
% change the following to see effects
% K_shoe = 60000;
% thickness = 0.03;
% 
% tic
% [max_GRF, max_dpMass, mean_Pmet, T_stim_res] = ...
%     eval_all_objectives(model_name, ...
%     K_shoe, ...
%     thickness, ...
%     T_stim_range, des_dp_Mass);
% toc
% 
% disp(max_GRF)
% disp(mean_Pmet)
% disp(max_dpMass)

% %% sanity check
% [max_GRF_1, max_dpMass_1, mean_Pmet_1, T_stim_res_1] = ...
%     eval_all_objectives(model_name, K_shoe, thickness, T_stim_res);


%% sweep in parfor
% since I am unsure how to properly write results to files in parfor,
% I will only keep the objectives.
% takes 8 minutes to run on my machine

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

%%
tic
% run actual loop, nesting is not allowed
parfor_progress(n_combinations)
parfor idx = 1:n_combinations
    params = param_combinations(idx,:);
    [max_GRF, max_dpMass, mean_Pmet, T_stim_res] = ...
        eval_all_objectives(model_name, ...
                            params(1), ...
                            params(2), ...
                            T_stim_range, des_dp_Mass);
    result = [max_GRF, max_dpMass, mean_Pmet, T_stim_res]; 
    out(idx,:) = result; % index only once
    parfor_progress
end
parfor_progress(0);
toc


%% save the objectives only as .mat file

filename = strcat(folder_dir,...
            'height_',num2str(des_dp_Mass),...
            '_objectives',...
            '.mat');

save(filename, "out", "param_combinations")


%%
set_param(model_name, 'FastRestart', 'off');
close_system(model_name,0);          
