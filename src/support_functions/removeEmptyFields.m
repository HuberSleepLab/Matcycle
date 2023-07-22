function Struct = removeEmptyFields(Struct)
% removes empty fields

Fieldnames  = fieldnames(Struct);

for Indx_F = 1:numel(Fieldnames)
    if isempty(Struct.(Fieldnames{Indx_F}))
        Struct = rmfield(Struct, Fieldnames{Indx_F});
    end
end
