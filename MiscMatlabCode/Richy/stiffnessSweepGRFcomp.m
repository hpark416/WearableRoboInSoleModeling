model = 'FullHopper';
set_param(model,'AlgebraicLoopSolver','LineSearch')

k_values = [5000 10000 20000 50000 100000 200000 500000];

figure;
hold on;

for i = 1:length(k_values)

    mdlWks = get_param(model, 'ModelWorkspace');
    mdlWks.assignin('k_shoe', k_values(i));
    mdlWks.assignin('thickness', 0.03);

    out = sim(model, 'StopTime', '2');

    GRF = out.GRF_out;
    t = GRF.Time;
    y = GRF.Data;

    idx = t >= 0.5;
    plot(t(idx), y(idx), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('k = %d N/m', k_values(i)));
end

xlabel('Time (s)');
ylabel('GRF (N)');
title('GRF Comparison Across Shoe Stiffness');
legend('show');
grid on;