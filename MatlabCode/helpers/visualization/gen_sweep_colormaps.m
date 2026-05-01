%% directly saves heatmaps to directory
% have to rewrite function if we want to change figures
% this function will read, process data from file and save plots.
% last two parameters denote if the output is saved in full timeseries
% or only the objectives have been saved.
function gen_sweep_colormaps(model_name, folder_dir, ...
    is_fixed_height, is_baseline_full, is_sweep_full)
    [~, ~, des_dp_Mass] =  load_params();

    if is_baseline_full
        d = load(strcat(folder_dir,"baseline.mat"));
        [baselines.max_GRF, baselines.max_dpMass, baselines.mean_Pmet] = ...
                                        analyze_sole_output(d.simout);
    else
        baseline_filename = "baseline_objectives.mat";
        if is_fixed_height
            baseline_filename = strcat('height_',num2str(des_dp_Mass),...
                                            "_", baseline_filename);
        end
        baselines = load(strcat(folder_dir,baseline_filename));
    end

    model_experiment_folder_dir = strcat(folder_dir,"/",model_name,"/");
    
    if is_sweep_full
        [K_shoes_2D, thicknesses_2D, sweep_results] = ...
                    load_sweep_data_full(model_experiment_folder_dir);
    else
        [K_shoes_2D, thicknesses_2D, sweep_results] = ...
        load_sweep_data_objectives(model_experiment_folder_dir, is_fixed_height);
    end

    if is_fixed_height
        title_postfix = strcat(", max $dp_{Mass} \approx$", num2str(...
                                    des_dp_Mass*100), "cm");
        filename_prefix = strcat("_height_", num2str(des_dp_Mass));
    else
        title_postfix = "";
        filename_prefix = "";
    end

    plot_colormaps_from_data(model_name, folder_dir,...
                                K_shoes_2D, thicknesses_2D,...
                                sweep_results, baselines, ...
                                title_postfix, filename_prefix)
end

function [K_shoes_2D, thicknesses_2D, sweep_results] = ...
    load_sweep_data_full(model_experiment_folder_dir)
    [K_shoes, thicknesses, ~] =  load_params();

    max_GRFs = zeros(length(K_shoes),length(thicknesses));
    max_dpMasses = zeros(length(K_shoes),length(thicknesses));
    mean_Pmets = zeros(length(K_shoes),length(thicknesses));
        
    for K_shoe_idx = 1:length(K_shoes)
        K_shoe = K_shoes(K_shoe_idx);

        for thickness_idx = 1:length(thicknesses)
            thickness = thicknesses(thickness_idx);
                
            filename = strcat(model_experiment_folder_dir,...
                'k_',num2str(K_shoe),'_maxcomp_',num2str(thickness),'.mat');
        
            if exist(filename, 'file') == 2         % Checking if file exists      
                d = load(filename);                 % Loads data from file

                [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(d.simout);
                max_GRFs(K_shoe_idx, thickness_idx) = max_GRF;
                max_dpMasses(K_shoe_idx, thickness_idx) = max_dpMass;
                mean_Pmets(K_shoe_idx, thickness_idx) = mean_Pmet;
            end
            
        end
    end

    [K_shoes_2D,thicknesses_2D] = meshgrid(K_shoes,thicknesses);
    sweep_results.max_GRF = max_GRFs';
    sweep_results.max_dpMass = max_dpMasses';
    sweep_results.mean_Pmet = mean_Pmets';
end


function [K_shoes_2D, thicknesses_2D, sweep_results] = ...
    load_sweep_data_objectives(model_experiment_folder_dir, is_fixed_height)

    [K_shoes, thicknesses, des_dp_Mass] =  load_params();
    if is_fixed_height
        filename = strcat(model_experiment_folder_dir,...
                    'height_',num2str(des_dp_Mass),...
                    '_objectives',...
                    '.mat');
    else
        filename = strcat(model_experiment_folder_dir,...
                    '_objectives',...
                    '.mat');
    end
    
    d = load(filename);

    % we need to reassemble out and params into 2d
    new_shape = [length(thicknesses), length(K_shoes)];
    % reshapes column wise
    sweep_results.max_GRF = reshape(d.out(:,1),new_shape);
    sweep_results.max_dpMass = reshape(d.out(:,2),new_shape);
    sweep_results.mean_Pmet = reshape(d.out(:,3),new_shape);
    sweep_results.amplitude = reshape(d.out(:,4),new_shape);

    % unpack from list of structs
    K_shoes_2D = []; % column
    thicknesses_2D = [];
    for i = 1:length(d.param_combinations)
        K_shoes_2D = [K_shoes_2D; d.param_combinations(i).K_shoe];
        thicknesses_2D = [thicknesses_2D; d.param_combinations(i).thickness];
    end

    K_shoes_2D = reshape(K_shoes_2D, new_shape);
    thicknesses_2D = reshape(thicknesses_2D, new_shape);
end


% this function only takes in processed data.
% K_shoes_2D and thicknesses_2D should be similar to results of meshgrid
function plot_colormaps_from_data(model_name, folder_dir,...
    K_shoes_2D, thicknesses_2D,...
    sweep_results, baselines, ...
    title_postfix, filename_prefix)

    image_folder_dir = strcat(folder_dir,"figures/");
    mkdir(image_folder_dir)

    % Plot GRF
    titlename = strcat("max GRF, baseline = ", ...
                        num2str(baselines.max_GRF), "N", title_postfix);
                    
    fig = init_contourf(titlename);
    contourf(K_shoes_2D,thicknesses_2D, sweep_results.max_GRF)

    saveas(fig,strcat(image_folder_dir,model_name,filename_prefix,... 
                        "_GRF_colormap.png"))

    % Plot Pmet
    titlename = strcat("$\bar P_{met}$, baseline = ", ...
                        num2str(baselines.mean_Pmet), title_postfix);
    fig = init_contourf(titlename);
    contourf(K_shoes_2D,thicknesses_2D, sweep_results.mean_Pmet)

    saveas(fig,strcat(image_folder_dir,model_name,filename_prefix,...
                        "_mean_Pmet_colormap.png"))

    % Plot dp_Mass
    titlename = strcat("max $dp_{Mass}$, baseline = ", ...
                        num2str(baselines.max_dpMass), "m", title_postfix);
    fig = init_contourf(titlename);
    contourf(K_shoes_2D,thicknesses_2D, sweep_results.max_dpMass)

    saveas(fig,strcat(image_folder_dir,model_name,filename_prefix,...
                        "_dpMass_colormap.png"))

    % plot amplitude if it exists in sweep_results
   if isfield(sweep_results,"amplitude")  
        titlename = strcat("Amplitude, baseline = ", ...
                        num2str(baselines.amplitude), title_postfix);
        fig = init_contourf(titlename);
        contourf(K_shoes_2D, thicknesses_2D, sweep_results.amplitude)

        saveas(fig,strcat(image_folder_dir, model_name, filename_prefix,...
            "_amplitude_colormap.png"))
   end
end


