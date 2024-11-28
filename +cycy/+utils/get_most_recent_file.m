function Filename = get_most_recent_file(Folder, Extension)
% Provide a folder and an extension, and this will return the most recently
% created file with that extension in that folder.

Content = dir(Folder);

Filenames = {Content.name};
Content(~contains(Filenames, Extension)) = [];

if isempty(Content)
    warning(['No files with ', Extension, ' extension in ', Folder])
    Filename = [];
    return
end

Timestamps = [Content.datenum];
[~, Order] = sort(Timestamps, 'descend');

Filename = Content(Order(1)).name;
