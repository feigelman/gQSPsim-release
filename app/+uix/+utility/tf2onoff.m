function str = tf2onoff(tf)
% tf2onoff - Convert true/false to on/off string
% -------------------------------------------------------------------------
% This function converts a single true/false flag to an on/off string
%
% Syntax:
%           str = uix.utility.tf2onoff(tf)
%
% Inputs:
%           tf - logical scalar or vector
%
% Outputs:
%           str - 'on' or 'off'
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2016 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 272 $  $Date: 2016-08-31 12:42:59 -0400 (Wed, 31 Aug 2016) $
% ---------------------------------------------------------------------

if tf
    str = 'on';
else
    str = 'off';
end