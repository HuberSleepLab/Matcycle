function Struct = cat_structs(Struct1, Struct2)
% Performs "cat" on structures, but also works for empty structs.
%
% Part of Matcycle 2022, by Sophia Snipes.

if (isempty(Struct1) || numel(fieldnames(Struct1)) == 0) && (isempty(Struct2) || numel(fieldnames(Struct2)) == 0)
    Struct = struct();
elseif isempty(Struct1) || numel(fieldnames(Struct1)) == 0
    Struct = Struct2;
elseif isempty(Struct2) || numel(fieldnames(Struct2)) == 0
    Struct = Struct1;
else
    Struct = cat(2, Struct1, Struct2);
end