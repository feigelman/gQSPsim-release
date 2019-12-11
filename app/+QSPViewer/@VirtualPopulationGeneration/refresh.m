function refresh(vObj)
% refresh - Updates all parts of the VirtualPopulationGeneration viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the VirtualPopulationGeneration viewer display
%
% Syntax:
%           refresh(vObj)
%
% Inputs:
%           vObj - The VirtualPopulationGeneration vObject
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
%   $Revision: 255 $  $Date: 2016-08-24 15:25:10 -0400 (Wed, 24 Aug 2016) $
% ---------------------------------------------------------------------


%% Invoke superclass's refresh

refresh@uix.abstract.CardViewPane(vObj);


%% Invoke update

update(vObj);



