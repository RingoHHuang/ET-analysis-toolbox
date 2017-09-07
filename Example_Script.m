%% Example Script for ET-analysis-toolbox
% Demonstrates how to use the functions for your data
% This currently works with Example_Data2 (a handgrip task), to make it
% work with Example_Data1, you'll need reconfigure the start_message and
% endings in the "Configure events" block of this script

clear S;
%% Configure data file
config.type_msg_string = 'MSG';
config.type_smp_string = 'SMP';
config.type_col = 2;
config.msg_col = 4;
config.smp_col = 8;
config.ts_col = 1;
config.duration_col = '';
config.skip_rows = 0;

%% Input statistics options
stats.getMEAN = 1;
stats.getSTD = 1;
stats.getSAMPLE_COUNT = 1;
stats.getMAX = 1;
stats.getMIN = 1;
stats.test = 0;
files = dir('Example2*.txt');

S(numel(files)) = struct;

f_num = 0;  %for plot indices
plot_num=0; %for plot indices

for sub_num = 1:numel(files)
    S(sub_num).isRawData = 1;
    S(sub_num).inputFileName = files(sub_num).name;
    S(sub_num).inputFullPath = fullfile(files(sub_num).folder,files(sub_num).name);
    
    %% Read data from file to structure
    S(sub_num).data = ET_ReadFile(S(sub_num).inputFullPath,config);
    
    %% Convert timestamp to seconds
    S(sub_num).data.smp_timestamp = S(sub_num).data.smp_timestamp/10^6;
    S(sub_num).data.msg_timestamp = S(sub_num).data.msg_timestamp/10^6;
    
    %% Prepare Plots for visualizing filtering steps
    if plot_num == 0
        f_num = f_num+1;
        f(f_num) = figure();
    end
    plot_num = plot_num+1;
    
    pupil = S(sub_num).data.sample;
    timestamp = S(sub_num).data.smp_timestamp;
    
    %% Filter using Velocity Profile Method
    [pupil,timestamp] = ET_FilterBlinks_VelProfile(pupil,timestamp,0.1);
    
    %% Plot reconstructed (blue) on original (green)
    set(0,'CurrentFigure',f(f_num))
    subplot(6,2,plot_num);
    plot(S(sub_num).data.smp_timestamp,S(sub_num).data.sample,'green',timestamp,pupil,'blue');
    title('Vel Profile Only');
    ylim([0,50])
    plot_num=plot_num+1;
    
    %% Filter using hard clipping method
    [pupil,timestamp] = ET_FilterBlinks_Clipping(pupil,timestamp,3,0.1,2,2);
    
    %% Plot reconstructed (blue) on original (green)
    set(0,'CurrentFigure',f(f_num))
    subplot(6,2,plot_num);
    plot(S(sub_num).data.smp_timestamp,S(sub_num).data.sample,'green',timestamp,pupil,'blue');
    title('Vel Profile and Clipping');
    ylim([0,50])
    
    if plot_num == 12
        plot_num = 0;
    end
    
    %% Configure events
    %parameters for event1
    S(sub_num).event(1).event_name = 'Baseline';
    S(sub_num).event(1).start_message = '# Message: Squeeze';
    S(sub_num).event(1).ending = -60;
    %parameters for event2
    S(sub_num).event(2).event_name = 'Squeeze';
    S(sub_num).event(2).start_message = '# Message: Squeeze';
    S(sub_num).event(2).ending = 18;
    %parameters for event3
    S(sub_num).event(3).event_name = 'Recovery';
    S(sub_num).event(3).start_message = '# Message: Recovery';
    S(sub_num).event(3).ending = 30;
    
    
    %% Parse data
    for event_num = 1:numel(S(sub_num).event)
        S(sub_num).event(event_num).trial = ET_ParseData(S(sub_num),event_num);
    end
    
    %% Do statistics
    for event_num = 1:numel(S(sub_num).event)
        S(sub_num).event(event_num).trial = ET_Statistics(S(sub_num).event(event_num).trial,stats);
    end
    
    %% Bin data
    for event_num = 1:numel(S(sub_num).event)
        [S(sub_num).event(event_num).trial] = ET_BinData(S(sub_num).event(event_num).trial);
    end
end
%% Save to output file
ET_SaveStats('Example_StatsSummary.txt',stats,S);
ET_SaveBins('Example_BinnedData.txt',S);