function Bursts = localizeBursts(Bursts, ChannelGroups)
% script to quantify how lateralized a burst is on a scale of -1 to 1, with
% -1 meaning 100% on the left of the brain.
% ChannelGroups is a struct providing the channels to consider (so it can
% also be front and back, if prefered). If more than 2 groups, then it just
% assigns a category variable for which group it's mostly in.
% Part of Matcycle 2022, by Sophia Snipes.

Groups = fieldnames(ChannelGroups);

for Indx_B = 1:numel(Bursts)

    B = Bursts(Indx_B);

    % get average amplitude for each group
    Amplitudes = zeros(1, numel(Groups));
    for Indx_G = 1:numel(Groups)
        IDs = ismember(B.Coh_Channel_Label, ChannelGroups.(Groups{Indx_G}));
        Amplitudes(Indx_G) = mean(B.Coh_Mean_amplitude(IDs));
    end

    % categorize
    if numel(Groups) == 2
        
    else
        [~, MaxID] = max(Amplitudes);
        Bursts(Indx_B) = Groups(MaxID);
    end
end