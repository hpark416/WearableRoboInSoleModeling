% objective function to be passed into bayesian optimization
% should be organized from performance_eval.m
% either declare here or use model in the main function


% the following function is not supposed to be passed directly
% into bayesopt; it should be wrapped in a function defined in
% the main file that contains the global variable model_name
% since true objective will be the weighted combinations of them
function [max_GRF, max_dpMass, mean_Pmet] = ...
    eval_all_objectives(model_name, params)
    % params: 1*D yable of variable values
    % objective: should be one scalar.
    % will evaluate several objectives.  

    % will not save anything.
    % we can run different slices, each varying one parameter, as sanity check
    set_param(strcat(model_name,'/LoadDynamics/k_shoe'),'Value',...
        num2str(params.K_shoe));
    set_param(strcat(model_name,'/LoadDynamics/thickness'),'Value',...
        num2str(params.thickness));

    simout = sim(model_name);     
    [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(simout);
end



%% helpers
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
function [sig_trimmed, t_start, t_end] = ...
    extract_cycle_from_end(timeseries, T_stim, cycle_idx)
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