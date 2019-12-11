function refresh(vObj)
% refresh - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           refresh(vObj)
%
% Inputs:
%           vObj - QSPViewer.Session object
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2014-2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 281 $  $Date: 2016-09-01 09:27:14 -0400 (Thu, 01 Sep 2016) $
% ---------------------------------------------------------------------

%% Invoke superclass's refresh

refresh@uix.abstract.CardViewPane(vObj);



if isscalar(vObj.Data)
    RootDir = vObj.Data.RootDirectory;
    RelativeObjectiveFunctionsPath = vObj.Data.RelativeObjectiveFunctionsPath;
    RelativeUserDefinedFunctionsPath = vObj.Data.RelativeUserDefinedFunctionsPath;
    set(vObj.h.ObjectiveFunctionsDirSelector,'RootDirectory',RootDir)
    set(vObj.h.UserDefinedFunctionsDirSelector,'RootDirectory',RootDir)
    
    set(vObj.h.UseParallelCheckbox, 'Value', vObj.Data.UseParallel);
    if vObj.Data.UseParallel
        Enable_cluster = 'on';
    else
        Enable_cluster = 'off';
    end
   
    ThisCluster = vObj.Data.ParallelCluster;
else
    RootDir = '';
%     RelativeResultsPath = '';
    RelativeUserDefinedFunctionsPath = '';
    RelativeObjectiveFunctionsPath = '';
    vObj.h.UseParallelCheckbox.Value = 0;
    Enable_cluster = 'off';
    ThisCluster = '';
    
%     info = ver;
%     if ismember('Parallel Computing Toolbox', {info.Name})
%         vObj.h.ParallelCluster.String = parallel.clusterProfiles;
%     else
%         vObj.h.ParallelCluster.String = {''};
%     end
end

vObj.h.RootDirSelector.Value = RootDir;
vObj.h.ResultsDirSelector.RootDirectory = RootDir;
% vObj.h.ResultsDirSelector.Value = RelativeResultsPath;
vObj.h.FunctionsDirSelector.RootDirectory = RootDir;
vObj.h.ObjectiveFunctionsDirSelector.Value = RelativeObjectiveFunctionsPath;
vObj.h.UserDefinedFunctionsDirSelector.Value = RelativeUserDefinedFunctionsPath;

ThisIdx = find(strcmp(get(vObj.h.ParallelCluster, 'String'),ThisCluster));
if isempty(ThisIdx)
    ThisIdx = 1;
end
set(vObj.h.ParallelCluster, 'Value', ThisIdx, ...
    'Enable', Enable_cluster);


%% Invoke update

update(vObj);

