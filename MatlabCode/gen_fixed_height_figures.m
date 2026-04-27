clc;close all; clear
folder_dir = "./generated_data/";
image_folder_dir = strcat(folder_dir,"figures/");
mkdir(image_folder_dir)

%%
des_dp_Mass = 0.02;
filename = strcat(folder_dir,...
            'height_',num2str(des_dp_Mass),...
            '_objectives',...
            '.mat');
        
d = load(filename);

% we need to reassemble out and params into 2d
% have to write a new function to generate the 2d parameter matrix
K_shoes = 20000:2500:70000;
thicknesses = 0.01:0.0025:0.035; % not very interesting

new_shape = [length(thicknesses), length(K_shoes)];
% reshapes column wise
max_GRF_2D = reshape(d.out(:,1),new_shape);
max_dpMass_2D = reshape(d.out(:,2),new_shape);
mean_Pmet_2D = reshape(d.out(:,3),new_shape);
T_stims_2D = reshape(d.out(:,4),new_shape);


K_shoes_2D = reshape(d.param_combinations(:,1), new_shape);
stiffnesses_2D = reshape(d.param_combinations(:,2), new_shape);



%%
titlename = strcat("$T_{stim} (s)$, max $dp_{Mass}$ = ", num2str(...
    des_dp_Mass), "$\pm$0.005m");
fig = init_contourf(titlename);
contourf(K_shoes_2D, stiffnesses_2D, T_stims_2D)

saveas(fig,strcat(image_folder_dir,"height_", num2str(...
    des_dp_Mass), "_Tstim_colormap.png"))

%%
titlename = strcat("max GRF (N), max $dp_{Mass}$ = ", num2str(...
    des_dp_Mass), "$\pm$0.005m");
fig = init_contourf(titlename);
contourf(K_shoes_2D, stiffnesses_2D, max_GRF_2D)

saveas(fig,strcat(image_folder_dir,"height_", num2str(...
    des_dp_Mass), "_GRF_colormap.png"))

%%
titlename = strcat("real max $dp_{Mass}$(m), max $dp_{Mass}$ = ", num2str(...
    des_dp_Mass), "$\pm$0.005m");
fig = init_contourf(titlename);
contourf(K_shoes_2D, stiffnesses_2D, max_dpMass_2D)

saveas(fig,strcat(image_folder_dir,"height_", num2str(...
    des_dp_Mass), "_dpMass_colormap.png"))

%%
titlename = strcat("$\bar P_{met}$, max $dp_{Mass}$ = ", num2str(...
    des_dp_Mass), "$\pm$0.005m");
fig = init_contourf(titlename);
contourf(K_shoes_2D, stiffnesses_2D, mean_Pmet_2D)

saveas(fig,strcat(image_folder_dir,"height_", num2str(...
    des_dp_Mass), "_Pmet_colormap.png"))



