%%
% =========================================================================
%  Understanding why SLAM algorithms fail in modern indoor environments.
% =========================================================================

%                  Study Center (St. Center)

% ======================= Useful Instruction ==============================
%   This code runs in sections, first you have to use the 'Run' command to
%   load the parameters to workspace, it will return some warnings and
%   errors, never mind. Use the 'Run section' command to analyse the
%   section of your choice. Make sure you click at the section first before
%   using the 'Run section' command.
% =========================================================================

%%  ==================  Load dataset to the workspace  =======================

%   Check if there is existing data loaded in workspace  
if ~isempty(who)
%   If there is data, the you have to to clear the workspace
    clear_data = questdlg('There is existing data in the workspace. Do you want to clear the workspace?', 'Clear Workspace', 'Yes', 'No', 'Yes');
    
    if strcmp(clear_data, 'Yes')
%   Clear the workspace and command prompt, clear all variables
        close all
        clear
        clc
        disp('Workspace cleared')
    else
%   If you doesn't want to clear the workspace, exit the program
        return
    end
end

%%   If there is no data loaded, ask user to load data to workspace
if ~exist('data_loaded', 'var')
%     data_loaded = false;
    load_data = questdlg('Do you want to load data to workspace?', 'Load Data', 'Yes', 'No', 'Yes');

  if strcmp(load_data, 'Yes')
      
gtVisStudyCenter = 'gtVisStudyCenter.csv'; % GroundTruth
rtabStudyCenter = 'rtabStudyCenter.csv';
orbslamStudyCenter = 'orbslamStudyCenter.csv';

%   Read and extract the messages 

gtVisStudyCenter_data = readtable(gtVisStudyCenter);
rtabStudyCenter_data = readtable(rtabStudyCenter);
orbslamStudyCenter_data = readtable(orbslamStudyCenter);

% Extract the timestamp column
gt_time_stamp = gtVisStudyCenter_data{:,1};
rtab_time_stamp = rtabStudyCenter_data{:,1};
orbslam_time_stamp = orbslamStudyCenter_data{:,1};

% Convert the timestamps to real time
gt_time = [((gt_time_stamp)- (gt_time_stamp(1)))];
rtab_time = [((rtab_time_stamp)- (rtab_time_stamp(1)))];
orbslam_time = [((orbslam_time_stamp)- (orbslam_time_stamp(1)))];

% Extract the x, y, z position columns
gt_x = gtVisStudyCenter_data{:,2};
gt_y = gtVisStudyCenter_data{:,3};
gt_z = gtVisStudyCenter_data{:,4};

rtab_x = rtabStudyCenter_data{:,2};
rtab_y = rtabStudyCenter_data{:,3};
rtab_z = rtabStudyCenter_data{:,4};

orbslam_x = orbslamStudyCenter_data{:,2};
orbslam_y = orbslamStudyCenter_data{:,3};
orbslam_z = orbslamStudyCenter_data{:,4};

% Extract the qx, qy, qz, qw rotation columns
gt_qz = gtVisStudyCenter_data{:,7};
rtab_qz = rtabStudyCenter_data{:,7};
orbslam_qz = orbslamStudyCenter_data{:,7};


%   Arrange the position and rotation data
%   Pose data
gt_translation_ts = [gt_time, (gt_x ), (gt_y), gt_z];
rtab_pose_ts = [rtab_time, rtab_x, rtab_y, rtab_z];
orbslam_pose_ts = [orbslam_time, orbslam_x, orbslam_y, orbslam_z];

%   Angular data
gt_rotation_ts = [gt_qz];
rtab_orient_ts = [rtab_qz];
orbslam_orient_ts = [orbslam_qz];

%   Extract the ground-truth (GT) data

    ground_truth_x = gt_translation_ts(:,2);
    ground_truth_y = gt_translation_ts(:,3);
    gt_estimated_z = gt_rotation_ts(:,1);

%   rtab
    rtab_estimated_x = rtab_pose_ts(:,2);
    rtab_estimated_y = rtab_pose_ts(:,3);
    rtab_estimated_z = rtab_orient_ts(:,1);

