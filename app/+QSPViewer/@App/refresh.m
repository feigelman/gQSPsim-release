function refresh(obj)
% refresh - Updates all parts of the obj display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the obj display
%
% Syntax:
%           refresh(obj)
%
% Inputs:
%           obj - The QSPViewer.App object
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 281 $  $Date: 2016-09-01 09:27:14 -0400 (Thu, 01 Sep 2016) $
% ---------------------------------------------------------------------

% Can only run if app construction is complete
if ~obj.IsConstructed
    return
end

% What is selected?
SelNode = obj.h.SessionTree.SelectedNodes;
sIdx = obj.SelectedSessionIdx;
% SessionName = obj.SelectedSessionName;
IsOneSessionSelected = isscalar(sIdx);
IsSelectedSessionDirty = isequal(obj.IsDirty(obj.SelectedSessionIdx), true);

%% Update menu items

% See if the current node is removable or restorable. To be removable, it
% must be a single node with empty userdata, and can not be in Deleted
% Items. To be restorable, it must be a single node that IS in Deleted
% Items.
if isscalar(SelNode) && isequal(SelNode.UserData,[])
    if strcmp(SelNode.Parent.UserData,'Deleted')
        IsNodeRestorable = true;
        IsNodeRemovable = false;
    else
        IsNodeRestorable = false;
        IsNodeRemovable = true;
    end
else
    IsNodeRestorable = false;
    IsNodeRemovable = false;
end

set(obj.h.QSPMenu.Add,'Enable',uix.utility.tf2onoff(IsOneSessionSelected));
set(obj.h.QSPMenu.Remove,'Enable',uix.utility.tf2onoff(IsNodeRemovable));
set(obj.h.QSPMenu.Restore,'Enable',uix.utility.tf2onoff(IsNodeRestorable));

% Enable/disable Save on tree context menu for session branch
set(obj.h.TreeMenu.Branch.SessionSave,'Enable',uix.utility.tf2onoff(IsSelectedSessionDirty))


%% Update the session tree

% Update each session node in the tree
for idx=1:obj.NumSessions
    
    % Get the session name for this node
    ThisRawName = obj.SessionNames{idx};
    ThisName = ThisRawName;
    
    % Add dirty flag if needed
    if obj.IsDirty(idx)
        ThisName = strcat(ThisName, ' *');
    end
    
    % Set the session node updates
    set(obj.SessionNode(idx), ...
        'Name', ThisName,...
        'TooltipString', obj.SessionPaths{idx} );
    
    % Assign Name
    setSessionName(obj.Session(idx),ThisRawName);
    
end


% If the current node was updated, check if the node name changed
if isscalar(SelNode) && isscalar(SelNode.Value) &&...
        isprop(SelNode.Value,'Name') && ~strcmp(SelNode.Value.Name, SelNode.Name) && ...
        ~strcmpi(class(SelNode.Value),'QSP.Session') % Skip for session. Do not use Name to update the Node property; use SessionName
    % Update the node name
    SelNode.Name = SelNode.Value.Name;
end



%% Update the right pane viewer

% What pane should be launched?

if isscalar(SelNode)
    
    % The right-pane viewer launched depends on contents of the tree node:
    % 1. If the node's UserData is non-empty, then it is a string
    % indicating the viewer to launch. (Exception: UserData is 'Deleted',
    % then see #2 but the viewer will be read-only because the item is
    % under Deleted Items.)
    % 2. If UserData is Empty, the class of data in the node's Value
    % indicates the viewer type to launch from the QSPViewer package.
    
    PaneType = SelNode.UserData;
    Data = SelNode.Value;
    IsDeleted = strcmpi(SelNode.Parent.UserData,'Deleted');
    
    % Check if the ActivePane changed
    if ~isempty(obj.ActivePane)
        
        % Save plot settings (i.e. if any axes are in manual mode
        if ~isempty(obj.ActivePane.Data) && isprop(obj.ActivePane.Data,'PlotSettings')
            obj.ActivePane.Data.PlotSettings = getSummary(obj.ActivePane.PlotSettings);
        end
        
        % Before launching, turn off zoom/pan/datacursormode if panetype
        % changes
        if isa(obj.ActivePane,'uix.abstract.CardViewPane')
            turnOffZoomPanDatacursor(obj.ActivePane);
        end
    end
    
    % Then, launch    
    obj.launchPane(Data, PaneType, IsDeleted);
    
    % Assign navigation changed listener (for RHS views - summary, edit, etc.)
    if ~isempty(obj.NavigationChangedListener)
        delete(obj.NavigationChangedListener);
    end
    if ~isempty(obj.ActivePane) && any(strcmpi(events(obj.ActivePane),'NavigationChanged'))
        obj.NavigationChangedListener = event.listener(obj.ActivePane,'NavigationChanged',@(h,e)onNavigationChanged(obj,h,e));
    end
    
    % Assign mark dirty listener
    if ~isempty(obj.MarkDirtyListener)
        delete(obj.MarkDirtyListener);
    end
    if ~isempty(obj.ActivePane) && any(strcmpi(events(obj.ActivePane),'MarkDirty'))
        obj.MarkDirtyListener = event.listener(obj.ActivePane,'MarkDirty',@(h,e)onMarkDirty(obj,h,e));
    end
else
    
    % Clear the pane - it's empty
    obj.clearPane();
    
end









