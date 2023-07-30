function [FallingEdgeZeroCrossing, RisingEdgeZeroCrossing] = detect_zero_crossings(Signal)
% gets all points in which the signal does from positive to negative (down
% zero crossing) and from negative to positive (up zero crossing)

% get when signal positive and negative
signData = sign(Signal);

% fix rare issue where slope is exactly 0
signData(signData == 0) = 1;

% -2 indicates when the sign goes from 1 to -1
FallingEdgeZeroCrossing = find(diff(signData) < 0);
RisingEdgeZeroCrossing = find(diff(signData) > 0);

RisingEdgeZeroCrossing = RisingEdgeZeroCrossing + 1;

% Check for earlier initial UZC than DZC
if RisingEdgeZeroCrossing(1) <= FallingEdgeZeroCrossing(1)
    RisingEdgeZeroCrossing(1)=[];
end

% in case the last DZC does not have a corresponding UZC then delete it
if length(FallingEdgeZeroCrossing) ~= length(RisingEdgeZeroCrossing)
    FallingEdgeZeroCrossing(end)=[];
end