%   ORB-SLAM 
    orbslam_estimated_x = orbslam_pose_ts(:,2);
    orbslam_estimated_y = orbslam_pose_ts(:,3);
    orbslam_estimated_z = orbslam_orient_ts(:,1);

% Interpolate the estimated data
%   target length of the interpolated matrix
    target_length = 69416;

%   GT
    interp_gt_x = interp1(1:length(ground_truth_x), ground_truth_x, linspace(1, length(ground_truth_x), target_length))';
    interp_gt_y = interp1(1:length(ground_truth_y), ground_truth_y, linspace(1, length(ground_truth_y), target_length))';
    interp_gt_z= interp1(1:length(gt_estimated_z), gt_estimated_z, linspace(1, length(gt_estimated_z), target_length))';
    interp_gt_time = interp1(1:length(gt_time), gt_time, linspace(1, length(gt_time), target_length))';

%   rtab
    interp_rtab_x = interp1(1:length(rtab_estimated_x), rtab_estimated_x, linspace(1, length(rtab_estimated_x), target_length))';
    interp_rtab_y = interp1(1:length(rtab_estimated_y), rtab_estimated_y, linspace(1, length(rtab_estimated_y), target_length))';
    interp_rtab_z = interp1(1:length(rtab_estimated_z), rtab_estimated_z, linspace(1, length(rtab_estimated_z), target_length))';
    interp_rtab_time = interp1(1:length(rtab_time), rtab_time, linspace(1, length(rtab_time), target_length))';

%   ORB-SLAM
    interp_orbslam_x = interp1(1:length(orbslam_estimated_x), orbslam_estimated_x, linspace(1, length(orbslam_estimated_x), target_length))';
    interp_orbslam_y = interp1(1:length(orbslam_estimated_y), orbslam_estimated_y, linspace(1, length(orbslam_estimated_y), target_length))';
    interp_orbslam_z=  interp1(1:length(orbslam_estimated_z), orbslam_estimated_z, linspace(1, length(orbslam_estimated_z), target_length))';
    interp_orbslam_time = interp1(1:length(orbslam_time), orbslam_time, linspace(1, length(orbslam_time), target_length))';

% Compute the errors between ground truth and interpolated estimated poses
%   rtab
    errors_rtab_x = interp_rtab_x - interp_gt_x;
    errors_rtab_y = interp_rtab_y - interp_gt_y;
    errors_rtab_z = interp_gt_z- interp_rtab_z;

% orbslam
    errors_orbslam_x = interp_gt_x - interp_orbslam_x;
    errors_orbslam_y = interp_gt_y - interp_orbslam_y;
    errors_orbslam_z = interp_gt_z- interp_orbslam_z;

% Compute the translation errors
%   rtab
    x_trans_rtab = (interp_gt_x - interp_rtab_x).^2;
    y_trans_rtab = (interp_gt_y - interp_rtab_y).^2;
    trans_error_rtab = sqrt(x_trans_rtab + y_trans_rtab);

%   orb-slam
    x_trans_orbslam = (interp_gt_x - interp_orbslam_x).^2;
    y_trans_orbslam = (interp_gt_y - interp_orbslam_y).^2;
    trans_error_orbslam = sqrt(x_trans_orbslam + y_trans_orbslam);

% Compute the angular errors
%   rtab
    ang_error_rtab = abs(interp_gt_z - interp_rtab_z);
    ang_error_rtab = min(ang_error_rtab, 2*pi - ang_error_rtab);

%   orbslam
    ang_error_orbslam = abs(interp_gt_z - interp_orbslam_z);
    ang_error_orbslam = min(ang_error_orbslam, 2*pi - ang_error_orbslam);

% Compute the translation errors
%   rtab
    error_rtab = sqrt((interp_rtab_x - interp_gt_x).^2 + (interp_rtab_y - interp_gt_y).^2);
%   orbslam
    error_orbslam = sqrt((interp_orbslam_x - interp_gt_x).^2 + (interp_orbslam_y - interp_gt_y).^2);

