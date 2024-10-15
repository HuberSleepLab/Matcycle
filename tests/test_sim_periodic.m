% simulate_periodic_eeg should create a vector of a specified length, of
% which a certain proportion should contain a sine wave of specified
% periodicity, with bursts a certain length.


DefaultCenterFrequency = 10;
DefaultBurstAmplitude = 30;
DefaultBurstDensity = .4;
DefaultBurstDuration = 1;
DefaultDuration = 60;
DefaultSampleRate = 200;
Plot = false;



%% test center frequency (and that values are reasonable)

CenterFrequencies = [0 .1 1 10 100 1000];

for CF = CenterFrequencies


end





%% test duration

clc

Durations = [nan 0 .01 .1 1 10 100 1000 10000];

for Duration = Durations
    [Data, t] = cycy.sim.simulate_periodic_eeg( ...
        DefaultCenterFrequency, ...
        DefaultBurstAmplitude, ...
        DefaultBurstDensity, ...
        DefaultBurstDuration, ...
        Duration, ...
        DefaultSampleRate, ...
        Plot);

    if ~isempty(Data) && (numel(Data) ~= Duration*DefaultSampleRate || numel(t) ~= Duration*DefaultSampleRate)
        error(['does not produce the correct number of sample points! Breaks at ' num2str(Duration), ' resulting in ', num2str(numel(t)), ' points'])
    end

end
disp(['Correctly sets duration!'])


%% test everything against everything?
