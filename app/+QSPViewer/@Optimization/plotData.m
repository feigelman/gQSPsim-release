function plotData(vObj, varargin)
% plotData - plots all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function plots all parts of the viewer display
%
% Syntax:
%           plotData(vObj)
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
%   $Revision: 264 $  $Date: 2016-08-30 15:24:41 -0400 (Tue, 30 Aug 2016) $
% ---------------------------------------------------------------------

%             try
% Plot
[vObj.h.SpeciesGroup,vObj.h.DatasetGroup,vObj.h.AxesLegend,vObj.h.AxesLegendChildren] = ...
    plotOptimization(vObj.Data,vObj.h.MainAxes, varargin);
%             catch ME
%                 hDlg = errordlg(sprintf('Cannot plot. %s',ME.message),'Invalid','modal');
%                 uiwait(hDlg);
%             end



