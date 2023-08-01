function StructMain = add_fields_to_struct(StructMain, StructNew)
% add all fields and their respective values of StructNew
% to every struct in StructMain.

Fieldnames = fieldnames(StructNew);

for n = 1:numel(StructMain)
    for Fieldname = Fieldnames'
        StructMain(n).(Fieldname{1}) = StructNew.(Fieldname{1});
    end
end

