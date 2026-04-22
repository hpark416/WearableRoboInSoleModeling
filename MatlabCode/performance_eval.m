% preliminary evaluation of piecewise linear force-displacement sole
% sweeps through stiffness and maximum compression on 1D

clc; close all; clear
%%
% record baseline value
model_name = 'original/FullHopper_baseline';
% model_filename = strcat('./',model_name,'.slx');
w = warning('off','all');
load_system(model_name);

simout = sim(model_name);    

close_system(model_name,0);          
warning(w)


%%
[max_GRF_baseline, max_dpMass_baseline, mean_Pmet_baseline] = analyze_sole_output(simout);


%% change stiffness first
K_shoes = 10000:1000:50000;

model_name = 'FullHopper_alt';
% model_filename = strcat('./',model_name,'.slx');
w = warning('off','all');
load_system(model_name);


max_GRFs = [];
max_dpMasses = [];
mean_Pmets = [];

for K_shoe = K_shoes
    disp(strcat("K_shoe=", num2str(K_shoe)))
    set_param(strcat(model_name,'/LoadDynamics/k_shoe'),'Value',num2str(K_shoe));
    simout = sim(model_name);     
    [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(simout);
    max_GRFs = [max_GRFs,max_GRF];
    max_dpMasses = [max_dpMasses, max_dpMass];
    mean_Pmets = [mean_Pmets, mean_Pmet];
    
end

close_system(model_name,0);          
warning(w)


%% plot

fig = figure("Units","inches", "Position",[1,1,6,4]);hold on;
plot(K_shoes,max_GRFs, "linewidth", 2)
title(strcat("50% pulse width, M = 70, baseline=", num2str(max_GRF_baseline)))
% yline(max_GRF_baseline,  "linewidth", 2)
xlabel("K_{shoe} (N/m)")
ylabel("GRF (N)")
grid on

saveas(fig,"GRF_stiffness.png")


fig = figure("Units","inches", "Position",[1,1,6,4]);hold on;
plot(K_shoes,max_dpMasses, "linewidth", 2)
title(strcat("50% pulse width, M = 70, baseline=", num2str(max_dpMass_baseline)))
% yline(max_dpMass_baseline, "linewidth", 2)
xlabel("K_{shoe} (N/m)")
ylabel("dp_{Mass} (m)")
grid on

saveas(fig,"dpMass_stiffness.png")


%%
fig = figure("Units","inches", "Position",[1,1,6,4]);hold on;
plot(K_shoes,mean_Pmets, "linewidth", 2)
title(strcat("50% pulse width, M = 70, baseline=", num2str(mean_Pmet_baseline)))
% yline(max_dpMass_baseline, "linewidth", 2)
xlabel("K_{shoe} (N/m)")
ylabel("avg P_{met} (m)")
grid on

saveas(fig,"Pmet_stiffness.png")


%% change thickness (maximum compression)

thicknesses = 0.01:0.001:0.05;

model_name = 'FullHopper_alt';
% model_filename = strcat('./',model_name,'.slx');
w = warning('off','all');
load_system(model_name);


max_GRFs = [];
max_dpMasses = [];
mean_Pmets = [];

for thickness = thicknesses
    disp(strcat("thickness=", num2str(thickness)))
    set_param(strcat(model_name,'/LoadDynamics/thickness'),'Value',num2str(thickness));
    simout = sim(model_name);     
    [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(simout);
    max_GRFs = [max_GRFs,max_GRF];
    max_dpMasses = [max_dpMasses, max_dpMass];
    mean_Pmets = [mean_Pmets, mean_Pmet];
    
end

close_system(model_name,0);          
warning(w)


%% plot

fig = figure("Units","inches", "Position",[1,1,6,4]);hold on;
plot(thicknesses,max_GRFs, "linewidth", 2)
title(strcat("50% pulse width, M = 70, baseline=", num2str(max_GRF_baseline)))
xlabel("max compression (m)")
ylabel("GRF (N)")
grid on

saveas(fig,"GRF_thickness.png")


fig = figure("Units","inches", "Position",[1,1,6,4]);hold on;
plot(thicknesses,max_dpMasses, "linewidth", 2)
title(strcat("50% pulse width, M = 70, baseline=", num2str(max_dpMass_baseline)))
xlabel("max compression (m)")
ylabel("dp_{Mass} (m)")
grid on

saveas(fig,"dpMass_thickness.png")

%%
fig = figure("Units","inches", "Position",[1,1,6,4]);hold on;
plot(thicknesses,mean_Pmets, "linewidth", 2)
title(strcat("50% pulse width, M = 70, baseline=", num2str(mean_Pmet_baseline)))
% yline(max_dpMass_baseline, "linewidth", 2)
xlabel("max compression (m)")
ylabel("avg P_{met} (m)")
grid on

saveas(fig,"Pmet_thickness.png")

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
