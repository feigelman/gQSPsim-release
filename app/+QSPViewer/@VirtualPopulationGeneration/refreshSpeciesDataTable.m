function refreshSpeciesDataTable(vObj)


%% Refresh Table

if ~isempty(vObj.TempData)
    SpeciesNames = {vObj.TempData.SpeciesData.SpeciesName};
    DataNames = {vObj.TempData.SpeciesData.DataName};
    FunctionExpressions = {vObj.TempData.SpeciesData.FunctionExpression};
    
    % Get the selected tasks based on Optim Items
    ItemTaskNames = {vObj.TempData.Item.TaskName};
    ValidSelectedTasks = getValidSelectedTasks(vObj.TempData.Settings,ItemTaskNames);
    
    NumTasksPerSpecies = zeros(size(SpeciesNames));
    for iSpecies = 1:numel(SpeciesNames)
        for iTask = 1:numel(ValidSelectedTasks)
            if any(strcmpi(SpeciesNames{iSpecies},ValidSelectedTasks(iTask).SpeciesNames))
                NumTasksPerSpecies(iSpecies) = NumTasksPerSpecies(iSpecies) + 1;
            end
        end
    end
    
    Data = [DataNames(:) SpeciesNames(:) num2cell(NumTasksPerSpecies(:)) FunctionExpressions(:)];
    
    % Mark any invalid entries
    if ~isempty(Data)
        % Species
        MatchIdx = find(~ismember(SpeciesNames(:),vObj.SpeciesPopupTableItems(:)));
        for index = 1:numel(MatchIdx)
            Data{MatchIdx(index),2} = QSP.makeInvalid(Data{MatchIdx(index),1});
        end
        % Data
        MatchIdx = find(~ismember(DataNames(:),vObj.DatasetDataColumn(:)));
        for index = 1:numel(MatchIdx)
            Data{MatchIdx(index),1} = QSP.makeInvalid(Data{MatchIdx(index),4});
        end        
    end
else
    Data = {};
end
set(vObj.h.SpeciesDataTable,'Data',Data);


%% Call Update

updateSpeciesDataTable(vObj)