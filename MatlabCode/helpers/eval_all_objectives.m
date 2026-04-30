%% objective function to be passed into bayesian optimization
% the following function is not supposed to be passed directly
% into bayesopt; it should be wrapped in a function defined in
% the main file that contains the global variable model_name
% since true objective will be the weighted combinations of them
function [max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
    eval_all_objectives(model_name, material_params, amplitude, varargin)
    % amplitude: scalar or 2-element vector. 
    % For the latter, denotes a range.
    
    % the single-scalar objective should be defined by 
    % the wrapper that calls this function.
    
    % will not save time series signals.

    if isscalar(amplitude) % amplitude is a prescribed value
        amplitude_res = amplitude;
        [max_GRF, max_dpMass, mean_Pmet] = ...
            eval_params(model_name, material_params, amplitude);

    else % amplitude is a permissable range
        % assumes that varargin is not empty; throws an error anyway
        des_max_dpMass = varargin{1};
        [amplitude_res, max_GRF, max_dpMass, mean_Pmet] =  search_amplitude(...
            des_max_dpMass, model_name, material_params, amplitude);
    end
end


%% helpers
%% wrapper to simulate and analyze output
function [max_GRF, max_dpMass, mean_Pmet] = ...
    eval_params(model_name, material_params, amplitude)

    [simIn,~] = assemble_sim_inputs(model_name, ...
        material_params, amplitude); 
    simOut = sim(simIn);
    
    [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(simOut);
end

% place binary search for amplitude here instead of in a new function
% since it is probably not called anywhere else
% binary search might not work for parsim, call this in parfor instead

%% Find the simulation that is kept near a jump height
% recursively search for the amplitude that results in COM displacement 
% within a threshold, assumes the relationship is monotonic
% It will eventually return all objectives, 
% as we usually need to run a simulation to obtain amplitude. 
%
% Optional parameters:
% varargin{1}: 
%   2*3 matrix, each row is max_GRF, max_dpMass, mean_Pmet,  
%   each column corresponds to min and max amplitude in range
% varargin{2}:
%   int, number of iterations.
function [amplitude, max_GRF, max_dpMass, mean_Pmet] =  search_amplitude(...
    des_max_dpMass, model_name, material_params, amplitude_range, ...
    varargin)
    % threshold is +-0.0005
    % do not use parallelization as the main function is in parfor

    if isempty(varargin) % initialize
        objectives_range = zeros(2,3);
        % get objectives corresponding to minimum amplitude
        objectives_range(1,:) = ...
            eval_and_pack(model_name, material_params, amplitude_range(1));
        % get objectives corresponding to maximum amplitude
        objectives_range(2,:) = ...
            eval_and_pack(model_name, material_params, amplitude_range(2));

        iters = 1;
    else
        % unpack evaluated values from the outer recursion
        objectives_range = varargin{1};
        iters = varargin{2};
    end

    if iters > 10
        amplitude = mean(amplitude_range); 
        [max_GRF, max_dpMass, mean_Pmet] = ...
            eval_params(model_name, material_params, amplitude_range(2));
        return
    end

    % see if the value lies between; if not; quit
    if (des_max_dpMass < objectives_range(1,2)) % minimum max_dpMass
        amplitude = amplitude_range(1);
        [max_GRF, max_dpMass, mean_Pmet] = unpack(objectives_range(1,:));
        return
    elseif (des_max_dpMass > objectives_range(2,2)) % maximum max_dpMass
        amplitude = amplitude_range(2);
        [max_GRF, max_dpMass, mean_Pmet] = unpack(objectives_range(2,:));
        return
    end

    % evaluate midpoint
    mid_amplitude = mean(amplitude_range);
    mid_objectives = ...
        eval_and_pack(model_name, material_params, mid_amplitude);
    mid_max_dpMass = mid_objectives(2);

    % hard-coded threshold
%     if abs(mid_max_dpMass - des_max_dpMass) < 0.005
    if abs(mid_max_dpMass - des_max_dpMass) < 0.0005
        amplitude = mid_amplitude;
        [max_GRF, max_dpMass, mean_Pmet] = unpack(mid_objectives(:));
        return
    end
    
    if (des_max_dpMass < mid_max_dpMass)
        next_amplitude_range = [amplitude_range(1), mid_amplitude];
        next_objectives_range = [objectives_range(1,:); mid_objectives];
        
    elseif (des_max_dpMass > mid_max_dpMass)
        next_amplitude_range = [mid_amplitude, amplitude_range(2)];
        next_objectives_range = [mid_objectives; objectives_range(2,:)];
        
    end
    % search recusively until returns
    [amplitude, max_GRF, max_dpMass, mean_Pmet] = search_amplitude(...
                    des_max_dpMass, model_name, material_params, ...
                    next_amplitude_range, ...
                    next_objectives_range, iters+1);

end

%% pack and unpack functions between objective matrices and seaparte scalars 
% matlab cannot do python-style unpack, needs additional functions
function [max_GRF, max_dpMass, mean_Pmet] = unpack(objectives)

    max_GRF = objectives(1);
    max_dpMass = objectives(2);
    mean_Pmet = objectives(3);
end

function objectives = eval_and_pack(...
    model_name, material_params, amplitude)

    [max_GRF, max_dpMass, mean_Pmet] = eval_params(...
        model_name, material_params, amplitude);
    objectives = [max_GRF, max_dpMass, mean_Pmet];
end


