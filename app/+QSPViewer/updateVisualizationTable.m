function [OutTable,OutTableWithInvalids,InvalidRowIndices] = updateVisualizationTable(InTable,InFullTable,InvalidRowIndices,KeyIndex)

if islogical(InvalidRowIndices)
    InvalidRowIndices = find(InvalidRowIndices);
end

% TODO: Handle the case where T1 was renamed, removed, and added back
OutTable = InFullTable; 

% Update OutTable according to InTable
for index = 1:size(OutTable,1)
    MatchRow = true(size(InTable,1),1);
    for kIndex = KeyIndex
        % Find this row in the previous table (InTable)
        MatchRow = MatchRow & strcmp(OutTable{index,kIndex},InTable(:,kIndex));
    end
    MatchRow = find(MatchRow);
    
    if ~isempty(MatchRow)
        % TODO:
        % Take the first match
        MatchRow = MatchRow(1);
        % Update the NewPlotTable
        if size(OutTable,2) < size(InTable,2)
            OutTable(:,(end+1):(end+(size(InTable,2)-size(OutTable,2)))) = {''};
        end
        OutTable(index,:) = InTable(MatchRow,:);
    end
end

%% OutTable and OutTableWithInvalids - first pass to mark invalid

% Go through each row of InFullTable (OutTable). If a row is marked as invalid and it
% does not exist in InTable, delete it. Otherwise, if it's invalid and
% exists in InTable, mark as invalid
OutTableWithInvalids = OutTable;
DeleteRowIndices = [];
if ~isempty(InvalidRowIndices)
    % If this row is invalid
    for index = InvalidRowIndices(:)'        
        % Check to see if the row is missing from InTable
        MissingRow = false;
        for kIndex = KeyIndex
            MissingRow = MissingRow | ~ismember(OutTable(index,kIndex),InTable(:,kIndex));
        end
        % If it's missing, then delete it
        if MissingRow
            % Mark for deletion
%             DeleteRowIndices = [DeleteRowIndices index]; %#ok<AGROW>
        else
            % Mark row as invalid
            for kIndex = KeyIndex
                OutTableWithInvalids{index,kIndex} = QSP.makeInvalid(OutTableWithInvalids{index,kIndex});
            end
        end % Else, leave as is to mark as invalid
    end
end

% Delete the appropriate rows
OutTable(DeleteRowIndices,:) = [];
OutTableWithInvalids(DeleteRowIndices,:) = [];

%% Next, append all in InTable that don't exist in InFullTable (OutTable) 

InvalidRowsFromInTable = [];
for index = 1:size(InTable,1)
    MissingRow = false;
    for kIndex = KeyIndex
        if iscell(InTable(index,kIndex)) && isempty(InTable{index,kIndex})
            continue
        end
        MissingRow = MissingRow | ~ismember(InTable(index,kIndex),OutTable(:,kIndex));
    end
    if all(MissingRow)
        InvalidRowsFromInTable = [InvalidRowsFromInTable; InTable(index,:)]; %#ok<AGROW>
    end    
end

% Append
NumPrevRows = size(OutTable,1);
OutTable = [OutTable;InvalidRowsFromInTable];
OutTableWithInvalids = [OutTableWithInvalids;InvalidRowsFromInTable];

% Next, mark as invalid and update InvalidRowIndices
InvalidRowsFromInTableIndices = (NumPrevRows+1):size(OutTable,1);
if ~isempty(InvalidRowsFromInTableIndices)
    for index = InvalidRowsFromInTableIndices
        for kIndex = KeyIndex            
            OutTableWithInvalids{index,kIndex} = QSP.makeInvalid(OutTableWithInvalids{index,kIndex});
        end
    end
    InvalidRowIndices = unique([InvalidRowIndices(:)' InvalidRowsFromInTableIndices]);
end


%% Update InvalidRowIndices (remove DeleteRowIndices)

InvalidRowIndices = setdiff(InvalidRowIndices,DeleteRowIndices);


