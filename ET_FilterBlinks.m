function [ pupil, timestamp ] = ET_FilterBlinks( pupil, timestamp )
%% Still a work in progress

Fs = 120;
[pupil,timestamp] = resample(pupil,timestamp,Fs/4);  %resample data
pupil_res=pupil;
w=hann(11)/sum(hanning(11));                %create hanning window (11ms)
pupil_smoothed=conv(pupil,w,'same');        %smoothed pupil signal
vel=diff(pupil_smoothed)./diff(timestamp);  %velocity profile

%% detect blink events
onset_count=1;
offset_count=1;
neg_threshold = mean(vel)-std(vel); %set neg threshold for the vel profile
pos_threshold = mean(vel)+std(vel); %set pos threshold for the vel profile
onset=[];
offset=[];
blink=[];
j=2;
while j<length(vel)
    if vel(j-1) > neg_threshold && vel(j) <= neg_threshold
        onset(onset_count)=j;
        onset_count=onset_count+1;
    elseif vel(j-1) > pos_threshold && vel(j) <= pos_threshold
        offset(offset_count)=j;
        offset_count=offset_count+1;
    end
    j=j+1;
end

blink_count=1;
k=1; %i is index for onset matrix
j=1; %j is index for offset matrix
while k<length(onset)
    blink(blink_count).onset=onset(k)-3;
    while j<length(offset) && timestamp(offset(j)) < timestamp(onset(k))
        j=j+1;
    end
    while k+1<length(onset) && timestamp(onset(k+1))-timestamp(offset(j))<.0500000
        k=k+1;
        while j<length(offset) && timestamp(offset(j)) < timestamp(onset(k))
            j=j+1;
        end
    end
    
    blink(blink_count).offset=offset(j)+3;
    blink_count=blink_count+1;
    k=k+1;
    while k<length(onset) && timestamp(onset(k)) < timestamp(offset(j)) % move i ahead of j
        k=k+1;
    end
end


%% interpolate - future changes - use "averages" around the timepoints instead of the single value for the timepoints
for j=1:length(blink)
    if timestamp(blink(j).offset)-timestamp(blink(j).onset) > 10
        pupil(blink(j).onset:blink(j).offset)=NaN;
    else
        t2 = blink(j).onset;
        t3 = blink(j).offset;
        t1 = t2-t3+t2;
        t4 = t3-t2+t3;
        if t1<=0 || t4>length(pupil) || blink(j).offset<blink(j).onset || t2==t3
            continue
        end
        x = [t1,t2,t3,t4];
        v = [pupil(t1),pupil(t2),pupil(t3),pupil(t4)];
        xq = t2:t3;
        vq = interp1(x,v,xq,'linear');
        pupil(t2:t3) = vq;
    end
end

blink_count=length(blink);

end