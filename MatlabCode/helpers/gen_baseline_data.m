%% wrapper that simulates FullHopper_baseline.
% does not consider sole dynamics
function gen_baseline_data(is_fixed_height)
    % we only need to run this once; do not consider speed.
    folder_dir = "./generated_data/";
    mkdir(folder_dir)

    addpath(genpath('./helpers'))
    addpath(genpath('./models')) % or parfor cannot access


    amplitude_range = [0.5, 1];

    model_name = 'FullHopper_baseline';
    w = warning('off','all');
    load_system(model_name);

    if is_fixed_height
        [~, ~, des_dp_Mass] =  load_params();
        [max_GRF, max_dpMass, mean_Pmet, amplitude] = ...
            eval_all_objectives(model_name, ...
            struct([]), ...
            amplitude_range, des_dp_Mass);
            filename = strcat(folder_dir,'height_',num2str(des_dp_Mass),...
                                        "_", "baseline_objectives.mat");
        save(filename, "max_GRF", "max_dpMass", "mean_Pmet", "amplitude");

    else % directly run simulation.
        simout = sim(model_name);    
        % save time series
        save(strcat(folder_dir,"baseline.mat"), "simout")
    end

    close_system(model_name,0);          
    warning(w)

end