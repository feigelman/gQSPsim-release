function update(vObj)
% update - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           update(vObj)
%
% Inputs:
%           vObj - QSPViewer.CohortGeneration vObject
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
%   $Author: agajjala $
%   $Revision: 269 $  $Date: 2016-08-31 00:01:30 -0400 (Wed, 31 Aug 2016) $
% ---------------------------------------------------------------------

%% Update plot layout

if ~isempty(vObj.Data)
    vObj.SelectedPlotLayout = vObj.Data.SelectedPlotLayout;
end


%% Invoke superclass's update

update@uix.abstract.CardViewPane(vObj);

if ~isempty(vObj.Data)
    % Check what items are stale or invalid
    [~,ValidFlag] = getStaleItemIndices(vObj.Data);
    if all(ValidFlag) && vObj.Selection ~= 2
        set(vObj.h.VisualizeButton,'Enable','on');
    else
        % Navigate to Summary view if not already on it
        if vObj.Selection == 3
            onNavigation(vObj,'Summary');
        end
        set(vObj.h.VisualizeButton,'Enable','off');        
    end
end


%% Update Edit View

if vObj.Selection == 2
    updateEditView(vObj);
end


%% Update Visualization View

if vObj.Selection == 3
    updateVisualizationView(vObj);
end



