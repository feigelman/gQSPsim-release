function [Header, Data, StatusOK, Message] = xlread(filepath)
StatusOK = true;
Message = '';
Header = {};
Data = {};

try
    data = readtable(filepath);
catch error
    Message = error.message;
    return
end

Header = data.Properties.VariableNames;
if ~isempty(data.Properties.VariableDescriptions)
    idxConverted = arrayfun(@(k) ~isempty(data.Properties.VariableDescriptions{k}), 1:size(data,2));

    for k = find(idxConverted)
        tmp = regexp(data.Properties.VariableDescriptions{k}, 'Original column heading: ''(.*)''', 'tokens');
        Header{k} = tmp{1}{1};
    end
end

try
Data = table2cell(data);
catch error
    warning(error.message)
end
    
    
