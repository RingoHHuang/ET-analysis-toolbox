function [ trial ] = ET_BinData( trial, varargin )
%This function bins eye-tracking samples into equal increments of the
%default 0.25s or user-defined window. Useful for creating group-level
%plots.
%
%To avoid endpoint artifact, this function pads the endpoints with the
%first and last value before resampling. After resampling, the padded
%resampled data is truncated to the original start/end timestamps

if nargin == 2
    win = varargin{1};
elseif nargin == 1
    win = 0.25;         %default bin window is 0.25 sec
end
%% Unpack input arguments
for trial_num = 1:numel(trial)
    %pad the data: add padded data to pupil_pad and associated timestamps
    %to timestamp_pad
    pupil_pad = [repmat(trial(trial_num).pupil(1),1,10),trial(trial_num).pupil',repmat(trial(trial_num).pupil(end),1,10)];
    ts_start = trial(trial_num).timestamp(1);
    ts_end = trial(trial_num).timestamp(end);
    ts_diff = trial(trial_num).timestamp(2)-trial(trial_num).timestamp(1);
    timestamp_pad = [ts_start-ts_diff*10:ts_diff:ts_start-ts_diff,trial(trial_num).timestamp',ts_end+ts_diff:ts_diff:ts_end+ts_diff*10];
    
    %resample padded data
    [pupil_binned, timestamp_binned] = resample(pupil_pad, timestamp_pad, 1/win);
    
    %truncate the padded resampled data
    start_index = find(timestamp_binned>ts_start,1,'first');
    end_index = find(timestamp_binned<ts_end,1,'last');    
    trial(trial_num).pupil_binned = pupil_binned(start_index:end_index);
    trial(trial_num).timestamp_binned = timestamp_binned(start_index:end_index);
end
