function Labels = indexes2labels(Indexes, Chanlocs)
% outputs channel indices based on chanlocs labels

AllLabels =  string({Chanlocs.labels});
AllLabels(strcmpi(AllLabels, 'CZ')) = "129";
Labels = AllLabels(Indexes);

Labels = str2double(Labels);