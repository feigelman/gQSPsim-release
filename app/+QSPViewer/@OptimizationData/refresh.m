function refresh(vObj)
% refresh - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           refresh(vObj)
%
% Inputs:
%           vObj - QSPViewer.OptimizationData vObject
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
%   $Revision: 241 $  $Date: 2016-08-17 12:48:39 -0400 (Wed, 17 Aug 2016) $
% ---------------------------------------------------------------------


%% Invoke superclass's refresh

refresh@uix.abstract.CardViewPane(vObj);


%% Invoke update

update(vObj);