%   Interpolate the errors to match the distance traveled
%   target length of the interpolated matrix
    target_length_distance = 69415;

%   GT
    interp_error_rtab = interp1(1:length(error_rtab), error_rtab, linspace(1, length(error_rtab), target_length_distance))';
    interp_error_orbslam = interp1(1:length(error_orbslam), error_orbslam, linspace(1, length(error_orbslam), target_length_distance))';
        
%     data_loaded = true;
    disp('Data loaded to workspace')
  end
else
    return
end


%% Sections
sections = {'Show the trajectories', 'Absolute trajectory errors (ATE)', 'Relative pose error (RPE)', 'Root mean square error (RMSE)', 'Scale drift', 'Avg. error and distance travelled', 'Time to convergence', 'Quit'};
[indx, tf] = listdlg('PromptString', 'Select section(s) to run:', 'ListString', sections, 'SelectionMode', 'multiple');
if tf
%   Execute the selected sections
    for i = 1:length(indx)
        switch sections{indx(i)}    
% Choose the section that you want to analyse
%    select_section = questdlg('Which section do you want to analyse?', 'Select Section', 'Plot the trajectories', 'Plot ATE, RPE & RMSE', 'Plot SD & TTC', 'Plot the trajectories');

%% Plot the robot's trajectory data as well as the variables
            case 'Show the trajectories'       
%   Plot the trajectories in 2D
    figure;
    plot(gt_translation_ts(:,2),gt_translation_ts(:,3),"r","LineWidth",1.0)
    hold on
    plot(rtab_pose_ts(:,2),rtab_pose_ts(:,3),"b","LineWidth",1.0)
    hold on
    plot(orbslam_pose_ts(:,2),orbslam_pose_ts(:,3),"g","LineWidth",1.0)
    xlabel('x-pose [m]')
    ylabel('y-pose [m]')
%    zlabel('z-pose [m]')
    legend("GT ","RTAB","ORB-SLAM2")

%   Plot the topic varaiables
    figure;
    subplot(1, 3, 1)
    plot(gt_time,gt_translation_ts(:,2), gt_time,gt_translation_ts(:,3), gt_time,gt_rotation_ts(:,1))
    %title('gt pose')
    xlabel('Time [seconds]')
    ylabel('gt pose')
    legend("x-pose [m]","y-pose [m]", "angular-z [rad]")
%    xlim([0 500])
    grid on

    subplot(1, 3 ,2)
    plot(rtab_time,rtab_pose_ts(:,2), rtab_time,rtab_pose_ts(:,3), rtab_time,rtab_orient_ts(:,1))
%   title('rtab estimated pose')
    xlabel('Time [seconds]')
    ylabel('rtab pose')
    legend("x-pose [m]","y-pose [m]", "angular-z [rad]")
    grid on

    subplot(1, 3 ,3)
    plot(orbslam_time,orbslam_pose_ts(:,2), orbslam_time,orbslam_pose_ts(:,3), orbslam_time,orbslam_orient_ts(:,1))
%   title('orbslam pose')
    xlabel('Time [seconds]')
    ylabel('orbslam pose')
    legend("x-pose [m]","y-pose [m]", "angular-z [rad]")
    grid on

    disp('The displayed plots are the robot trajectories')

%% Analyse the absolute trajectory error (ATE)  
            case 'Absolute trajectory errors (ATE)'           
%   Compute the absolute trajectory errors (ATE)
    rtab_ate = sqrt(errors_rtab_x.^2 + errors_rtab_y.^2);
    orbslam_ate = sqrt(errors_orbslam_x.^2 + errors_orbslam_y.^2);

%   Create an array of ate values for multiple runs of the slam algorithm
    ate_values_rtab = [rtab_ate];
    ate_values_orbslam = [orbslam_ate];

%   Set the bin edges for the histogram
    bins_rtab = linspace(min(ate_values_rtab(:)), max(ate_values_rtab(:)), 40);
    bins_orbslam = linspace(min(ate_values_orbslam(:)), max(ate_values_orbslam(:)), 40);

