function updateVisualizationParametersTable(vObj,varargin)
% updateVisualizationParametersTable - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           updateVisualizationParametersTable(vObj)
%
% Inputs:
%           vObj - QSPViewer.Optimization vObject
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
%   $Revision: 331 $  $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
% ---------------------------------------------------------------------

if nargin > 1 && iscell(varargin{1})
    ThisProfileData = varargin{1};
else
    [~,~,ThisProfileData] = importParametersSourceHelper(vObj);
end

% Parameters Table
if ~isempty(ThisProfileData) && size(ThisProfileData,2)==3
    
    % Mark the rows that are edited (column 2 does not equal column 3)
    if ispc
        italCols = 1:size(ThisProfileData,2);
    else
        italCols = 1;
    end
    
    for rowIdx = 1:size(ThisProfileData,1)
        tmp1 = ThisProfileData{rowIdx,2};
        tmp2 = ThisProfileData{rowIdx,3};
        if ischar(tmp1), tmp1=str2num(tmp1); end
        if ischar(tmp2), tmp2=str2num(tmp2); end
        
        if ~isequal(tmp1, tmp2)
            for colIdx = italCols
                ThisProfileData{rowIdx,colIdx} = QSP.makeItalicized(ThisProfileData{rowIdx,colIdx});
            end
        end
    end
    
    set(vObj.h.PlotParametersTable,...
        'Data',ThisProfileData,...
        'ColumnName',{'Parameter','Value','Source Value'},...
        'ColumnFormat',{'char','float','float'},...
        'ColumnEditable',[false,true,false], ...
        'LabelString', sprintf('Parameters (Run = %d)', vObj.Data.SelectedProfileRow));
else
    set(vObj.h.PlotParametersTable,...
        'Data',cell(0,3),...
        'ColumnName',{'Parameter','Value','Source Value'},...
        'ColumnFormat',{'char','float','float'},...
        'ColumnEditable',[false,true,false], ...
        'LabelString', sprintf('Parameters'));
end