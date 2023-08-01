function Bursts = classify_bursts_shape(Bursts)
% categorizes bursts based on their average shape
% Types: Sw = sawtooth, Mu = mu wave, NM = notched mu, Sq = square, Tr =
% triangle, Sn = sinusoid
% Part of Matcycle 2022, by Sophia Snipes.

DRSYM_Threshold = .15; % this is deviation from .5
TPSYM_Threshold = .1;
Square_Threshold = .3; % 0 is perfect square
Triangle_Threshold = .9; % 1 is perfect triangle (sine is around 73%)

for Indx_B = 1:numel(Bursts)

    B = Bursts(Indx_B);

    DRSYM = mean(B.drsym);
    TPSYM = mean(B.tpsym);
    Roundiness = mean(B.roundiness);


    % check if decay/rise symmetry is such to count as a sawtooth wave
    if DRSYM >= 0.5+DRSYM_Threshold || DRSYM <= 0.5-DRSYM_Threshold
        Bursts(Indx_B).Type = 'Sw';
        continue
    end

    % check if trough-peak symmetry is such to count as a mu wave
    if TPSYM >= 0.5+TPSYM_Threshold || TPSYM <= 0.5-TPSYM_Threshold
        if mean(B.nExtraPeaks) > 1 % if there's notches, then its a notched mu wave
            Bursts(Indx_B).Type = 'NM';
            continue
        else
            Bursts(Indx_B).Type = 'Mu';
            continue
        end
    end

    % check if roundedness is such as to count as either a square or
    % triangle wave. Otherwise, it's just a sine.
    if Roundiness < Square_Threshold
        Bursts(Indx_B).Type = 'Sq';
    elseif Roundiness > Triangle_Threshold
        Bursts(Indx_B).Type = 'Tr';
    else
        Bursts(Indx_B).Type = 'Sn';
    end
end