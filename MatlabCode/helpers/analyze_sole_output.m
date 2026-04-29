%% calculates objectives from simulation output
% extracts the last 3 cycles to analyze
function [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(simout)

% Use T_stim from simout if available, otherwise default to 0.4
T_stim = 0.4;

max_GRFs = [];
max_dpMasses = [];

for cycle_idx = 0:2
    GRF_trimmed = extract_cycle_from_end(simout.GRF, T_stim, cycle_idx);
    dpMass_trimmed = extract_cycle_from_end(simout.dp_Mass, T_stim, cycle_idx);

    max_GRFs = [max_GRFs, max(GRF_trimmed)];
    max_dpMasses = [max_dpMasses, max(dpMass_trimmed)];
end

max_GRF = mean(max_GRFs);
max_dpMass = mean(max_dpMasses);

% metabolic rate, already integrated in sim so we just pick two points
Int_mean_Pmet_start = extract_cycle_from_end(simout.int_mean_Pmet, T_stim, 2);
Int_mean_Pmet_end = extract_cycle_from_end(simout.int_mean_Pmet, T_stim, 0);

mean_Pmet = Int_mean_Pmet_end(end) - Int_mean_Pmet_start(1);

end


%% Extract one cycle from the end of a signal
function [sig_trimmed, t_start, t_end] = extract_cycle_from_end(signal, T_stim, cycle_idx)

    [t, sig] = get_time_and_data(signal);

    sim_time = t(end);

    % determine cycle window
    n_cycles = floor(sim_time / T_stim);
    t_end = T_stim * (n_cycles - cycle_idx);
    t_start = t_end - T_stim;

    % extract segment
    idx = t >= t_start & t <= t_end;
    sig_trimmed = sig(idx);

end


%% Convert different Simulink output formats into t and data vectors
function [t, sig] = get_time_and_data(signal)

    % Case 1: normal timeseries object
    if isa(signal, 'timeseries')
        t = signal.Time;
        sig = signal.Data;

    % Case 2: structure with time and signals.values
    elseif isstruct(signal) && isfield(signal, 'time') && isfield(signal, 'signals')
        t = signal.time;
        sig = signal.signals.values;

    % Case 3: structure with Time/Data fields
    elseif isstruct(signal) && isfield(signal, 'Time') && isfield(signal, 'Data')
        t = signal.Time;
        sig = signal.Data;

    % Case 4: numeric array
    elseif isnumeric(signal)

        % If two columns, assume [time, signal]
        if size(signal,2) == 2
            t = signal(:,1);
            sig = signal(:,2);

        % If one column, no time was saved
        else
            error(['Signal is numeric but does not contain time. ', ...
                   'Use Save format = Timeseries or Structure with time.']);
        end

    else
        error('Unsupported signal format.');
    end

    % force column vectors
    t = t(:);
    sig = sig(:);

end