%   Plot ATE error histogram
    figure;
    histogram(ate_values_rtab, bins_rtab, 'Normalization', 'probability', 'FaceColor', 'r','FaceAlpha',1.0);
    hold on
    histogram(ate_values_orbslam, bins_orbslam, 'Normalization', 'probability', 'FaceColor', 'c', 'EdgeAlpha', 0.06);
    legend('rtab', 'orbslam');
    ax = gca; 
    ax.XAxis.LineWidth = 2;
    ax.YAxis.LineWidth = 2;
    ax.FontSize = 14; 
    xlabel('ATE Error (m)');
    ylabel('Probability');
%   title('ATE Error Histograms');
    set(gca, 'FontWeight', 'bold');	
%   set(gca, 'XTickLabel', get(gca, 'XTick'), 'FontWeight', 'bold');	
%   set(gca, 'YTickLabel', get(gca, 'YTick'), 'FontWeight', 'bold'); 	

    xline(mean(rtab_ate),'--r', '\mu','HandleVisibility','off');
    xline(mean(orbslam_ate),'--c', '\mu','HandleVisibility','off');
    
    hold off;

%   Plot the ATE against timestamp
    figure;
    plot(interp_gt_time, rtab_ate, 'r');
    hold on
    plot(interp_gt_time, orbslam_ate, 'b');
    xlabel('Time (s)');
    ylabel('ATE (m)');
    legend('rtab', 'orbslam')
    yline(mean(rtab_ate),'--g', 'meanrtab','HandleVisibility','off');
    yline(mean(orbslam_ate),'--c', 'meanorbslam','HandleVisibility','off');
    
    clc
    disp('The displayed plots shows the ATE')
    disp('The mean ATE for rtab and orbslam are:')
    disp([mean(rtab_ate) mean(orbslam_ate)])
    disp('The standard deviation of the ATE for rtab and orbslam are:')
    disp([std(rtab_ate) std(orbslam_ate)])


%% Compute the relative pose errors (RPE)
            case 'Relative pose error (RPE)'    
%   rtab
    rpe_trans_rtab = trans_error_rtab ./ sqrt(interp_gt_x.^2 + interp_gt_y.^2);
    rpe_ang_rtab = ang_error_rtab ./ (2*pi);

%   orbslam-SLAM
    rpe_trans_orbslam = trans_error_orbslam ./ sqrt(interp_gt_x.^2 + interp_gt_y.^2);
    rpe_ang_orbslam = ang_error_orbslam ./ (2*pi);

%   Plot the RPE
    figure;
    subplot(2,1,1);
    plot(interp_gt_time, rpe_trans_rtab);
    hold on 
    plot(interp_gt_time, rpe_trans_orbslam);
    legend("rtab","orbslam")
    xlabel('Time (s)');
    ylabel('Translational RPE ');

    subplot(2,1,2);
    plot(interp_rtab_time,rpe_ang_rtab);
    hold on 
    plot(interp_rtab_time, rpe_ang_orbslam);
    legend("rtab","orbslam")
    xlabel('Time (s)');
    ylabel('Angular RPE ');

    clc
    disp('The displayed plots shows the relative pose errors (RPE) ')
    disp('The mean RPE-trans for rtab and orbslam are:')
    disp([mean(rpe_trans_rtab) mean(rpe_trans_orbslam)])
    disp('The standard deviation of the RPE-trans for rtab and orbslam are:')
    disp([std(rpe_trans_rtab) std(rpe_trans_orbslam)])
    
    disp('The mean RPE-rot for rtab, orbslam are:')
    disp([mean(rpe_ang_rtab) mean(rpe_ang_orbslam)])
    disp('The standard deviation of the RPE-rot for rtab and orbslam are:')
    disp([std(rpe_ang_rtab) std(rpe_ang_orbslam)])    
    
%% Compute the root mean square error (RMSE)
            case 'Root mean square error (RMSE)'    
