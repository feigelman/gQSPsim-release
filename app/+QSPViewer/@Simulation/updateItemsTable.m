function updateItemsTable(vObj)

% Set the data
set(vObj.h.ItemsTable,...
    'ColumnEditable',[true true true],...
    'ColumnName',{'Task','Virtual Subject(s)','Virtual Subject Group to Simulate','Available Groups in Virtual Subjects',},...
    'ColumnFormat',{vObj.TaskPopupTableItems(:), ... vObj.GroupPopupTableItems(:),
        vObj.VPopPopupTableItems(:), 'char', 'char'});
