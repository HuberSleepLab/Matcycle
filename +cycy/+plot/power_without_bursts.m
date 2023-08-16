function power_without_bursts(DataBroadband, SampleRate, Bursts)


% plot power spectrum of channel
[PowerBroadband, Frequencies] = cycy.utils.compute_power(DataBroadband, SampleRate);
hold on
cycy.plot.power_spectrum(PowerBroadband, Frequencies, true, true, [], cycy.utils.pick_colors(1, '', 'blue'));


% plot spectrum after removing bursts
BurstStarts = [Bursts.Start];
BurstEnds = [Bursts.End];

Remove = zeros(size(DataBroadband));
for idxBurst = 1:numel(BurstStarts)
    Remove(BurstStarts(idxBurst):BurstEnds(idxBurst)) = 1;
end

DataBurstless = DataBroadband(~Remove);

[PowerBroadband, Frequencies] = cycy.utils.compute_power(DataBurstless, SampleRate);
hold on
cycy.plot.power_spectrum(PowerBroadband, Frequencies, true, true, [], cycy.utils.pick_colors(1, '', 'red'));

disp(['Bursts occupied ', num2str(round(100*nnz(Remove)/numel(Remove))), '% of the EEG'])

% TODO: apply to larger dataset: multi channels; multi participants
