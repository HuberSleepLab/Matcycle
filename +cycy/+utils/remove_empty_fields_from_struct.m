function Struct = remove_empty_fields_from_struct(Struct)
% removes empty fields

Fieldnames  = fieldnames(Struct);

for Indx_F = 1:numel(Fieldnames)
    if isempty(Struct.(Fieldnames{Indx_F}))
        Struct = rmfield(Struct, Fieldnames{Indx_F});
    end
end
end