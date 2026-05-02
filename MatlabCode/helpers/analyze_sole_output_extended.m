%% Extended metrics from simulation output (kinematic / force-rate proxies)
% Use alongside analyze_sole_output for fixed-height correlation studies.
%
% Kin proxies (no extra model logging required):
%   max_abs_ddpdt  - max |d(dp_Mass)/dt| over last 3 hop cycles
%   max_abs_dGRFdt - max |d(GRF)/dt| over last 3 hop cycles
%
% Optional muscle_signal_name: if simOut contains a logged signal with that
% name (e.g. simOut.my_velocity), reports mean absolute value in the last
% full cycle (cycle_idx = 0). Otherwise muscle_mean_abs is NaN.
function [max_GRF, max_dpMass, mean_Pmet, kin] = ...
    analyze_sole_output_extended(simout, muscle_signal_name)

if nargin < 2 || isempty(muscle_signal_name)
    muscle_signal_name = '';
end

T_stim = 0.4;
[max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(simout);

[max_abs_ddpdt, max_abs_dGRFdt] = ...
    sole_kin_proxies_from_cycles(simout, T_stim);

muscle_mean_abs = NaN;
if ~isempty(strtrim(char(string(muscle_signal_name))))
    muscle_mean_abs = mean_abs_signal_last_cycle(simout, ...
        char(muscle_signal_name), T_stim);
end

kin = struct( ...
    'max_abs_ddpdt', max_abs_ddpdt, ...
    'max_abs_dGRFdt', max_abs_dGRFdt, ...
    'muscle_mean_abs', muscle_mean_abs, ...
    'muscle_signal_name', char(muscle_signal_name));

end


function [max_abs_ddpdt, max_abs_dGRFdt] = sole_kin_proxies_from_cycles(simout, T_stim)

max_abs_ddpdt = 0;
max_abs_dGRFdt = 0;

for cycle_idx = 0:2
    [t_dp, dp] = extract_cycle_ts(simout.dp_Mass, T_stim, cycle_idx);
    [t_g, g] = extract_cycle_ts(simout.GRF, T_stim, cycle_idx);

    if numel(t_dp) > 2
        ddpdt = gradient(dp(:), t_dp(:));
        max_abs_ddpdt = max(max_abs_ddpdt, max(abs(ddpdt)));
    end
    if numel(t_g) > 2
        dgdt = gradient(g(:), t_g(:));
        max_abs_dGRFdt = max(max_abs_dGRFdt, max(abs(dgdt)));
    end
end

end


function mu = mean_abs_signal_last_cycle(simout, name, T_stim)

mu = NaN;
sig = get_simout_signal(simout, name);
if isempty(sig)
    return
end

try
    [~, x_trim] = extract_cycle_ts(sig, T_stim, 0);
    mu = mean(abs(x_trim(:)));
catch
    mu = NaN;
end

end


function sig = get_simout_signal(simout, name)

sig = [];
try
    if isstruct(simout) && isfield(simout, name)
        sig = simout.(name);
    elseif isa(simout, 'Simulink.SimulationOutput')
        wh = simout.who;
        if iscell(wh)
            hit = any(strcmp(wh, name));
        else
            hit = any(strcmp(string(wh), string(name)));
        end
        if hit
            sig = simout.get(name);
        end
    end
catch
    sig = [];
end

end


function [t_trim, x_trim] = extract_cycle_ts(signal, T_stim, cycle_idx)

[t, x] = get_time_and_data(signal);
sim_time = t(end);
n_cycles = floor(sim_time / T_stim);
t_end = T_stim * (n_cycles - cycle_idx);
t_start = t_end - T_stim;
idx = t >= t_start & t <= t_end;
t_trim = t(idx);
x_trim = x(idx);

end


function [t, sig] = get_time_and_data(signal)

if isa(signal, 'timeseries')
    t = signal.Time;
    sig = signal.Data;
elseif isstruct(signal) && isfield(signal, 'time') && isfield(signal, 'signals')
    t = signal.time;
    sig = signal.signals.values;
elseif isstruct(signal) && isfield(signal, 'Time') && isfield(signal, 'Data')
    t = signal.Time;
    sig = signal.Data;
elseif isnumeric(signal)
    if size(signal, 2) == 2
        t = signal(:, 1);
        sig = signal(:, 2);
    else
        error(['Signal is numeric but does not contain time. ', ...
               'Use Save format = Timeseries or Structure with time.']);
    end
else
    error('Unsupported signal format.');
end

t = t(:);
sig = sig(:);

end
