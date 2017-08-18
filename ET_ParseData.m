function [ trial ] = ET_ParseData( S, event_num )
% This function parses data into user-specified events depending on the
% data's parser method and design. 
% 
% There are two possible design types:
%   1. Single event - these are events that occur once in the data file.
%   The start_message input argument is a string with no asterisk
%   placeholder.
%   2. Trial event - these are events that occur for every trial in the
%   data file. The start_message argument is a string with an asterisk
%   placeholder for the trial number.
%   
% There are three possible parser methods:
%   1. End message - if the event is bounded by a start message trigger and
%   an end message trigger. The ending input argument is a string.
%   2. Duration forward - the start of the event is marked by a start
%   message trigger and the end is a user-defined duration (in seconds)
%   after it. The argument ending is a positive double.
%   3. Duration backward - the end of the event is marked by a start
%   message trigger and the start of the event is duration before the
%   message. The argument ending is a negative double.

if isfield(S.event(event_num),'start_message') && isfield(S.event(event_num),'ending')
    start_message = S.event(event_num).start_message;
    ending = S.event(event_num).ending;
else
    error('Missing required field start_message, or ending.')
end

%% Identify the design type and parser method
trial = [];
if ~contains(start_message,'*')
    design_type = 'single_event';
else
    design_type = 'trial_event';
end

if ischar(ending)
    parser_method = 'end_message';
elseif isa(ending,'double') && ending > 0
    parser_method = 'duration_forward';
elseif isa(ending,'double') && ending < 0
    parser_method = 'duration_backward';
end

%% Update data structure
fprintf([design_type ' ' parser_method '\n'])
switch design_type
    case 'single_event'
        stringStart = start_message;
        [tsStart, tsEnd] = getStartEndTimestamps(S, stringStart, ending, parser_method);
        for trial_num=1:numel(tsStart)
            trial = updateTrial(S, tsStart, tsEnd, trial, trial_num);
        end
    case 'trial_event'
        trial_num = 1;
        stringStart = replaceAsteriskWithTrialNum(start_message, trial_num);
        while find(strcmp(S.data.message,stringStart))
            switch parser_method
                case 'end_message'
                    ending2 = replaceAsteriskWithTrialNum(ending, trial_num);
                otherwise
                    ending2 = ending;
            end
            [tsStart, tsEnd] = getStartEndTimestamps(S, stringStart, ending2, parser_method);
            trial = updateTrial(S, tsStart, tsEnd, trial, trial_num);
            trial_num = trial_num + 1;
            stringStart = replaceAsteriskWithTrialNum(start_message, trial_num);
        end
end

%% Below are nested functions:
    function newString = replaceAsteriskWithTrialNum(originalString, trial_num)
        % replaces the asterisk in a trial message with the trial number      
        stringSplit = strsplit(originalString, '*');
        newString = [stringSplit{1} num2str(trial_num) stringSplit{2}];
    end

    function [ startTimestamp, endTimestamp ] = getStartEndTimestamps( S, stringStart, ending, parser_method )
        %   retrieves tsStart and tsEnd (start and end timestamps for the event)
        %   variable "ending" is a string (message) if "parser_type" is 'end_message'
        %   "ending" is time (seconds) if "parser_type" is 'duration_forward' or
        %   'duration_backward'
        
        msg_indexStart = strcmp(S.data.message,stringStart);
        startTimestamp = S.data.msg_timestamp(msg_indexStart);
        
        switch parser_method
            case 'end_message'
                msg_indexEnd = strcmp(S.data.message,ending);
                endTimestamp = S.data.msg_timestamp(msg_indexEnd);
            case 'duration_forward'
                endTimestamp = startTimestamp + ending;
            case 'duration_backward'
                endTimestamp = startTimestamp;
                startTimestamp = endTimestamp + ending;
        end
    end

    function [ indexStart, indexEnd ] = getStartEndIndices( S, tsStart, tsEnd )
        % retrieves indexStart and indexEnd (start and end sample indices 
        % in smp_timestamp and smp for the event)
        indexStart = find(S.data.smp_timestamp>=tsStart,1,'first');
        indexEnd = find(S.data.smp_timestamp<=tsEnd,1,'last');
    end

    function trial = updateTrial( S, tsStart, tsEnd, trial, trial_count)
        % Updates "trial" data stucture
        [indexStart, indexEnd] = getStartEndIndices(S, tsStart, tsEnd);
        if indexStart < indexEnd
            trial(trial_count).msg_timestamp = [tsStart, tsEnd];
            trial(trial_count).timestamp = S.data.smp_timestamp(indexStart:indexEnd);
            trial(trial_count).pupil = S.data.sample(indexStart:indexEnd);
            if S.isRawData == 0
                trial(trial_count).duration = S.data.smp_duration(indexStart:indexEnd);
            end
        else
            trial(trial_count).msg_timestamp = [tsStart, tsEnd];
            trial(trial_count).timestamp = [];
            trial(trial_count).pupil = [];
            if S.isRawData == 0
                trial(trial_count).duration = [];
            end
        end
    end
end
