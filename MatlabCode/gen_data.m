%% Script that sweeps through parameters using parsim
% T_stim is precribed and will not adjust to obtain same jump height
% saves full time series data

clc; close all; clear

folder_dir = "./generated_data/";
mkdir(folder_dir)
addpath(genpath('./helpers'))

%% record baseline value
model_name = 'models/FullHopper_baseline';
% model_filename = strcat('./',model_name,'.slx');
w = warning('off','all');
load_system(model_name);

simout = sim(model_name);    

% save time series
save(strcat(folder_dir,"baseline.mat"), "simout")

close_system(model_name,0);          
warning(w)

%% params sweep

K_shoes = 20000:2500:70000;
thicknesses = 0.01:0.0025:0.035; % not very interesting
T_stim = 0.4; % default value for now.

%% actual simulation, preparation

model_name = 'models/FullHopper_alt';
model_filename = strcat('./',model_name,'.slx');
w = warning('off','all');
load_system(model_name);
set_param(model_name, ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'on');

%% regular non-parallel simulation loop, have not tested
% tic

% for thickness = thicknesses % more like max compression
%     disp(strcat("thickness=", num2str(thickness)))
    
%     for K_shoe = K_shoes
        
%         [simIn,~] = assemble_sim_inputs(model_name, ...
%         K_shoe, thickness, T_stim); 
        
%         filename = strcat(folder_dir,...
%             'k_',num2str(K_shoe),'_maxcomp_',num2str(thickness),'.mat');

%         simout = sim(simIn);     
%         save(filename, "simout")

%     end
% end

% toc

%% parallel simulation
tic

[simIn, param_combinations] = assemble_sim_inputs( ...
                               model_name, K_shoes, thicknesses, T_stim);
simouts = parsim(simIn);

toc

%% data saving for parallel simulation
% identify the corresponding parameters through param_combinations

n_sims = length(simIn);

for sim_idx = 1:n_sims % [K_shoe, thickness, T_stim]
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

