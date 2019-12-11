function updateEditView(vObj)
% updateEditView - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           updateEditView(vObj)
%
% Inputs:
%           vObj - QSPViewer.VirtualPopulationGeneration vObject
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
%   $Revision: 319 $  $Date: 2016-09-10 21:44:01 -0400 (Sat, 10 Sep 2016) $
% ---------------------------------------------------------------------

if vObj.Selection ~= 2
    return;
end

%% Update Results directory

updateResultsDir(vObj);


%% Refresh dataset

refreshDataset(vObj);


%% Refresh Items Table

refreshItemsTable(vObj);


%% Update MinNumVirtualPatients

updateMinNumVirtualPatients(vObj);


%% Refresh SpeciesData Table

refreshSpeciesDataTable(vObj);


