function [pupil, timestamp] = ET_FilterBlinks_Clipping(pupil, timestamp, thresh_tolerance, precision, onset_buffer, offset_buffer)
%% Find blink onset/offset by thresholding the pupil
threshold = nanmean(nonzeros(pupil))-thresh_tolerance*nanstd(nonzeros(pupil));
greater = pupil > threshold;
less = pupil <= threshold;
blink_index.onset = find(greater(1:end-1)&less(2:end));
blink_index.offset = find(greater(2:end)&less(1:end-1));

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

blink_index.onset(blink_index.onset - onset_buffer > 0) = blink_index.onset(blink_index.onset - onset_buffer > 0) - onset_buffer;
blink_index.offset(blink_index.offset + offset_buffer < numel(pupil)) = blink_index.offset(blink_index.offset + offset_buffer < numel(pupil)) + offset_buffer;

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
        if blink_index.offset(j)<blink_index.onset(j)
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