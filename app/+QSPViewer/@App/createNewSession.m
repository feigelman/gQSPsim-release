function createNewSession(obj,Session)
% createNewSession
% -------------------------------------------------------------------------
% Abstract: This method is executed when the user creates a new session
%

% Copyright 2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 226 $  $Date: 2016-08-02 16:46:16 -0400 (Tue, 02 Aug 2016) $
% ---------------------------------------------------------------------

% Was a session provided? If not, make a new one
if nargin<2
    Session = QSP.Session();
end

% Add the session to the tree
hRoot = obj.h.SessionTree.Root;
obj.createTree(hRoot, Session);


%% Update the app state

% Which session is this?
newIdx = obj.NumSessions + 1;

% Add the session to the app
obj.Session(newIdx,1) = Session;

% Start timer
initializeTimer(Session);