function assignPaneData(obj, Data, varargin)
% assignPaneData
% -------------------------------------------------------------------------
% Abstract: This method assigns pane data. This method may be overloaded as
% needed. If additional inputs are needed (via varargin), it must be
% overridden.
%

% Copyright 2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting $Author: rjackey $ $Revision: 247 $  $Date:
%   2016-08-03 10:40:59 -0400 (Wed, 03 Aug 2016) $
% ---------------------------------------------------------------------


% Assign data to the pane
if ~isempty(obj.ActivePane)
    try
        obj.ActivePane.Data = Data;
        obj.ActivePane.Callback = @(h,e)onDataChanged(obj,h,e);
        
        % Set the IsDeleted flag
        if nargin > 2 && islogical(varargin{1}) && isprop(obj.ActivePane,'IsDeleted')
            obj.ActivePane.IsDeleted = varargin{1};
        end
        
    catch err
        warning('QSPViewer:AssignData',...
            'Unable to assign data to ViewPane %s.\nError: %s (%s - line %d)',...
            class(obj.ActivePane), err.message, err.stack(1).name, err.stack(1).line);
    end
end

end %function