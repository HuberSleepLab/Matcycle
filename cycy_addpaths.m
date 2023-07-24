function cycy_addpaths()
% add all folders to path so scripts can find functions


CD = mfilename('fullpath');
CD = extractBefore(CD, 'cycy_addpaths');

% get all folders in matcyle directory
Subfolders = deblank(string(ls(fullfile(CD, 'src')))); % all content
Subfolders(contains(Subfolders, '.')) = []; % remove all files
Subfolders(contains(Subfolders, 'private')) = []; % remove private folder

for Indx_F = 1:numel(Subfolders)
    addpath(fullfile(CD, 'src', Subfolders{Indx_F}))
end