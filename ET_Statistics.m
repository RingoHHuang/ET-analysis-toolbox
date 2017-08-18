function [ trial ] = ET_Statistics( trial, stats )
%ET_Statistics
%   trial: is the structure containing a pupil field; trial is a field of
%   event
%   stats: is the strcture with stats configuration defined by the user.
%   The possible fields in stats include: getMEAN, getSTD, getSAMPLE_COUNT,
%   getMAX, getMIN, with values of 0 or 1. If one of the possible fields is
%   missing from the stats structure, the function ignores that associated
%   stat
%

statsFields = fieldnames(stats);
for trial_num = 1:numel(trial)
    for stats_num = 1:numel(statsFields)
        if stats.(statsFields{stats_num}) == 1
            switch statsFields{stats_num}
                case 'getMEAN'
                    trial(trial_num).mean = mean(nonzeros(trial(trial_num).pupil));
                case 'getSTD'
                    trial(trial_num).std = std(nonzeros(trial(trial_num).pupil));
                case 'getSAMPLE_COUNT'
                    trial(trial_num).sample_count = numel(nonzeros(trial(trial_num).pupil));
                case 'getMAX'
                    trial(trial_num).max = max(nonzeros(trial(trial_num).pupil));
                case 'getMIN'
                    trial(trial_num).min = min(nonzeros(trial(trial_num).pupil));
            end
        end
    end
end

