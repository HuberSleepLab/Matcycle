function [DZC, UZC] = getZC(Signal)
% gets all points in which the signal does from positive to negative (down
% zero crossing) and from negative to positive (up zero crossing)

% get when signal positive and negative
signData = sign(Signal);

% fix rare issue where slope is exactly 0
signData(signData == 0) = 1;

% -2 indicates when the sign goes from 1 to -1
DZC = find(diff(signData) < 0);
UZC = find(diff(signData) > 0);

UZC = UZC + 1;

% Check for earlier initial UZC than DZC
if UZC(1) <= DZC(1)
    UZC(1)=[];
end

% in case the last DZC does not have a corresponding UZC then delete it
if length(DZC) ~= length(UZC)
    DZC(end)=[];
end