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

WeirdInputs = [nan 0 .01 .1 1.3333, 3, 10 19.33333, 10.334566, pi, DefaultBurstDuration, DefaultDuration, 100 1000 10000, inf];


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

    if MeasuredFrequency < CF-CF*.05 || MeasuredFrequency > CF+ CF*.05
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

    [peaks, locs] = findpeaks(abs(Data));
    MeasuredAmplitude =  mode(abs(peaks)*2);
    if  MeasuredAmplitude < Amplitude-Amplitude*.01 || MeasuredAmplitude > Amplitude+Amplitude*.01
        error(['incorrect amplitudes for ', num2str(Amplitude)])
    end

    disp(['Completed ', num2str(Amplitude), ', measured ', num2str(MeasuredAmplitude)])

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

    if ~isempty(Data) && (numel(Data) ~= round(Duration*DefaultSampleRate) || numel(t) ~= round(Duration*DefaultSampleRate))
        error(['does not produce the correct number of sample points! Breaks at ' num2str(Duration), ' resulting in ', num2str(numel(t)), ' points'])
    end
    disp(['Completed ', num2str(Duration)])

end
disp(['Correctly sets duration'])



