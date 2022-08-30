function addMatcyclePaths()
% add all folders to path so scripts can find functions


CD = mfilename('fullpath');
CD = extractBefore(CD, 'addMatcyclePaths');

% get all folders in chART folder
Subfolders = deblank(string(ls(CD))); % all content
Subfolders(contains(Subfolders, '.')) = []; % remove all files

for Indx_F = 1:numel(Subfolders)
    addpath(fullfile(CD, Subfolders{Indx_F}))
end