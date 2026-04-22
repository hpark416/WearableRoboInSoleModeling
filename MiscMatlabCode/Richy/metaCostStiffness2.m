%% Metabolic proxy vs shoe stiffness using cycle averaging
% Cost per cycle = integral of positive MTU power over one hop cycle
% MTU power proxy = F_mt * dL_MT_rate
% Cycle boundaries detected from GRF threshold crossing

clear; clc;

model = 'FullHopper';
set_param(model,'AlgebraicLoopSolver','LineSearch');

k_values = [5000 10000 20000 50000 100000 200000 500000];
thickness_val = 0.03;

% Simulation length: make long enough to capture many cycles
stop_time = 10;   % seconds

% GRF threshold for detecting stance start
grf_thresh = 50; % N

% Number of final cycles to average
n_cycles_to_average = 5;

mean_cost = nan(size(k_values));
std_cost  = nan(size(k_values));
peak_GRF_mean = nan(size(k_values));
n_cycles_used = zeros(size(k_values));

for i = 1:length(k_values)

    mdlWks = get_param(model, 'ModelWorkspace');
    mdlWks.assignin('k_shoe', k_values(i));
    mdlWks.assignin('thickness', thickness_val);

    out = sim(model, 'StopTime', num2str(stop_time));

    % Read timeseries
    t = out.F_mt_out.Time(:);
    F = out.F_mt_out.Data(:);
    v_mtu = out.dL_MT_rate_out.Data(:);
    GRF = out.GRF_out.Data(:);

    % MTU power proxy
    P = F .* v_mtu;

    % If sign convention looks backwards in your model, use:
    % P = -F .* v_mtu;

    % Positive-only power
    Ppos = max(P,0);

    stance = out.stance_out.Data(:) > 0.5;
    stance_start_idx = find(diff(stance) == 1) + 1;

    % Need at least 2 starts to define 1 cycle
    if length(stance_start_idx) < 2
        warning('k = %g: not enough cycles detected.', k_values(i));
        continue;
    end

    % Build cycle costs from stance start to next stance start
    cycle_costs = [];
    cycle_peak_grf = [];

    for c = 1:length(stance_start_idx)-1
        i1 = stance_start_idx(c);
        i2 = stance_start_idx(c+1);

        tc = t(i1:i2);
        Pc = Ppos(i1:i2);
        GRFc = GRF(i1:i2);

        cycle_costs(end+1,1) = trapz(tc, Pc); %#ok<SAGROW>
        cycle_peak_grf(end+1,1) = max(GRFc); %#ok<SAGROW>
    end

    % Use final steady cycles
    n_available = length(cycle_costs);
    n_use = min(n_cycles_to_average, n_available);

    cycle_costs_use = cycle_costs(end-n_use+1:end);
    cycle_peak_use  = cycle_peak_grf(end-n_use+1:end);

    mean_cost(i) = mean(cycle_costs_use);
    std_cost(i) = std(cycle_costs_use);
    peak_GRF_mean(i) = mean(cycle_peak_use);
    n_cycles_used(i) = n_use;

    fprintf('k = %8g N/m | mean cost = %8.3f J | std = %6.3f | mean peak GRF = %8.2f N | cycles used = %d\n', ...
        k_values(i), mean_cost(i), std_cost(i), peak_GRF_mean(i), n_use);
end

%% Identify optimum stiffness
[best_cost, idx_best] = min(mean_cost);
best_k = k_values(idx_best);

fprintf('\nOptimal stiffness in tested range:\n');
fprintf('k_shoe = %g N/m\n', best_k);
fprintf('Mean cycle cost = %.3f J\n', best_cost);

%% Plot mean cost with error bars
figure;
errorbar(k_values, mean_cost, std_cost, '-o', 'LineWidth', 1.5);
xlabel('Shoe stiffness, k_{shoe} (N/m)');
ylabel('Mean positive MTU work per cycle (J)');
title('Metabolic Proxy vs Shoe Stiffness (Averaged Over Final Cycles)');
grid on;

%% Plot mean peak GRF
figure;
plot(k_values, peak_GRF_mean, '-o', 'LineWidth', 1.5);
xlabel('Shoe stiffness, k_{shoe} (N/m)');
ylabel('Mean peak GRF per cycle (N)');
title('Peak GRF vs Shoe Stiffness (Cycle Averaged)');
grid on;

%% Print summary table
T = table(k_values(:), mean_cost(:), std_cost(:), peak_GRF_mean(:), n_cycles_used(:), ...
    'VariableNames', {'k_shoe_N_per_m','MeanCycleCost_J','StdCycleCost_J','MeanPeakGRF_N','CyclesUsed'});
disp(T);