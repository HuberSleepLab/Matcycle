function Bursts = localizeBursts(Bursts, ChannelGroups, Fieldname, MinPercent)
% script to quantify how lateralized a burst is on a scale of -1 to 1, with
% -1 meaning 100% on the left of the brain.
% ChannelGroups is a struct providing the channels to consider (so it can
% also be front and back, if prefered). If more than 2 groups, then it just
% assigns a category variable for which group it's mostly in. NB: the
% negative value is the group alphabetically before the other.
% Fieldname is a string with the name
% MinPercent is the minimum value for assigning a group when more than 2
% Part of Matcycle 2022, by Sophia Snipes.

Groups = fieldnames(ChannelGroups);

for Indx_B = 1:numel(Bursts)

    B = Bursts(Indx_B);

    % get average amplitude for each group
    Amplitudes = zeros(1, numel(Groups));
    for Indx_G = 1:numel(Groups)
        IDs = ismember(B.Coh_Burst_Channel_Labels, ChannelGroups.(Groups{Indx_G}));

        Amplitudes(Indx_G) = mean(B.Coh_Burst_amplitude(IDs));
    end

    % categorize
    if numel(Groups) == 2 % from -1 to 1
        Group = bilaterality(Amplitudes(1), Amplitudes(2));
    
    else
        Percentages = Amplitudes/sum(Amplitudes);
        if all(Amplitudes==0) % if burst is not in any of the groups
            Group = 'none';
        elseif exist("MinPercent", 'var') && ~isempty(MinPercent) && ~any(Percentages>MinPercent)   % if there's a minimum, make sure at least one group surpasses it
            Group = 'global';
        else % pick group with largest amplitudes
            [~, MaxID] = max(Amplitudes);
            Group = Groups(MaxID);
        end
    end

    % assign
    Bursts(Indx_B).(Fieldname) = Group;
end
end


function y = bilaterality(Amp1, Amp2)
% gives value between -1 and 1 such that if Amp2 is 0, then y = -1, and
% viceversa if Amp1 is 0 then y = 1. Any intermediate value reflects the
% relative amplitudes of the two groups.

y = (Amp2-Amp1)/(Amp1+Amp2);

end