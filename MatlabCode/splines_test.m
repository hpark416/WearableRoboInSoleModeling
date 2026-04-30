%% edited from fixed_height_test.m for sanity check of splines implementation
% when splines define a straight line, it should be the same as
% Fullhopper_kb output

clc; close all; clear

%%
folder_dir = "./generated_data/";
mkdir(folder_dir)

addpath(genpath('./helpers'))
addpath(genpath('./models')) % or parfor cannot access

%% load model
model_name = 'FullHopper_kb_splines'; 

model_filename = strcat('./models/',model_name,'.slx');

model_experiment_folder_dir = strcat(folder_dir,"/",model_name,"/");
mkdir(model_experiment_folder_dir)

w = warning('off','all');
load_system(model_filename);
set_param(model_name, ...
    'SimulationMode', 'accelerator', ...
    'FastRestart', 'off');

%% load parameters
[K_shoes, thicknesses, des_dp_Mass] =  load_params();
amplitude_range = [0.8, 1]; % might adjust the lower bound for speed


%% sweep parameters
% set all splines to be straight - should be same output as original kb

% assemble 2D params
n_combinations = length(K_shoes) * length(thicknesses);
count = 1;
for K_shoe = K_shoes
    for thickness = thicknesses
        param.K_shoe = K_shoe;
        param.thickness = thickness;
        param_combinations(count) = param;
        
        spline_params = generate_straight_spline_params(K_shoe, thickness);
        spline_param_combinations(count) = spline_params;
        count = count + 1;
    end
end
out = zeros(n_combinations, 4);

%% Actual parfor loop
tic
parfor_progress(n_combinations)

parfor idx = 1:n_combinations % nesting is not allowed in parfor
% parfor idx = 1:2 % nesting is not allowed in parfor
% for idx = 1:2 % nesting is not allowed in parfor
    params = spline_param_combinations(idx);
%     [max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
%         eval_all_objectives(model_name, ...
%                             params, ...
%                             amplitude_range, des_dp_Mass);

    [max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
        eval_all_objectives(model_name, ...
                            params, ...
                            1);

    result = [max_GRF, max_dpMass, mean_Pmet, amplitude_res]; 
    out(idx,:) = result; % index only once
    parfor_progress

end
parfor_progress(0);
toc


%% save the objectives only as .mat file
% keeping the same file name just for validation
filename = strcat(model_experiment_folder_dir,...
            'height_',num2str(des_dp_Mass),...
            '_objectives',...
            '.mat');

save(filename, "out", "param_combinations")


%% close system
set_param(model_name, 'FastRestart', 'off');
close_system(model_name,0);          


%% degenerate case for splines
function spline_params = generate_straight_spline_params(K_shoe, thickness)

    displacement = linspace(0,thickness,4);
    force = linspace(0, K_shoe*thickness, 4);
    params.x2 = displacement(2);
    params.x3 = displacement(3);
    params.x4 = displacement(4);
    params.F2 = force(2);
    params.F3 = force(3);
    params.F4 = force(4);

    [spline_params.force_table, spline_params.disp_table] = ...
                                        generate_lookup(params);
    
end




