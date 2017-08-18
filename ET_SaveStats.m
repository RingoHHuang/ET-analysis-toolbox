function ET_SaveStats( outputFileName, stats, S, varargin )
%Saves an summary output file of the desired stats
%   outputFileName: a string for the file name with a .txt extension
%   stats: structure containing the user's desired statistics
%   S: data structure
%   varargin{1} (optional): array where the elements are the indices
%   for the events that will be merged into the summary file

narginchk(3,4);

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

statsFields = fieldnames(stats);
fileID = fopen(outputFileName,'w');

%% Create headers in text file
header_num = 1;
for i=1:numel(event_nums)
    event_num = event_nums(i);
    prefix = [S(1).event(event_num).event_name, '_'];
    for stats_num=1:numel(statsFields)
        if stats.(statsFields{stats_num}) == 1
            switch statsFields{stats_num}
                case 'getMEAN'
                    header{header_num} = [prefix,'MEAN'];
                case 'getSTD'
                    header{header_num} = [prefix,'STD'];
                case 'getSAMPLE_COUNT'
                    header{header_num} = [prefix,'SAMPLE_COUNT'];
                case 'getMAX'
                    header{header_num} = [prefix,'MAX'];
                case 'getMIN'
                    header{header_num} = [prefix,'MIN'];
            end
            header_num = header_num+1;
        end
    end
end
lineFormat = ['InputFile\tTrialNumber',repmat('\t%s',1,header_num-1),'\n'];
fprintf(fileID,lineFormat,header{:});

%% Copy data from structure array to text file
for sub_num=1:numel(S)
    for trial_num=1:numel(S(sub_num).event(1).trial)
        item_num = 1;
        for i=1:numel(event_nums)
            event_num = event_nums(i);
            for stats_num=1:numel(statsFields)
                if stats.(statsFields{stats_num}) == 1
                    switch statsFields{stats_num}
                        case 'getMEAN'
                            item{item_num} = S(sub_num).event(event_num).trial(trial_num).mean;
                        case 'getSTD'
                            item{item_num} = S(sub_num).event(event_num).trial(trial_num).std;
                        case 'getSAMPLE_COUNT'
                            item{item_num} = S(sub_num).event(event_num).trial(trial_num).sample_count;
                        case 'getMAX'
                            item{item_num} = S(sub_num).event(event_num).trial(trial_num).max;
                        case 'getMIN'
                            item{item_num} = S(sub_num).event(event_num).trial(trial_num).min;
                    end
                    item_num = item_num+1;
                end
            end
        end
        lineFormat = ['%s\t%f',repmat('\t%f',1,item_num-1),'\n'];
        fprintf(fileID,lineFormat,S(sub_num).inputFileName,trial_num,item{:});
    end
end
fclose(fileID);
end