function Bursts = burst_shape_properties(Bursts, EEG)
% Gets all the information about the peaks in the burst that are not used
% to determine the bursts in the first place
% Part of Matcycle 2022, by Sophia Snipes.

fs = EEG.srate;

for Indx_B = 1:numel(Bursts)

    B = Bursts(Indx_B);
    Wave = B.Sign*EEG.data(B.Channel, :);

    % decay-rise symmetry (fraction of the halfperiod that is compsed of the
    % down slope)
    Bursts(Indx_B).drsym = getDRSYM(B.MidFallingIdx, B.NegPeakIdx, B.MidRisingIdx);


    % positive and negative slopes (in miV/s) from midpoints
    [Bursts(Indx_B).slopeDecay, Bursts(Indx_B).slopeRise] = getSlopes(Wave, fs, ...
        B.MidFallingIdx, B.NegPeakIdx, B.MidRisingIdx); % TOCHECK if this works with multiple peaks

    % period based on positive peaks' distance
    rise_period = B.PosPeakIdx - B.NegPeakIdx;
    decay_period = B.NegPeakIdx - B.PrevPosPeakID;
    Bursts(Indx_B).periodPeakPos = (rise_period+decay_period)/fs;

    % trough-peak symmetry
    Bursts(Indx_B).tpsym = getTPSYM(B.MidFallingIdx, B.MidRisingIdx, B.NextMidDownID);

    % get degree of roundedness of the peak
    Bursts(Indx_B).roundinessNeg = getRoundiness(Wave, B.MidFallingIdx, B.NegPeakIdx, ...
        B.MidRisingIdx);
    Bursts(Indx_B).roundinessPos = getRoundiness(-Wave, B.MidRisingIdx, B.PosPeakIdx, ...
        B.NextMidDownID);

    Bursts(Indx_B).roundiness = (Bursts(Indx_B).roundinessNeg+Bursts(Indx_B).roundinessPos)/2;
end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% sub functions

function drsym = getDRSYM(MidDownID, NegPeakID, MidUpID)
% decay-rise symmetry (fraction of the halfperiod that is compsed of the
% down slope)

rise_periods = MidUpID - NegPeakID;
decay_periods = NegPeakID - MidDownID;
drsym = decay_periods./(decay_periods+rise_periods);
end


function tpsym = getTPSYM(MidDownID, MidUpID, NextMidDownID)
% trough-peak symmetry (fraction of negative peaks' Midpoint and
% previous' positive peak.
trough_period = MidUpID - MidDownID;
peak_period = NextMidDownID - MidUpID;
tpsym = trough_period./(trough_period+peak_period);
end


function [decay_slope, rise_slope] = getSlopes(Wave, fs, P1, P2, P3)
% get slopes in radians based on three adjacent points

% handle edge case
if P3 > numel(Wave)
    decay_slope = nan;
    rise_slope = nan;
    return
end

decay_period = (P2-P1)/fs;
rise_period = (P3-P2)/fs;

decay_amp = Wave(P1) - Wave(P2);
rise_amp = Wave(P3) - Wave(P2);

% basic trigonometry I had to google
decay_slope = abs(atan(decay_period./decay_amp));
rise_slope = abs(atan(rise_period./rise_amp));
end



function roundiness = getRoundiness(Wave, P1, P2, P3)
% roundiness is the deviation from perfect triangleness. Assumes a negative
% peak.

roundiness = nan(1, numel(P1));

for Indx_R = 1:numel(P1)
    decay_roundiness = getHalfRoundiness(-Wave(P1:P2));
    rise_roundiness = getHalfRoundiness(-Wave(P2:P3));

    roundiness(Indx_R) = (rise_roundiness+decay_roundiness)/2;
end
end

function halfroundiness = getHalfRoundiness(halfWave)
% Does each half of roundiness. Assumes a positive peak. 0 is perfectly
% square, 1 is perfectly triangular.

h = abs(halfWave(end)-halfWave(1));
w = numel(halfWave);

% identify the shortest line between the edges of the half wave
line = linspace(halfWave(1), halfWave(end), w);

% identify the amount of area that deviates from this short line
curve = sum(abs(halfWave-line));

% identify the area of a potential square, the "longest" deviation
area = (h*w)/2;

% quantify roundiness as the % of area moving away from the shortest path.
halfroundiness = (area - curve)./area;
end


% TODO rename and check