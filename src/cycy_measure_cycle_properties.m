function Cycles = cycy_measure_cycle_properties(ChannelBroadband, Cycles, SampleRate)
% Identifies various ways to characterize each peak. Based on Cole 2019,
% but relative to the negative peaks rather than positive peaks.
% NOTE: all fieldnames should start lowercase, so I know later on that they
% come from here.

% Part of Matcycle 2022, by Sophia Snipes.

for n = 2:numel(Cycles)-1
    P = Cycles(n);
    PrevP = Cycles(n-1);

    NextP = Cycles(n+1);

    if min(ChannelBroadband(P.MidFallingIdx:P.MidRisingIdx)) < ChannelBroadband(P.NegPeakIdx) ...
            || P.NegPeakIdx == P.MidRisingIdx || P.NegPeakIdx == P.MidFallingIdx % if peak coincided with edges of zero-crossings
        Cycles(n).truePeak = 0;
    else
        Cycles(n).truePeak = 1;
    end

    Cycles(n).voltageNeg = ChannelBroadband(P.NegPeakIdx);
    Cycles(n).voltagePos = ChannelBroadband(P.PosPeakIdx);

    % periods
    Cycles(n).periodNeg = 2*(P.MidRisingIdx - P.MidFallingIdx)/SampleRate;
    Cycles(n).periodPos = 2*(P.NextMidDownID - P.MidRisingIdx)/SampleRate;

    % Prominance as boolean on whether there are any midpoint crossings
    % between the current peak's midpoint, and the previous one's.
    halfWave = ChannelBroadband(PrevP.MidRisingIdx:P.MidFallingIdx-1);
    nCrossingsPre = nnz(diff(sign(halfWave-ChannelBroadband(P.MidFallingIdx))));

    halfWave = ChannelBroadband(P.MidRisingIdx+1:NextP.MidFallingIdx);
    nCrossingsPost = nnz(diff(sign(halfWave-ChannelBroadband(P.MidRisingIdx))));

    if nCrossingsPre > 1 || nCrossingsPost > 1
        %  if nCrossingsPre > 1 && nCrossingsPost > 1
        Cycles(n).isProminent = 0;
    else
        Cycles(n).isProminent = 1;
    end


    % Amplitude as average between distance to positive peaks surrounding
    % this negative peak.
    decay_amp = ChannelBroadband(P.PrevPosPeakID) - ChannelBroadband(P.NegPeakIdx);
    rise_amp = ChannelBroadband(P.PosPeakIdx) - ChannelBroadband(P.NegPeakIdx);
    Cycles(n).amplitude = (rise_amp + decay_amp)/2;

    % get direction of amplitude change
    if decay_amp > rise_amp % going down
        Cycles(n).ampRamp = -1;
    elseif decay_amp < rise_amp % going up
        Cycles(n).ampRamp = 1;
    else
        Cycles(n).ampRamp = 0; % magic case of exactly the same
    end

    % efficiency in amplitude; indication of how much the signal goes in the "wrong"
    % direction. 0 means the signal went in the opposite direction it
    % should have for the whole amplitude. It basically doubled back. Also
    % includes part when signal "overshoots".

    % monotonicity (degree to which both flanks go in the correct
    % direction) in time
    [Cycles(n).efficiency, Cycles(n).monotonicity, Cycles(n).monDecay, Cycles(n).monRise] = ...
        flankInfo(ChannelBroadband, P.PrevPosPeakID, P.NegPeakIdx, P.PosPeakIdx);



    % amplitude consistency (difference in amplitudes) NB: in Cole, they
    % look at adjacent cycles for this; I am trying just within
    % oscillation.
    Cycles(n).flankConsistency = min(rise_amp/decay_amp, decay_amp/rise_amp);
end


%%% comparing cycles to each other
for n = 2:numel(Cycles)-1

    % period consistency (fraction of previous peak to next peak)
    P1 = Cycles(n).NegPeakIdx-Cycles(n-1).NegPeakIdx;
    P2 = Cycles(n+1).NegPeakIdx-Cycles(n).NegPeakIdx;


    if isempty(P1)
        P1 = 0;
    end

    Cycles(n).periodConsistency = min([P1/P2, P2/P1]); % take most extreme difference

    % get period as distance between neighboring peaks
    Cycles(n).period = mean([P1, P2])/SampleRate;

    % mean period consistency across peaks, zero crossings, and trough
    PP = periodConsistency(Cycles(n-1), Cycles(n), Cycles(n+1), 'periodPos');
    PN = periodConsistency(Cycles(n-1), Cycles(n), Cycles(n+1), 'periodNeg');
    Cycles(n).periodMeanConsistency = (PP+PN)/2;

    % amplitude consistency
    A1 = Cycles(n-1).amplitude;
    A2 = Cycles(n).amplitude;
    A3 = Cycles(n+1).amplitude;
    if isempty(A1)
        A1 = 0;
    end

    if isempty(A3)
        A3 = 0;
    end

    A = mean([A1, A3]); % use mean so that if ramps, its not inconsistent amp
    Cycles(n).ampConsistency = min([A/A2, A2/A]);
