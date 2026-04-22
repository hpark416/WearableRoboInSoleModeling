clc; close all; clear

folder_dir = "./generated_data/";
mkdir(folder_dir)

%%
% record baseline value
model_name = 'original/FullHopper_baseline';
% model_filename = strcat('./',model_name,'.slx');
w = warning('off','all');
load_system(model_name);

simout = sim(model_name);    

% save time series
save(strcat(folder_dir,"baseline.mat"), "simout")

close_system(model_name,0);          
warning(w)


%% params
% sweep
K_shoes = 20000:2500:70000;
thicknesses = 0.01:0.0025:0.035; % not very interesting

%% actual simulation
model_name = 'FullHopper_alt';
model_filename = strcat('./',model_name,'.slx');
w = warning('off','all');
load_system(model_name);

tic
for thickness = thicknesses % more like max compression
    disp(strcat("thickness=", num2str(thickness)))
    
    for K_shoe = K_shoes
        
        set_param(strcat(model_name,'/LoadDynamics/k_shoe'),'Value',num2str(K_shoe));
        set_param(strcat(model_name,'/LoadDynamics/thickness'),'Value',num2str(thickness));
        
        filename = strcat(folder_dir,...
            'k_',num2str(K_shoe),'_maxcomp_',num2str(thickness),'.mat');

        simout = sim(model_name);     
        save(filename, "simout")

    end
end

close_system(model_name,0);          
warning(w)
toc

