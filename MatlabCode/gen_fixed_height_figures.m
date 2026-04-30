%% generate figures for fixed_height_test.m
clc;close all; clear
folder_dir = "./generated_data/";
image_folder_dir = strcat(folder_dir,"figures/");
mkdir(image_folder_dir)
addpath(genpath('./helpers'))


% change this
% model_name = 'FullHopper_k';
% model_name = 'FullHopper_kb'; 
model_name = 'FullHopper_kb_splines'; 

model_experiment_folder_dir = strcat(folder_dir,"/",model_name,"/");

%% load and process data from file
[K_shoes, thicknesses, des_dp_Mass] =  load_params();

filename = strcat(model_experiment_folder_dir,...
            'height_',num2str(des_dp_Mass),...
            '_objectives',...
            '.mat');
d = load(filename);

% we need to reassemble out and params into 2d
% have to write a new function to generate the 2d parameter matrix

new_shape = [length(thicknesses), length(K_shoes)];
% reshapes column wise
max_GRF_2D = reshape(d.out(:,1),new_shape);
max_dpMass_2D = reshape(d.out(:,2),new_shape);
mean_Pmet_2D = reshape(d.out(:,3),new_shape);
amplitudes_2D = reshape(d.out(:,4),new_shape);

% unpack from list of structs
K_shoes_2D = []; % column
thicknesses_2D = [];
for i = 1:length(d.param_combinations)
    K_shoes_2D = [K_shoes_2D; d.param_combinations(i).K_shoe];
    thicknesses_2D = [thicknesses_2D; d.param_combinations(i).thickness];
end
K_shoes_2D = reshape(K_shoes_2D, new_shape);
thicknesses_2D = reshape(thicknesses_2D, new_shape);

%% amplitude
titlename = strcat("Amplitude, max $dp_{Mass}$ = ", num2str(...
    des_dp_Mass*100), "$\pm$0.05cm");
fig = init_contourf(titlename);
contourf(K_shoes_2D, thicknesses_2D, amplitudes_2D)

saveas(fig,strcat(image_folder_dir, model_name, "_height_", num2str(...
    des_dp_Mass), "_amplitude_colormap.png"))

%% GRF
titlename = strcat("max GRF (N), max $dp_{Mass}$ = ", num2str(...
    des_dp_Mass*100), "$\pm$0.05cm");
fig = init_contourf(titlename);
contourf(K_shoes_2D, thicknesses_2D, max_GRF_2D)

saveas(fig,strcat(image_folder_dir,model_name, "_height_", num2str(...
    des_dp_Mass), "_GRF_colormap.png"))

%% dp_Mass
titlename = strcat("real max $dp_{Mass}$(m), max $dp_{Mass}$ = ", num2str(...
    des_dp_Mass*100), "$\pm$0.05cm");
fig = init_contourf(titlename);
contourf(K_shoes_2D, thicknesses_2D, max_dpMass_2D)

saveas(fig,strcat(image_folder_dir,model_name,"_height_", num2str(...
    des_dp_Mass), "_dpMass_colormap.png"))

%% P_met
titlename = strcat("$\bar P_{met}$, max $dp_{Mass}$ = ", num2str(...
    des_dp_Mass*100), "$\pm$0.05cm");
fig = init_contourf(titlename);
contourf(K_shoes_2D, thicknesses_2D, mean_Pmet_2D)

saveas(fig,strcat(image_folder_dir,model_name,"_height_", num2str(...
    des_dp_Mass), "_Pmet_colormap.png"))



