% simulate_periodic_eeg should create a vector of a specified length, of
% which a certain proportion should contain a sine wave of specified
% periodicity, with bursts a certain length.
clear
clc
close all


DefaultCenterFrequency = 10;
DefaultBurstAmplitude = 30;
DefaultBurstDensity = .4;
DefaultBurstDuration = 1;
DefaultDuration = 60;
DefaultSampleRate = 400;
Plot = false;

WeirdInputs = [-10, -1, nan 0 .01 .1, .3, .5 .75 .9999, .000001, 1.3333, 3, 10 19.33333, 10.334566, pi, DefaultBurstDuration, DefaultDuration, 100 1000 10000, inf];


%% Test_CenterFrequency
clc

CenterFrequencies = WeirdInputs;

for CF = CenterFrequencies

    [Data, t] = cycy.sim.simulate_periodic_eeg( ...
        CF, ...
        DefaultBurstAmplitude, ...
        DefaultBurstDensity, ...
        DefaultBurstDuration, ...
        DefaultDuration, ...
        DefaultSampleRate, ...
        Plot);

    if isempty(Data)
        disp(['No output for ', num2str(CF)])
        continue
    end

    [Power, Freqs] = cycy.utils.compute_power(Data, DefaultSampleRate, 4, .5);
    [~, peakIdx] = max(Power);

    MeasuredFrequency = Freqs(peakIdx);

    if MeasuredFrequency < CF-CF*.1 || MeasuredFrequency > CF+ CF*.1
        error(['Incorrect center frequency for ', num2str(CF)])
    end
    disp(['Completed ', num2str(CF), ', achieved ', num2str(MeasuredFrequency)])
end

disp(['Correctly handles center frequencies'])



%% Test_Amplitude

clc
Amplitudes = WeirdInputs;

for Amplitude = Amplitudes
    [Data, t] = cycy.sim.simulate_periodic_eeg( ...
        DefaultCenterFrequency, ...
        Amplitude, ...
        DefaultBurstDensity, ...
        DefaultBurstDuration, ...
        DefaultDuration, ...
        DefaultSampleRate, ...
        Plot);

    if isempty(Data)
        continue
    end

    [peaks, locs] = findpeaks(abs(Data));
    MeasuredAmplitude =  mode(abs(peaks)*2);
    if  MeasuredAmplitude < Amplitude-Amplitude*.01 || MeasuredAmplitude > Amplitude+Amplitude*.01
        error(['incorrect amplitudes for ', num2str(Amplitude)])
    end

    disp(['Completed ', num2str(Amplitude), ', measured ', num2str(MeasuredAmplitude)])

end
disp(['Correctly sets duration'])


%% Test_Density

clc
Densities = WeirdInputs;

for Density = Densities
    [Data, t] = cycy.sim.simulate_periodic_eeg( ...
        DefaultCenterFrequency, ...
        DefaultBurstAmplitude, ...
        Density, ...
        DefaultBurstDuration, ...
        DefaultDuration, ...
        DefaultSampleRate, ...
        Plot);

    if isempty(Data) || all(Data==0)
        continue
    end

    Empty = nnz(diff(Data)==0);
    MeasuredDensity = 1-Empty/(numel(Data));

    if MeasuredDensity < .001 &&  Density==0
    elseif MeasuredDensity < Density - Density*.001 || MeasuredDensity > Density + Density*.001
        error(['Mismatched density ', num2str(Density)])
    end

    disp(['Completed ', num2str(Density), ', measured ', num2str(MeasuredDensity)])
end
disp(['Correctly sets duration'])



%% Test_BurstDuration

clc

Durations = WeirdInputs;

for Duration = Durations
    disp(['Simulating: ', num2str(Duration)])

    [Data, t] = cycy.sim.simulate_periodic_eeg( ...
        DefaultCenterFrequency, ...
        DefaultBurstAmplitude, ...
        DefaultBurstDensity, ...
        Duration, ...
        DefaultDuration, ...
        DefaultSampleRate, ...
        Plot);

    if isempty(Data) || all(Data==0)
        continue
    end

    [Starts, Ends] = cycy.utils.data2windows(diff(Data)~=0);
    Bursts = (Ends-Starts)/DefaultSampleRate;
    MeasuredBurst = min(Bursts);

    if MeasuredBurst < Duration - Duration*.01 || MeasuredBurst > Duration + Duration*.01
        error(['Durations too small ' num2str(Duration), ' resulting in ', num2str(MeasuredBurst), ' points'])
    end
    disp(['Measured: ', num2str(mean(Bursts))])

end
disp(['Correctly sets duration'])




%% Test_Duration

clc

Durations = WeirdInputs;

for Duration = Durations
    [Data, t] = cycy.sim.simulate_periodic_eeg( ...
        DefaultCenterFrequency, ...
        DefaultBurstAmplitude, ...
        DefaultBurstDensity, ...
        DefaultBurstDuration, ...
        Duration, ...
        DefaultSampleRate, ...
        Plot);

    if ~(isempty(Data) || all(Data==0)) && (numel(Data) ~= round(Duration*DefaultSampleRate) || numel(t) ~= round(Duration*DefaultSampleRate))
        error(['does not produce the correct number of sample points! Breaks at ' num2str(Duration), ' resulting in ', num2str(numel(t)), ' points'])
    end
    disp(['Completed ', num2str(Duration)])

end
disp(['Correctly sets duration'])


%% Test_SampleRate

SampleRates= WeirdInputs;
clc

for fs = SampleRates
 [Data, t] = cycy.sim.simulate_periodic_eeg( ...
        DefaultCenterFrequency, ...
        DefaultBurstAmplitude, ...
        DefaultBurstDensity, ...
        DefaultBurstDuration, ...
        DefaultDuration, ...
        fs, ...
        Plot);

 if isempty(Data) || all(Data==0)
     continue
 end

 MeasuredPeriod = mean(diff(t));
 Period = 1/fs;
     if  MeasuredPeriod < Period - Period*.001 || MeasuredPeriod > Period + Period*.001
     error(['Mismatch sample rate for ', num2str(fs)])
 end
disp(['completed ', num2str(fs)])
end
disp('correctly deals with sample rates')