%   rtab
    x_mse_trans_rtab = (interp_gt_x - interp_rtab_x).^2 ;
    y_mse_trans_rtab = (interp_gt_y - interp_rtab_y).^2;
    mse_trans_rtab = mean(x_mse_trans_rtab + y_mse_trans_rtab);
    mse_ang_rtab = mean(ang_error_rtab.^2);
%   Compute the root mean squared error
    rmse_trans_rtab = sqrt(mse_trans_rtab);
    rmse_ang_rtab = sqrt(mse_ang_rtab);

%   orbslam-SLAM
    x_mse_trans_orbslam = (interp_gt_x - interp_orbslam_x).^2 ;
    y_mse_trans_orbslam = (interp_gt_y - interp_orbslam_y).^2;
    mse_trans_orbslam = mean(x_mse_trans_orbslam + y_mse_trans_orbslam);
    mse_ang_orbslam = mean(ang_error_orbslam.^2);
%   Compute the root mean squared error
    rmse_trans_orbslam = sqrt(mse_trans_orbslam);
    rmse_ang_orbslam = sqrt(mse_ang_orbslam);
   
    clc   
    disp('The translational RMSE for rtab and orbslam are:')
    disp([(rmse_trans_rtab) (rmse_trans_orbslam)])
    
    disp('The angular RMSE for rtab and orbslam are:')
    disp([(rmse_ang_rtab) (rmse_ang_orbslam)])

%% Compute the average error and the distance traveled 
            case 'Avg. error and distance travelled'        
% Average translation error in percentage
%   Compute the average error
    average_error_rtab = mean(error_rtab);
    average_error_orbslam = mean(error_orbslam);

%   Compute the average error in percentage
    average_error_percent_rtab = 100 * average_error_rtab / mean(sqrt(interp_gt_x.^2 + interp_gt_y.^2));
    average_error_percent_orbslam = 100 * average_error_orbslam / mean(sqrt(interp_gt_x.^2 + interp_gt_y.^2));
                
% Compute the cumulative distance traveled    
    gt_cumulative_distance = cumsum(sqrt(diff(interp_gt_x).^2 + diff(interp_gt_y).^2));
    rtab_cumulative_distance = cumsum(sqrt(diff(interp_rtab_x).^2 + diff(interp_rtab_y).^2));
    orbslam_cumulative_distance = cumsum(sqrt(diff(interp_orbslam_x).^2 + diff(interp_orbslam_y).^2));
%   Compute the distance traveled by the robot
    distance = cumsum(sqrt(diff(interp_gt_x).^2 + diff(interp_gt_y).^2));
    
%   Display the average error in percentage
    clc
    disp(['Average error in percentage_rtab: ', num2str(average_error_percent_rtab), '%']);
    disp(['Average error in percentage_orbslam: ', num2str(average_error_percent_orbslam), '%']);
        
% Plot the translation error against the distance traveled
    figure;
    plot(distance, interp_error_rtab);
    hold on
    plot(distance, interp_error_orbslam);

    xlabel('Distance traveled (m)');
    ylabel('Translation error (m)');
    %title('Translation error vs distance traveled');% Compute the distance traveled by the robot
    legend('rtab','orbslam')

    disp('The displayed plots shows distance travelled against the errors')


%% Compute the scale drift    
            case 'Scale drift' 
 % Extract the ground truth and estimated trajectories from the table
    gt_traj = [interp_gt_x, interp_gt_y, interp_gt_z];
    rtab_est_traj = [interp_rtab_x, interp_rtab_y, interp_rtab_z];
    orbslam_est_traj = [interp_orbslam_x, interp_orbslam_y, interp_orbslam_z];

% Compute the scale deviation between the ground truth and estimated trajectories
    N = size(gt_traj, 1);
    rtab_scale_deviation = zeros(N-1, 1);
    orbslam_scale_deviation = zeros(N-1, 1);
   
 for k = 2:N
    gt_dist = norm(gt_traj(k,:) - gt_traj(k-1,:));
    rtab_est_dist = norm(rtab_est_traj(k,:) - rtab_est_traj(k-1,:));
    orbslam_est_dist = norm(orbslam_est_traj(k,:) - orbslam_est_traj(k-1,:));
    rtab_scale_deviation(k-1) = rtab_est_dist/gt_dist;
    orbslam_scale_deviation(k-1) = orbslam_est_dist/gt_dist;
 end  

