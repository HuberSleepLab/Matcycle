function [FallingEdgeCrossings, RisingEdgeCrossings] = detect_zero_crossings(Signal)
% gets all points in which the signal goes from positive to negative values
% (falling edge zero-crossing) and from negative to positive (rising edge
% zero-crossing).
%
% Part of Matcycle 2022, by Sophia Snipes.

SignSignal = sign(Signal);

% fix edgecase where slope is exactly 0
SignSignal(SignSignal == 0) = 1;

FallingEdgeCrossings = find(diff(SignSignal) < 0);
RisingEdgeCrossings = find(diff(SignSignal) > 0);

% attributes the rising edge zero-crossing index to the right-side datapoint
RisingEdgeCrossings = RisingEdgeCrossings + 1;

% Ensure that the first index is always a falling edge zero-crossing
if RisingEdgeCrossings(1) <= FallingEdgeCrossings(1)
    RisingEdgeCrossings(1) = [];
end

% in case the last falling edge zero-crossing is not followed by a rising
% edge zero-crossing, then delete it
if length(FallingEdgeCrossings) ~= length(RisingEdgeCrossings)
    FallingEdgeCrossings(end) = [];
end