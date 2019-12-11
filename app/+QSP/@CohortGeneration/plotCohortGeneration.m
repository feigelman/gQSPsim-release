function [hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = plotCohortGeneration(obj,hAxes)
% plotCohortGeneration - plots the Cohort Generation visualization
% -------------------------------------------------------------------------
% Abstract: This plots the cohort generation analysis
%
% Syntax:
%           plotCohortGeneration(aObj,hAxes)
%
% Inputs:
%           obj - QSP.CohortGeneration object
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


[hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = QSP.plotVirtualCohortGeneration(obj,hAxes,'Mode','Cohort');