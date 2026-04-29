%% generated figures for data generated from gen_data.m
% jump height is not fixed.

clc;close all; clear
%%
% change this
% model_name = 'FullHopper_k';
model_name = 'FullHopper_kb'; 

folder_dir = "./generated_data/";
model_experiment_folder_dir = strcat(folder_dir,"/",model_name,"/");
image_folder_dir = strcat(folder_dir,"figures/");
mkdir(image_folder_dir)

%% get baseline value
d = load(strcat(folder_dir,"baseline.mat"));
[max_GRF_baseline, max_dpMass_baseline, mean_Pmet_baseline] = analyze_sole_output(d.simout);


%% generate Heatmap data
[K_shoes, thicknesses, ~] =  load_params();

max_GRFs = zeros(length(K_shoes),length(thicknesses));
max_dpMasses = zeros(length(K_shoes),length(thicknesses));
mean_Pmets = zeros(length(K_shoes),length(thicknesses));
    
for K_shoe_idx = 1:length(K_shoes)
    K_shoe = K_shoes(K_shoe_idx);

    for thickness_idx = 1:length(thicknesses)
        thickness = thicknesses(thickness_idx);
            
        filename = strcat(model_experiment_folder_dir,...
            'k_',num2str(K_shoe),'_maxcomp_',num2str(thickness),'.mat');
       
        if exist(filename, 'file') == 2         % Checking if file exists      
            d = load(filename);                 % Loads data from file

            [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(d.simout);
            max_GRFs(K_shoe_idx, thickness_idx) = max_GRF;
            max_dpMasses(K_shoe_idx, thickness_idx) = max_dpMass;
            mean_Pmets(K_shoe_idx, thickness_idx) = mean_Pmet;
        end
        
    end
end

[X,Y] = meshgrid(K_shoes,thicknesses);

%% Plot GRF, TODO handle different model names better
titlename = strcat("max GRF, baseline = ", ...
            num2str(max_GRF_baseline), "N");
                
fig = init_contourf(titlename);
contourf(X,Y,max_GRFs')

saveas(fig,strcat(image_folder_dir,model_name, "_GRF_colormap.png"))

%% Plot Pmet
titlename = strcat("$\bar P_{met}$, baseline = ", ...
                    num2str(mean_Pmet_baseline));
fig = init_contourf(titlename);
contourf(X,Y,mean_Pmets')

saveas(fig,strcat(image_folder_dir,model_name,"_mean_Pmet_colormap.png"))

%% Plot dp_Mass
titlename = strcat("max $dp_{Mass}$, baseline = ", ...
                    num2str(max_dpMass_baseline), "m");
fig = init_contourf(titlename);
contourf(X,Y,max_dpMasses')

saveas(fig,strcat(image_folder_dir,model_name,"_dpMass_colormap.png"))

