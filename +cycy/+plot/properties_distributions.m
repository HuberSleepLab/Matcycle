function properties_distributions(Structure)

if isstruct(Structure)
Labels = fieldnames(Structure);
else
Labels = Structure.Properties.VariableNames;
end

Labels(contains(Labels, 'Idx')) = []; % ignore fields that are indixes
Labels(contains(Labels, 'Start')) = []; % ignore fields that are indixes
Labels(contains(Labels, 'End')) = []; % ignore fields that are indixes

FigureDimensions = [4 5];

figure('Units','normalized', 'OuterPosition', [0 0 1 1])
idxPlot = 1;
for idxLabels = 1:numel(Labels)
    if isstruct(Structure)
        Data = [Structure.(Labels{idxLabels})];
    else
    Data = Structure.(Labels{idxLabels});
    end

    if ~isnumeric(Data) && ~islogical(Data)
        continue
    end

    subplot(FigureDimensions(1), FigureDimensions(2), idxPlot)
    histogram(Data)
    title(Labels{idxLabels})

    % start a new figure if run out of plot spots
    if idxPlot == FigureDimensions(1)*FigureDimensions(2) && idxLabels<numel(Labels)
        figure('Units','normalized', 'OuterPosition', [0 0 1 1])
        idxPlot = 1;
    else
        idxPlot = idxPlot+1;
    end
end
