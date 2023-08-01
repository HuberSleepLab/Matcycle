function plot_all_bursts(EEG, YGap, Bursts, ColorCode)
% function to view bursts in the EEG
% Type is either 'ICA' or 'EEG', and will appropriately plot the bursts
% over the channels or the components, accordingly.
% colorcode indicates based on which property to pick the colors.

% Part of Matcycle 2022, by Sophia Snipes.

[~, nPnts] = size(EEG.data);
t = linspace(0, nPnts/EEG.srate, nPnts);

Data = EEG.data;
DimsD = size(Data);

Y = YGap*DimsD(1):-YGap:0;
Y(end) = [];

figure('Units','normalized', 'OuterPosition',[0 0 1 1])
hold on

%%% plot EEG
Color = [.3 .3 .3];
LW = .5;

Data = Data+Y';

plot(t, Data,  'Color', Color, 'LineWidth', LW, 'HandleVisibility','off')


%%% plot bursts
if isempty(ColorCode)
    Colors = 'b';
else
    % get colors for all the types of burst

    if ischar(Bursts(1).(ColorCode))
        Groups = unique({Bursts.(ColorCode)});
    else
        Groups = unique([Bursts.(ColorCode)]);
    end

    if numel(Groups) <= 8
        Colors = getColors(numel(Groups));
    elseif numel(Groups) <= 20
        Colors = jet(numel(Groups));
    else
        Colors = rand(numel(Groups), 3);
    end

end

for Indx_B = 1:numel(Bursts)

    B = Bursts(Indx_B);

    if isfield(B, 'All_Start')
        Start = B.All_Start;
        End = B.All_End;
    else
        Start = B.Start;
        End = B.End;
    end


    Ch = B.Channel;
    if isfield(B, 'involved_ch')
        AllCh = B.involved_ch;
    elseif isfield(B, 'Coh_Burst_Channels')
        AllCh = B.Coh_Burst_Channels;
    else
        AllCh = [];
    end

    Ch(Ch>DimsD(1)) = [];

    if isempty(ColorCode)
        C  = Colors;
    else
        C = Colors(ismember(Groups, B.(ColorCode)), :); % get appropriate color, and make it slightly translucent
    end

    % plot all channels involved
    if ~isempty(AllCh)
        Burst = EEG.data(AllCh, Start:End)+Y(AllCh)';
        plot(t(Start:End), Burst', 'Color', C);
    end

    % plot main burst
    Burst = EEG.data(Ch, Start:End)+Y(Ch);
    plot(t(Start:End), Burst', 'Color', [C, .5], 'LineWidth', 2);
end


xlim(Bursts(1).Start/EEG.srate+[0 20])