% Create a time vector for the scale deviation data
    target_length_time = 69415;
    time = interp1(1:length(gt_time), gt_time, linspace(1, length(gt_time), target_length_time))';

% Plot the scale deviation over time
    plot(time, rtab_scale_deviation, time, orbslam_scale_deviation);
    xlabel('Time');
    ylabel('Scale deviation');
    title('Scale deviation over time');               
                  
% % Compute the cumulative distance traveled by the ground truth trajectory
% gt_cumulative_distance = cumsum(sqrt(diff(interp_gt_x).^2 + diff(interp_gt_y).^2));
% 
% % Compute the cumulative distance traveled by the rtab trajectory
% rtab_cumulative_distance = cumsum(sqrt(diff(interp_rtab_x).^2 + diff(interp_rtab_y).^2));
% 
% % Compute the cumulative distance traveled by the orbslam trajectory
% orbslam_cumulative_distance = cumsum(sqrt(diff(interp_orbslam_x).^2 + diff(interp_orbslam_y).^2));
% 
% 
% % Compute the scale drift in percentage
% scale_drift_rtab = (rtab_cumulative_distance ./ gt_cumulative_distance);
% scale_drift_orbslam = (orbslam_cumulative_distance ./ gt_cumulative_distance);
% 
% %Mean Scale Drift
% 
% mean_rtab_scale_drift = std(scale_drift_rtab)
% mean_orbslam_scale_drift = std(scale_drift_orbslam)
% 
% % Plot the scale drift
% drift_time_rtab = imresize(rtab_time,[69415,1]);
% drift_time_orbslam = imresize(orbslam_time,[69415,1]);
% 
% figure;
% plot(drift_time_rtab, scale_drift_rtab);
% hold on
% plot(drift_time_rtab, scale_drift_orbslam);
% xlim([0 300])
% xlabel('Time (s)');
% ylabel('Scale Drift');
% legend('rtab','orbslam')
     
%% Compute the time to convergence (TTC)
            case 'Time to convergence'
% Compute the time to convergence (TTC) metrics 
%   Define the convergence threshold
    threshold = 0.1;

%   Find the index of the first time the error is below the threshold
    rtab_first_convergence_index = find(rtab_ate < threshold, 1);
    orbslam_first_convergence_index = find(orbslam_ate < threshold, 1);
    
%   Compute the time to convergence
    rtab_time_to_convergence = interp_rtab_time(rtab_first_convergence_index);
    orbslam_time_to_convergence = interp_orbslam_time(orbslam_first_convergence_index);
   
%   Display the time to convergence
    disp(['Time to convergence_rtab: ', num2str(rtab_time_to_convergence), 's']);
    disp(['Time to convergence_orbslam: ', num2str(orbslam_time_to_convergence), 's']);

%   Plot the ATE and TTC
    figure;
    plot(interp_gt_time, rtab_ate, 'LineWidth', 1.0);
    hold on
    plot(interp_gt_time, orbslam_ate, 'LineWidth', 1.0);
    
    hold on;
    plot(rtab_time_to_convergence, rtab_ate(rtab_first_convergence_index), '*', 'MarkerSize', 10);
    hold on;
    plot(orbslam_time_to_convergence, orbslam_ate(orbslam_first_convergence_index), 'o', 'MarkerSize', 10);
    
    xlabel('Time (s)');
    ylabel('ATE (m)');
    title('ATE vs Time');
    legend({'ATE', 'TTC'});
    
    disp('The displayed plots shows ATE and TTC')

%% Quit the program
  case 'Quit'
%   Quit the program
        return        
    otherwise
%   User did not select a valid option
        disp('Invalid selection')

        end
    end
end  


