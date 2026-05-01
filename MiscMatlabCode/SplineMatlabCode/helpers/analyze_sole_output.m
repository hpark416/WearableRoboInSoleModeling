%% calculates objectives from simulation output
% extracts the last 2 cycles to analyze, with a hard-coded T_stim=0.4
function [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(simout)
% T_stim is hard coded as 0.4 here!
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


%% extract the (n-cycle_idx)th cycle and calculate the peak dp_Mass and GRF
% To avoid writing a function to find several peaks.
function [sig_trimmed, t_start, t_end] = ...
    extract_cycle_from_end(timeseries, T_stim, cycle_idx)

sig = timeseries.Data;
t = timeseries.Time;
sim_time = t(end);
% extract the prescribed cycle 
% determine time
n_cycles = floor(sim_time/T_stim);
t_end = T_stim*(n_cycles - cycle_idx);

t_start = t_end - 1*T_stim;
% extract segment
t0 = t>= t_start & t <= t_end;

sig_trimmed = sig(t0);

end