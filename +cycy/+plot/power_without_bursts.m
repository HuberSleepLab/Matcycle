function power_without_bursts(DataBroadband, SampleRate, Bursts, CleanTimepoints)
arguments
DataBroadband
SampleRate
Bursts
CleanTimepoints = ones(size(DataBroadband));
end

DataBroadband(CleanTimepoints) = nan;

% plot power spectrum of channel
[PowerBroadband, Frequencies] = cycy.utils.compute_power(DataBroadband, SampleRate);
hold on
cycy.plot.power_spectrum(PowerBroadband, Frequencies, true, true, [], [0 0 0]);


% plot spectrum after removing bursts
BurstStarts = [Bursts.Start];
BurstEnds = [Bursts.End];

isBurst = false(size(DataBroadband));
for idxBurst = 1:numel(BurstStarts)
    isBurst(BurstStarts(idxBurst):BurstEnds(idxBurst)) = 1;
end

DataBurst = DataBroadband(isBurst);
[PowerBroadband, Frequencies] = cycy.utils.compute_power(DataBurst, SampleRate);
hold on
cycy.plot.power_spectrum(PowerBroadband, Frequencies, true, true, [], cycy.utils.pick_colors(1, '', 'blue'));


DataBurstless = DataBroadband(~isBurst);
[PowerBroadband, Frequencies] = cycy.utils.compute_power(DataBurstless, SampleRate);
hold on
cycy.plot.power_spectrum(PowerBroadband, Frequencies, true, true, [], cycy.utils.pick_colors(1, '', 'red'));




disp(['Bursts occupied ', num2str(round(100*nnz(isBurst)/numel(isBurst))), '% of the EEG'])

% TODO: apply to larger dataset: multi channels; multi participants
