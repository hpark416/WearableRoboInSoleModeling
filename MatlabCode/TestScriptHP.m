model = 'ComSSModel';
mdlWks = get_param(model,'ModelWorkspace');

mdlWks.assignin('f_hop',2.0);
mdlWks.assignin('T_stim',1/2.0);
disp('For f_hop = 2.0 Hz:')
disp(mdlWks.evalin('T_stim'))

out1 = sim(model,'StopTime','1');

mdlWks.assignin('f_hop',4.0);
mdlWks.assignin('T_stim',1/4.0);
disp('For f_hop = 4.0 Hz:')
disp(mdlWks.evalin('T_stim'))

out2 = sim(model,'StopTime','1');