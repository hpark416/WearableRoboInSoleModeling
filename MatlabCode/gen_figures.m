clc;close all; clear
folder_dir = "./generated_data/";
image_folder_dir = strcat(folder_dir,"figures/");
mkdir(image_folder_dir)

%% baseline

d = load(strcat(folder_dir,"baseline.mat"));
[max_GRF_baseline, max_dpMass_baseline, mean_Pmet_baseline] = analyze_sole_output(d.simout);


%% Heatmap
K_shoes = 20000:2500:70000;
thicknesses = 0.01:0.0025:0.035; % not very interesting

max_GRFs = zeros(length(K_shoes),length(thicknesses));
max_dpMasses = zeros(length(K_shoes),length(thicknesses));
mean_Pmets = zeros(length(K_shoes),length(thicknesses));
    
for K_shoe_idx = 1:length(K_shoes)
    K_shoe = K_shoes(K_shoe_idx);

    for thickness_idx = 1:length(thicknesses)
        thickness = thicknesses(thickness_idx);
            
        filename = strcat(folder_dir,...
            'k_',num2str(K_shoe),'_maxcomp_',num2str(thickness),'.mat');
       
        if exist(filename) == 2          % Checking if file exists      
            d = load(filename);          % Loads data from file

            [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(d.simout);
            max_GRFs(K_shoe_idx, thickness_idx) = max_GRF;
            max_dpMasses(K_shoe_idx, thickness_idx) = max_dpMass;
            mean_Pmets(K_shoe_idx, thickness_idx) = mean_Pmet;
        end
        
    end
end

%%

[X,Y] = meshgrid(K_shoes,thicknesses); % true frequency

fig = figure("Units","inches", "Position",[1,1,6,5]);hold on;
ax = gca;
ax.FontSize = 12;
ax.FontName = "Times New Roman"; 

contourf(X,Y,max_GRFs')
title(strcat("max GRF, baseline = ", num2str(max_GRF_baseline), "N"),...
    'Interpreter', 'latex',"FontSize",15)
xlabel("K_{shoe}(N/m)")
ylabel("max compression (m)")


colorbar

saveas(fig,strcat(image_folder_dir,"GRF_colormap.png"))


%%

fig = figure("Units","inches", "Position",[1,1,6,5]);hold on;
ax = gca;
ax.FontSize = 12;
ax.FontName = "Times New Roman"; 

contourf(X,Y,mean_Pmets')
title(strcat("$\bar P_{met}$, baseline = ", num2str(mean_Pmet_baseline)),...
    'Interpreter', 'latex',"FontSize",15)
xlabel("K_{shoe}(N/m)")
ylabel("max compression (m)")


colorbar

saveas(fig,strcat(image_folder_dir,"mean_Pmet_colormap.png"))

%%
fig = figure("Units","inches", "Position",[1,1,6,5]);hold on;
ax = gca;
ax.FontSize = 12;
ax.FontName = "Times New Roman"; 

contourf(X,Y,max_dpMasses')
title(strcat("max $dp_{Mass}$, baseline = ", num2str(max_dpMass_baseline), "m"),...
    'Interpreter', 'latex',"FontSize",15)
xlabel("K_{shoe}(N/m)")
ylabel("max compression (m)")


colorbar

saveas(fig,strcat(image_folder_dir,"dpMass_colormap.png"))


%%
function [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(simout)

max_GRFs = [];
max_dpMasses = [];
for cycle_idx = 0:2
    GRF_trimmed = extract_cycle_from_end(simout.GRF, 0.4, cycle_idx);
    dpMass_trimmed = extract_cycle_from_end(simout.dp_Mass, 0.4, cycle_idx);

    max_GRFs = [max_GRFs, max(GRF_trimmed)];
    max_dpMasses = [max_dpMasses, max(dpMass_trimmed)];
end

max_GRF = mean(max_GRFs);
max_dpMass = mean(max_dpMasses);

% metabolic rate, already integrated in sim so we just pick 2 points
Int_mean_Pmet_start = extract_cycle_from_end(simout.int_mean_Pmet, 0.4, 2);
Int_mean_Pmet_end = extract_cycle_from_end(simout.int_mean_Pmet, 0.4, 0);

mean_Pmet = Int_mean_Pmet_end(end) - Int_mean_Pmet_start(1);

end


% extract the last cycle for now and calculate the peak dp_Mass and GRF
function [sig_trimmed, t_start, t_end] = extract_cycle_from_end(timeseries, ...
                                            T_stim, cycle_idx)
% extracts the (n-cycle_idx)th cycle. To avoid writing a function to find
% several peaks.

sig = timeseries.Data;
t = timeseries.Time;
sim_time = t(end);
% extract the final 4 full cycles 
% determine time
n_cycles = floor(sim_time/T_stim);
t_end = T_stim*(n_cycles - cycle_idx);

t_start = t_end - 1*T_stim;
% extract segment
t0 = t>= t_start & t <= t_end;

% t_indices = find(t0);
% t_start_idx = t_indices(1);
% t_end_idx = t_indices(end);

sig_trimmed = sig(t0);

end
