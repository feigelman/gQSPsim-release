function refreshItemsTable(vObj)

%% Refresh TaskPopupTableItems
if ~isempty(vObj.TempData)
    ValidItemTasks = getValidSelectedTasks(vObj.TempData.Settings,{vObj.TempData.Settings.Task.Name});
    if ~isempty(ValidItemTasks)
        vObj.TaskPopupTableItems = {ValidItemTasks.Name};
    else
        vObj.TaskPopupTableItems = {};
    end
else
    vObj.TaskPopupTableItems = {};
end

%% Refresh SpeciesPopupTableItems - Derived from Selected Tasks

% Species
    if ~isempty(vObj.TempData) && all(isvalid(vObj.TempData.Item))
        ItemTaskNames = {vObj.TempData.Item.TaskName};    
        vObj.SpeciesPopupTableItems = getSpeciesFromValidSelectedTasks(vObj.TempData.Settings,ItemTaskNames);    
    else
        vObj.SpeciesPopupTableItems = {};
    end


%% Update ItemsTable

if ~isempty(vObj.TempData)
    TaskNames = {vObj.TempData.Item.TaskName};
    GroupIDs = {vObj.TempData.Item.GroupID};
    RunToSteadyState = false(size(TaskNames));
    
    for index = 1:numel(TaskNames)
        MatchIdx = strcmpi(TaskNames{index},{vObj.TempData.Settings.Task.Name});
        if any(MatchIdx)
            RunToSteadyState(index) = vObj.TempData.Settings.Task(MatchIdx).RunToSteadyState;
        end
    end
    Data = [TaskNames(:) GroupIDs(:) num2cell(RunToSteadyState(:))];
    
    % Mark any invalid entries
    if ~isempty(Data)
        % Task
        
        for index = 1:numel(TaskNames)
            ThisTask = getValidSelectedTasks(vObj.TempData.Settings,TaskNames{index});
            % Mark invalid if empty
            if isempty(ThisTask)            
                Data{index,1} = QSP.makeInvalid(Data{index,1});
            end
        end
        
        % GroupIDs
        MatchIdx = find(~ismember(GroupIDs(:),vObj.GroupIDPopupTableItems(:)));
        for index = 1:numel(MatchIdx)
            Data{MatchIdx(index),2} = QSP.makeInvalid(Data{MatchIdx(index),2});
        end
    end
else
    Data = {};
end

set(vObj.h.ItemsTable,'Data',Data);


%% Invoke update

updateItemsTable(vObj);