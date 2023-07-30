function [FallingEdgeMidpoints, RisingEdgeMidpoints] = cycy_detect_mipoints(NegPeaks, PosPeaks)
% identifies the falling edge midpoints and rising edge midpoints between
% peaks.
%
% Part of Matcycle 2022, by Sophia Snipes.

PeaksCount = size(NegPeaks, 2);
FallingEdgeMidpoints = nan(1, PeaksCount);
RisingEdgeMidpoints = nan(1, PeaksCount);










function 