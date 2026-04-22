%% Metabolic proxy vs shoe stiffness
% Proxy based on positive MTU mechanical power:
%   P_MTU = F_mt * dL_MT_rate
%   Cost  = integral of max(P_MTU, 0) over time

model = 'FullHopper';

% Sweep values
k_values = [5000, 10000, 20000, 50000, 100000, 200000, 500000];

% Fixed thickness
thickness_val = 0.03;

% Storage
cost_values = zeros(size(k_values));
peak_GRF = zeros(size(k_values));

% Optional solver setting
set_param(model,'AlgebraicLoopSolver','LineSearch');

for i = 1:length(k_values)

    % Update model workspace parameters
    mdlWks = get_param(model, 'ModelWorkspace');
    mdlWks.assignin('k_shoe', k_values(i));
    mdlWks.assignin('thickness', thickness_val);

    % Run simulation
    out = sim(model, 'StopTime', '2');

    % Read timeseries
    Fmt_ts   = out.F_mt_out;
    dLrate_ts = out.dL_MT_rate_out;
    GRF_ts   = out.GRF_out;

    t = Fmt_ts.Time(:);
    Fmt = Fmt_ts.Data(:);
    dLrate = dLrate_ts.Data(:);
    GRF = GRF_ts.Data(:);

    % Ignore early transient
    idx = t >= 0.5;
    t_use = t(idx);
    F_use = Fmt(idx);
    dLrate_use = dLrate(idx);
    GRF_use = GRF(idx);

    % MTU power
    P_mtu = F_use .* dLrate_use;

    % Positive-only work proxy
    P_pos = max(P_mtu, 0);
    cost_values(i) = trapz(t_use, P_pos);

    % Peak GRF
    peak_GRF(i) = max(GRF_use);
end

%% Plot metabolic proxy vs stiffness
figure;
plot(k_values, cost_values, '-o', 'LineWidth', 1.5);
xlabel('Shoe stiffness, k_{shoe} (N/m)');
ylabel('Positive MTU work proxy (J)');
title('Metabolic Proxy vs Shoe Stiffness');
grid on;

%% Plot peak GRF vs stiffness
figure;
plot(k_values, peak_GRF, '-o', 'LineWidth', 1.5);
xlabel('Shoe stiffness, k_{shoe} (N/m)');
ylabel('Peak GRF (N)');
title('Peak GRF vs Shoe Stiffness');
grid on;

%% Display values
disp(table(k_values(:), cost_values(:), peak_GRF(:), ...
    'VariableNames', {'k_shoe_N_per_m','PositiveWorkProxy_J','PeakGRF_N'}));