function ThisObj = makeUniqueNames(ThisObj)
% Make names unique
if isprop(ThisObj,'Name')
    UniqueNames = matlab.lang.makeUniqueStrings({ThisObj.Name});
    if ~isequal(UniqueNames,{ThisObj.Name})
        for index = 1:numel(ThisObj)
            ThisObj(index).Name = UniqueNames{index};
        end
    end
end
