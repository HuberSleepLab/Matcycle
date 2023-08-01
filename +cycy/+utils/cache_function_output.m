function Output = cache_function_output(Function, varargin)
% runs a function, saves the output on disk, and next time the function
% is run, if there's something on disk, it just uses that instead of
% running the function again. Use for slow functions like designfilt.
% Example: Output = cycy.utils.cache_function_output(@sum, [1 2 3]);
% Part of Matcycle 2022, by Sophia Snipes.

StringInput = string_all_input(Function, varargin{:});

CacheDir = fullfile(cd, 'cycy.cache_dont_add_to_git'); % 
CachePath = fullfile(CacheDir, [StringInput, '.mat']);

if exist(CachePath, 'file')
    load(CachePath, 'Output')
    return
elseif ~exist(CacheDir, 'dir')
    mkdir(CacheDir)
end

% run function with all its inputs
disp(['Running ', func2str(Function), '...'])
Output = Function(varargin{:});

% save to cache
save(CachePath, 'Output')

end



function StringInput = string_all_input(Function, varargin)
% strings together all the inputs, so that it gets saved in a filename

StringInput = {func2str(Function)};
for Indx_V = 1:numel(varargin)

    Item = varargin{Indx_V};
    if isnumeric(Item)
        Item = string(Item);
    end

    StringInput = cat(2, StringInput, Item);
end

StringInput = char(strjoin(StringInput, '_'));
StringInput = replace(StringInput, '.', '-');

end