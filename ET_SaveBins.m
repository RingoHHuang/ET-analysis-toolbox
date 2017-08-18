function ET_SaveBins( filename, S, varargin )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

narginchk(2,3);

if isempty(varargin)
    event_nums=1:numel(S(1).event);
elseif numel(varargin)==1
    event_nums=varargin{1};
end

% Check that number of trials for these events are equal
trialnum_check = [];
for sub_num=1:numel(S)
    for i=1:numel(event_nums)
        trialnum_check = [trialnum_check,numel(S(sub_num).event(event_nums(i)).trial)];
    end
end
if sum(trialnum_check-trialnum_check(1)) ~= 0
    error('The event_nums argument must be indexes of the event field that have the same number of elements');
end

fileID = fopen(filename,'w');

%% Create headers in text file
header_num = 1;
for i=1:numel(event_nums)
    event_num = event_nums(i);
    prefix = [S(1).event(event_num).event_name, '_'];
    for bin_num = 1:numel(S(1).event(event_num).trial(1).pupil_binned)
        header{header_num} = [prefix,num2str(header_num)];
        header_num = header_num+1;
    end
end
lineFormat = ['InputFile\tTrialNumber',repmat('\t%s',1,header_num-1),'\n'];
fprintf(fileID,lineFormat,header{:});

%% Copy data from structure array to text file
for sub_num=1:numel(S)
    for trial_num=1:numel(S(sub_num).event(event_num).trial)
        item_num = 1;
        for i=1:numel(event_nums)
            event_num = event_nums(i);
            for bin_num = 1:numel(S(sub_num).event(event_num).trial(trial_num).pupil_binned)
                item{item_num} = S(sub_num).event(event_num).trial(trial_num).pupil_binned(bin_num);
                item_num = item_num+1;
            end
        end
        lineFormat = ['%s\t%f',repmat('\t%f',1,item_num-1),'\n'];
        fprintf(fileID,lineFormat,S(sub_num).inputFileName,trial_num,item{:});
    end
end

fclose(fileID);
end