%     Peaks(n).ampConsistency = min([A1/A2, A2/A3, A2/A1, A3/A2]);

    % count number of extra negative peak and next peak
    halfWave = ChannelBroadband(Cycles(n).MidRisingIdx:Cycles(n).NextMidDownID);
    Cycles(n).nExtraPeaks = nnz(diff(sign(diff(halfWave))) > 1);

    % get efficiency relative to closest positive peaks. Pominence is the
    % ampplitude relative to the closest deflections
    if Cycles(n).nExtraPeaks > 0 && ~isempty(Cycles(n-1).nExtraPeaks) && Cycles(n-1).nExtraPeaks > 0
        [Cycles(n).prominence, Cycles(n).efficiencyAdj] = adjustPositivePeaks(ChannelBroadband, ...
            Cycles(n-1).PosPeakIdx, Cycles(n).MidFallingIdx, Cycles(n).NegPeakIdx, Cycles(n).MidRisingIdx, Cycles(n).PosPeakIdx);
    else
        Cycles(n).efficiencyAdj = Cycles(n).efficiency;
        Cycles(n).prominence = Cycles(n).amplitude;
    end
end

% remove edge peaks that are empty
Cycles([1 end]) = [];

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% specific functions


function [efficiency, monotonicity, mon_decay, mon_rise] = flankInfo(Wave, PrevPos, Neg, Pos)
% calculate efficiency of signal between 3 points (assuming a negative
% wave)

% first derivative of flanks of peak
decay = diff(Wave(PrevPos:Neg));
rise = diff(Wave(Neg:Pos));

% efficiency
maxdecay = Wave(PrevPos) - Wave(Neg);
decay_efficiency = (maxdecay - sum(abs(decay(decay>0))))/maxdecay;

maxrise = Wave(Pos) - Wave(Neg);
rise_efficiency = (maxrise-sum(abs(rise(rise<0))))/maxrise;

efficiency = min(decay_efficiency, rise_efficiency);
if efficiency <= 0
    efficiency = 0;
end

% monotonicity
mon_decay = nnz(decay<0)/numel(decay);
mon_rise = nnz(rise>0)/numel(rise);

monotonicity = min(mon_decay, mon_rise);
if numel(decay) < 2 || numel(rise) < 2 % if not enough datapoints
    monotonicity = 0;
    mon_decay = 0;
    mon_rise = 0;
end
end


function [adjamplitude, adjefficiency] = adjustPositivePeaks(Wave, PrevPos, MidDown, Neg, MidUp, Pos)
% adjusts amplitude based on closest positive peak after midpoint rather
% than absolute positive peak.
% adjusts efficiency to look at ratio of distance to closest positive peaks
% relative to highest positive peak. Important for cases with notched
% waves.

% do down flank
decay = Wave(PrevPos:MidDown);
decayPeak = find(diff(sign(diff(decay)))<0, 1, 'last');
if isempty(decayPeak)
    decayPeak = 1;
end
decayAmp_new = decay(decayPeak) - Wave(Neg);
decayAmp = decay(1) - Wave(Neg);

% do up flank
rise = Wave(MidUp:Pos);
risePeak = find(diff(sign(diff(rise)))<0, 1, 'first');
if isempty(risePeak)
    risePeak = numel(rise);
end
riseAmp_new = rise(risePeak) - Wave(Neg);
riseAmp = rise(end)-Wave(Neg);

% combined values
adjamplitude = (decayAmp_new+riseAmp_new)/2;
% adjefficiency = (riseAmp_new/riseAmp+decayAmp_new/decayAmp)/2;
adjefficiency = min(riseAmp_new/riseAmp, decayAmp_new/decayAmp);

if adjefficiency > 1
    adjefficiency = 1;
elseif adjefficiency < 0
    adjefficiency = 0;
end

end



function PC = periodConsistency(P1, P2, P3, Type)
% gets the period consistency from neighboring period calculations

if isempty(P1.(Type)) || isempty(P2.(Type)) || isempty(P3.(Type))
    PC = nan;
    return
end

PC = min([P1.(Type)/P2.(Type), P2.(Type)/P1.(Type), ...
    P2.(Type)/P2.(Type), P3.(Type)/P2.(Type)]);
end