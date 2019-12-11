function [hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = plotVirtualPopulationGeneration(obj,hAxes)
% plotVirtualPopulationGeneration - plots the virtual population generation
% analysis.
% -------------------------------------------------------------------------
% Abstract: This plots the virtual population generation analysis.
%
% Syntax:
%           plotVirtualPopulationGeneration(aObj,hAxes)
%
% Inputs:
%           obj - QSP.VirtualPopulationGeneration object
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


[hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = QSP.plotVirtualCohortGeneration(obj,hAxes,'Mode','VP');
