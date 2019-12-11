function out = cellstr2dlmstr(in,delimiter)
% cellstr2dlmstr - Convert cell string to delimited list
% -------------------------------------------------------------------------
% Abstract: Converts an input cell array of strings into a delimited string
%
% Syntax:
%           out = cellstr2dlmstr(in,delimiter)
%           out = cellstr2dlmstr(in,delimiter)
%
% Inputs:
%           in - input cellstr array
%           delimiter - delimiter string to separate items
%
% Outputs:
%           out = output string
%
% Examples:
%           >> out = cellstr2dlmstr({'moo','boo','foo'},'; ')
%           out =
%           moo; boo; foo
%
% Notes: none
%

%   Copyright 2011-2014 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 272 $  $Date: 2016-08-31 12:42:59 -0400 (Wed, 31 Aug 2016) $
% ---------------------------------------------------------------------

if nargin < 2
    delimiter = ',';
end

in = cellstr(in);

if ~isempty(in)
    out = [sprintf(['%s' delimiter], in{1:end-1}), sprintf('%s', in{end})];
else
    out = '';
end
