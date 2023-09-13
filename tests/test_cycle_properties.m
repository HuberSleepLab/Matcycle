% TODO: test for properties: values should be in certain ranges, so plot
% their distribution, and give test problem (eventually) if they're outside
% of range


Properties = fieldnames(AugmentedCycles);

for Property = Properties'
    figure
    histogram([AugmentedCycles.(Property{1})])
title(Property)

end