function [hLegend,hLegendChildren] = updatePlots(obj,hAxes,hSpeciesGroup,hDatasetGroup,varargin)
% updatePlots - Updates the plot
% -------------------------------------------------------------------------
% Abstract: Updates the plot
%
% Syntax:
%           updatePlots(aObj,hAxes)
%
% Inputs:
%           obj - QSP.CohortGeneration object
%
%           hAxes
%
%           hSpeciesGroup
%
%           hDatasetGroup
%
% Outputs:
%           hLegend
%
%           hLegendChildren
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

[hLegend,hLegendChildren] = QSP.updateVirtualCohortGenerationPlots(obj,hAxes,hSpeciesGroup,hDatasetGroup,'Mode','Cohort',varargin{:});
