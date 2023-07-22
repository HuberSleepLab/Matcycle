function Struct = catStruct(Struct1, Struct2)
% concatente structs, also when potentially empty.

% Part of Matcycle 2022, by Sophia Snipes.

if numel(fieldnames(Struct1)) == 0 || isempty(Struct1)
    Struct = Struct2;
elseif numel(fieldnames(Struct2)) == 0 || isempty(Struct2)
    Struct = Struct1;
else
    Struct = cat(2, Struct1, Struct2);
end



