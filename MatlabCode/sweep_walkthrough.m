clc; close all; clear
addpath(genpath('./helpers'))
folder_dir = "./generated_data/";

%% generate baselines
gen_baseline_data(false) % height not constrained.
gen_baseline_data(true) % height constrained.

%% sweep tests
%% jump with amplitude = 1
model_name = 'FullHopper_kb'; 
gen_sweep_data(model_name, false, false);

%% plot
gen_sweep_colormaps(model_name, folder_dir, ...
    false, true, true)

%% jump at height = 4cm
model_name = 'FullHopper_kb'; 
gen_sweep_data(model_name, true, false);

%%
gen_sweep_colormaps(model_name, folder_dir, ...
    true, false, false)

%% sanity check for curve/spline model: 
% the following should output the same results as above.
%% test amplitude=1 on curve model
model_name = 'FullHopper_kb_splines'; 
gen_sweep_data(model_name, false, true);

%%
gen_sweep_colormaps(model_name, folder_dir, ...
    false, true, true)

%% height = 4cm on curve model
model_name = 'FullHopper_kb_splines'; 
gen_sweep_data(model_name, true, true);
%%
gen_sweep_colormaps(model_name, folder_dir, ...
    true, false, false)
