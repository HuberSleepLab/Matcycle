function properties_distributions(Structure)

Labels = fieldnames(Structure);
Labels(contains(Labels, 'Idx')) = []; % ignore fields that are indixes
Labels(contains(Labels, 'Start')) = []; % ignore fields that are indixes
Labels(contains(Labels, 'End')) = []; % ignore fields that are indixes

FigureDimensions = [4 5];

figure('Units','normalized', 'OuterPosition', [0 0 1 1])
idxPlot = 1;
for idxLabels = 1:numel(Labels)
    Data = [Structure.(Labels{idxLabels})];

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
