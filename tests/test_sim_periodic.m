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

WeirdInputs = [nan 0 .01 .1 1.3333, 10 19.33333, 10.334566, pi, DefaultBurstDuration, DefaultDuration, 100 1000 10000, inf];


%% Test_CenterFrequency
clc

CenterFrequencies = WeirdInputs;
DefaultSampleRate = 200;
CenterFrequencies= 5:5:200;

MF = nan(size(CenterFrequencies));

Idx =0;
for CF = CenterFrequencies
    Idx = Idx+1;

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

    % identify all the sine wave peaks
    Data2 = Data;
    Data2([diff(Data)==0 false]) = nan;
    [peak, locs] = findpeaks(abs(Data2), t);
    remove = round(peak)~=max(round(peak)); % select only the max peaks, which correspond to the sine's tops
    locs(remove) = [];

    MeasuredFrequency = 1/(mode(diff(locs))*2);
    % MF(Idx) = MeasuredFrequency;

    % if MeasuredFrequency < CF-CF*.05 || MeasuredFrequency > CF+ CF*.05
    %     error(['Incorrect center frequency for ', num2str(CF)])
    % end
        disp(['Completed ', num2str(CF), ', achieved ', num2str(MeasuredFrequency)])

        [Power, Freqs] = cycy.utils.compute_power(Data, DefaultSampleRate, 10, .5);
        [~, peakIdx] = max(Power);

        MF(Idx) = Freqs(peakIdx);

    % if ~isempty(Data)
    %     error(['Incorrect burst frequency for center frequency of ', num2str(CF)])
    % end
end

disp(['Correctly handles center frequencies'])




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

