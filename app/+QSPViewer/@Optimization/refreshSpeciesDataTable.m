function refreshSpeciesDataTable(vObj)


%% Update ObjectiveFunctions

if ~isempty(vObj.TempData)
    if exist(vObj.TempData.Session.ObjectiveFunctionsDirectory,'dir')
        FileList = dir(vObj.TempData.Session.ObjectiveFunctionsDirectory);
        IsDir = [FileList.isdir];
        Names = {FileList(~IsDir).name};
        vObj.ObjectiveFunctions = vertcat('defaultObj',Names(:));
    else
        vObj.ObjectiveFunctions = {'defaultObj'};
    end
else
    vObj.ObjectiveFunctions = {'defaultObj'};
end


%% Refresh Table

if ~isempty(vObj.TempData)
    SpeciesNames = {vObj.TempData.SpeciesData.SpeciesName};
    DataNames = {vObj.TempData.SpeciesData.DataName};
    FunctionExpressions = {vObj.TempData.SpeciesData.FunctionExpression};
    ObjectiveNames = {vObj.TempData.SpeciesData.ObjectiveName};
    
    % Get the selected tasks based on Optim Items
    ItemTaskNames = {vObj.TempData.Item.TaskName};
    ValidSelectedTasks = getValidSelectedTasks(vObj.TempData.Settings,ItemTaskNames);
    
    NumTasksPerSpecies = zeros(size(SpeciesNames));
    for iSpecies = 1:numel(SpeciesNames)
        for iTask = 1:numel(ValidSelectedTasks)
            if any(strcmpi(SpeciesNames{iSpecies},ValidSelectedTasks(iTask).ActiveSpeciesNames))
                NumTasksPerSpecies(iSpecies) = NumTasksPerSpecies(iSpecies) + 1;
            end
        end
    end
    
    Data = [DataNames(:) SpeciesNames(:) num2cell(NumTasksPerSpecies(:)) FunctionExpressions(:) ObjectiveNames(:)];
    
    % Mark any invalid entries
    if ~isempty(Data)
        % Data
        MatchIdx = find(~ismember(DataNames(:),vObj.PrunedDatasetHeader(:)));
        for index = 1:numel(MatchIdx)
            Data{MatchIdx(index),1} = QSP.makeInvalid(Data{MatchIdx(index),1});
        end
        % Species
        MatchIdx = find(~ismember(SpeciesNames(:),vObj.SpeciesPopupTableItems(:)));
        for index = 1:numel(MatchIdx)
            Data{MatchIdx(index),2} = QSP.makeInvalid(Data{MatchIdx(index),2});
        end
        % ObjectiveNames
        MatchIdx = find(~ismember(ObjectiveNames(:),vObj.ObjectiveFunctions(:)));
        for index = 1:numel(MatchIdx)
            Data{MatchIdx(index),5} = QSP.makeInvalid(Data{MatchIdx(index),5});
        end
    end
else
    Data = {};
end
set(vObj.h.SpeciesDataTable,'Data',Data);


%% Call Update

updateSpeciesDataTable(vObj)