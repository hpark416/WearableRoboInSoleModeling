model = 'Copy_of_FullHopper_alt';

mdlWks = get_param(model,'ModelWorkspace');

mdlWks.assignin('k_shoe',20000);
mdlWks.assignin('b_shoe',500);
mdlWks.assignin('thickness',0.03);
mdlWks.assignin('Mass',35);
mdlWks.assignin('gravity',9.81);

% Make sure these match your integrator ICs in the model:
% dp_Mass IC = 0.1
% dv_Mass IC = 0
% dp_sole IC = 0
% dp_sub IC = 0.1

out = sim(model,'StopTime','2');

figure;
plot(out.dp_Mass.Time,out.dp_Mass.Data,'LineWidth',1.5); hold on;
plot(out.dp_sole.Time,out.dp_sole.Data,'LineWidth',1.5);
plot(out.dp_sub.Time,out.dp_sub.Data,'LineWidth',1.5);
legend('dp\_Mass','dp\_sole','dp\_sub');
xlabel('Time (s)');
ylabel('Displacement (m)');
title('Displacement Check for Damped Shoe');
grid on;

figure;
plot(out.GRF.Time,out.GRF.Data,'LineWidth',1.5);
xlabel('Time (s)');
ylabel('GRF (N)');
title('Ground Reaction Force');
grid on;