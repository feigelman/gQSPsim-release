function refreshItemsTable(vObj, validateFlag)

%% Refresh TaskPopupTableItems
if validateFlag

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

    %% Refresh VPopPopupTableItems

    if ~isempty(vObj.TempData)
        ValidItemVPops = getValidSelectedVPops(vObj.TempData.Settings,{vObj.TempData.Settings.VirtualPopulation.Name});    
        if ~isempty(ValidItemVPops)
            vObj.VPopPopupTableItems = [{vObj.Data.NullVPop} {ValidItemVPops.Name}];        
        else
            vObj.VPopPopupTableItems = {vObj.Data.NullVPop};
        end
    else
        vObj.VPopPopupTableItems = {};
    end
end
%% Refresh GroupPopupTableItems
% vObj.GroupPopupTableItems = sprintfc('%d',1:length(vObj.TempData.Settings.Task));


%% Update ItemsTable

if ~isempty(vObj.TempData)
    TaskNames = {vObj.TempData.Item.TaskName};
    VPopNames = {vObj.TempData.Item.VPopName};
    Groups = {vObj.TempData.Item.Group};
    AvailableGroups = cell(1,length(vObj.TempData.Item));
    for k=1:length(vObj.TempData.Item)
        vpopObj = vObj.TempData.Settings.getVpopWithName(vObj.TempData.Item(k).VPopName);
        if isempty(vpopObj) 
            AvailableGroups{k} = 'N/A';
        else
            AvailableGroups{k} = vpopObj.Groups;
        end
    end
    Data = [TaskNames(:) VPopNames(:) Groups(:) AvailableGroups(:) ];
    
    % Mark any invalid entries
    if ~isempty(Data)
        % Task
        MatchIdx = find(~ismember(TaskNames(:),vObj.TaskPopupTableItems(:)));
        for index = MatchIdx(:)'
            Data{index,1} = QSP.makeInvalid(Data{index,1});
        end        
        % VPop
        MatchIdx = find(~ismember(VPopNames(:),vObj.VPopPopupTableItems(:)));
        for index = MatchIdx(:)'
            Data{index,2} = QSP.makeInvalid(Data{index,2});
        end
    end
else
    Data = {};
end
    
% Set the data
set(vObj.h.ItemsTable,'Data',Data);


%% Invoke update

updateItemsTable(vObj);
