function [RisingEdgeCrossings, FallingEdgeCrossings] = detect_zero_crossings(Signal)
% finds all the timepoints in which the signal goes from positive to 
% negative (falling edge zero-crossing) and from negative to positive
% (rising edge zero-crossing).
% Ensures that the first rising edge zero-crossing comes at an earlier
% timepoint than the first falling-edge zero-crossing (ensures that the 
% sequence starts with a positive cycle).
% Part of Matcycle 2022, by Sophia Snipes.

[RisingEdgeCrossings, FallingEdgeCrossings] = detect_crossings(Signal, 0);

% Ensure that the first index is always a rising edge zero-crossing
if RisingEdgeCrossings(1) > FallingEdgeCrossings(1)
    FallingEdgeCrossings(1) = [];
elseif RisingEdgeCrossings(1) == FallingEdgeCrossings(1)
    FallingEdgeCrossings(1) = FallingEdgeCrossings(1)+1;

end

% Ensure that the last index is always a falling edge zero-crossing
RisingEdgeCrossings = RisingEdgeCrossings(1:length(FallingEdgeCrossings));
