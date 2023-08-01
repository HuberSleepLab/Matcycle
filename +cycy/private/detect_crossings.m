function [RisingEdgeCrossings, FallingEdgeCrossings] = detect_crossings(Signal, CrossingValue)
% finds all the timepoints in which the signal goes:
% - from greater than CrossingValue to less than CrossingValue (falling edge crossing) 
% - and from less than CrossingValue to greater than CrossingValue (rising edge crossing).

SignSignal = sign(Signal - CrossingValue);

% fix edgecase where slope is exactly 0
SignSignal(SignSignal == 0) = 1;

FallingEdgeCrossings = find(diff(SignSignal) < 0);
RisingEdgeCrossings = find(diff(SignSignal) > 0);

% attributes the rising edge zero-crossing index to the right-side datapoint
RisingEdgeCrossings = RisingEdgeCrossings + 1;