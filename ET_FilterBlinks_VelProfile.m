function [pupil, timestamp] = ET_FilterBlinks_VelProfile(pupil, timestamp, precision)
% blink filtering algorithm based on the process described by the Sebastiaan
% Mathot paper - "A simple way to reconstruct pupil size during eye blinks"

[pupil,timestamp] = resample(pupil,timestamp,60);  %resample data
pupil_res=pupil;
%% Generate velocity profile
w1=hann(11)/sum(hanning(11));                   %create hanning window (11ms)
pupil_smoothed=conv(pupil,w1,'same');           %smoothed pupil signal
vel=diff(pupil_smoothed)./diff(timestamp);      %velocity profile

%% Find blink onset/blink offset index using vel
neg_threshold = mean(vel)-std(vel);
greater_neg = vel >= neg_threshold;
less_neg = vel < neg_threshold;
greater_neg(2:end+1) = greater_neg;
less_neg(end+1) = less_neg(end);
blink_index.onset = find(greater_neg&less_neg);

pos_threshold = mean(vel)+std(vel);
greater_pos = vel > pos_threshold;
less_pos = vel <= pos_threshold;
greater_pos(2:end+1) = greater_pos;
less_pos(end+1) = less_pos(end);
blink_index.offset = find(greater_pos&less_pos);

i=1;
while i<numel(blink_index.offset) && i<numel(blink_index.onset)
    if blink_index.onset(i)<blink_index.offset(i)
        if blink_index.onset(i+1)>blink_index.offset(i)
            if (timestamp(blink_index.onset(i+1)) - timestamp(blink_index.offset(i))) > precision
                i=i+1;
            elseif (timestamp(blink_index.onset(i+1)) - timestamp(blink_index.offset(i))) <= precision %if the separation between two blink events is less than user-defined precision, merge the two events
                blink_index.onset(i+1) = [];
                blink_index.offset(i) = [];
            end
        elseif blink_index.onset(i+1)<=blink_index.offset(i)
            blink_index.onset(i+1) = [];
        end
    elseif blink_index.onset(i)>=blink_index.offset(i)
        blink_index.offset(i) = [];
    end
end

if numel(blink_index.onset) > numel(blink_index.offset)
    blink_index.onset(numel(blink_index.offset)+1:end) = [];
elseif numel(blink_index.onset) < numel(blink_index.offset)
    blink_index.offset(numel(blink_index.onset)+1:end) = [];
end


%% interpolate - future changes - use "averages" around the timepoints instead of the single value for the timepoints
for j=1:length(blink_index.onset)
    if timestamp(blink_index.offset(j))-timestamp(blink_index.onset(j)) > 10
        pupil(blink_index.onset(j):blink_index.offset(j))=NaN;
    else
        t2 = blink_index.onset(j);
        t3 = blink_index.offset(j);
        t1 = t2-t3+t2;
        t4 = t3-t2+t3;
        if t1 <= 0
            t1 =1;
        end
        if t4 > numel(pupil)
            t4 = numel(pupil);
        end
        if t3 < t2
            continue
        end
        if t1 == t2 || t2 == t3 || t3 == t4
            continue
        end
        x = [t1,t2,t3,t4];
        v = [pupil(t1),pupil(t2),pupil(t3),pupil(t4)];
        xq = t2:t3;
        vq = interp1(x,v,xq,'linear');
        pupil(t2:t3) = vq;
    end
end
