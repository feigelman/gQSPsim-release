classdef (Abstract) AppWithSessionFiles < uix.abstract.AppWindow
    
    %% Properties
    
    properties (Access=private)
        LastFolder = pwd %Last folder that was used when opening a file
        RecentSessionPaths = cell.empty(0,1) %List of recent session files
    end
    
    properties (SetAccess=protected, AbortSet=true)
        AllowMultipleSessions = false;
        FileSpec = {'*.mat','MATLAB MAT File'}
        SelectedSessionIdx = double.empty(0,1)
    end
    
    properties (SetAccess=private, Dependent=true, AbortSet=true)
        SelectedSessionName
        SelectedSessionPath
        NumSessions
        SessionNames %FileNames from each loaded
    end
    
    properties (SetAccess=private, AbortSet=true)
        SessionPaths = cell.empty(0,1) %The file paths of the current sessions
        IsDirty = logical.empty(0,1) %Indicates modifications have not been saved
    end
    
    
    %% Abstract methods
    methods(Abstract=true, Access=protected)
        
        % Subclass must define how to save and load a particular session,
        % given a filename (and for save, index of which session)
        createNewSession(obj) %Called to create a new session
        StatusOk = saveSessionToFile(obj, FilePath, idx) %Called when saving a session
        StatusOk = loadSessionFromFile(obj, FilePath) %Called when loading a session
        StatusOk = closeSession(obj,idx) %Called when closing a session
        refresh(obj) %Called after a session filename or status changed, and the app should refresh its view
        
    end % abstract methods
    
    
    
    %% Constructor and Destructor
    methods
        
        function obj = AppWithSessionFiles(varargin)
            
            % Load recent file paths
            obj.LastFolder = getpref(obj.TypeStr,'LastFolder',obj.LastFolder);
            obj.RecentSessionPaths = getpref(obj.TypeStr,'RecentSessionPaths',obj.RecentSessionPaths);
            
            % Validate each recent file, and remove any invalid files
            idxOk = cellfun(@(x)exist(x,'file'),obj.RecentSessionPaths);
            obj.RecentSessionPaths(~idxOk) = [];
            
            % Create the file menu items
            obj.h.FileMenu.Menu = uimenu(...
                'Parent',obj.Figure,...
                'Label','File');
            
            obj.h.FileMenu.New = uimenu(...
                'Parent',obj.h.FileMenu.Menu,...
                'Label','New...',...
                'Accelerator','N',...
                'Callback',@(h,e)onNew(obj));
            
            obj.h.FileMenu.Open = uimenu(...
                'Parent',obj.h.FileMenu.Menu,...
                'Label','Open...',...
                'Accelerator','O',...
                'Callback',@(h,e)onOpen(obj));
            
            obj.h.FileMenu.OpenRecent = uimenu(...
                'Parent',obj.h.FileMenu.Menu,...
                'Label','Open Recent');
            
            obj.h.FileMenu.Close = uimenu(...
                'Parent',obj.h.FileMenu.Menu,...
                'Label','Close',...
                'Separator','on',...
                'Callback',@(h,e)onCloseSession(obj));
            
            obj.h.FileMenu.Save = uimenu(...
                'Parent',obj.h.FileMenu.Menu,...
                'Label','Save',...
                'Accelerator','S',...
                'Separator','on',...
                'Callback',@(h,e)onSave(obj));
            
            obj.h.FileMenu.SaveAs = uimenu(...
                'Parent',obj.h.FileMenu.Menu,...
                'Label','Save As...',...
                'Callback',@(h,e)onSaveAs(obj));
            
            obj.h.FileMenu.Exit = uimenu(...
                'Parent',obj.h.FileMenu.Menu,...
                'Label','Exit',...
                'Accelerator','Q',...
                'Separator','on',...
                'Callback',@(h,e)onExit(obj));
            
            obj.redraw();
            obj.redrawRecentFiles();
            
        end
        
        
        function delete(obj)
            
            % Save recent file paths
            setpref(obj.TypeStr,'LastFolder',obj.LastFolder)
            setpref(obj.TypeStr,'RecentSessionPaths',obj.RecentSessionPaths)
            
        end % delete
        
    end
    
    
    %% Callbacks
    methods (Access=protected)
        
        
        function onCloseSession(obj)
            % Close the currently selected session (used only for
            % multi-session apps)
            
            idxClose = obj.SelectedSessionIdx;
            if obj.promptToSave(idxClose)
                closeFile(obj,idxClose);
            end
            
        end %function
        
        
        function onExit(obj)
            % Exit the whole app
            
            % Only close if sessions are clean, or user agrees to prompt
            if ~any(obj.IsDirty) || obj.promptToSave()
                % Not dirty or prompt returns ok
                obj.delete();
            end
            
        end %function
        
        
        function onNew(obj)
            % Create a new session (for single session, close existing one)
            
            % Can we open a new session or do we prompt to save?
            if obj.AllowMultipleSessions || obj.promptToSave()
                createUntitledSession(obj);
            end
            
        end %function
        
        
        function onOpen(obj,varargin)
            % Open a session (for single session, close existing one)
            
            % Can we open a new session or do we prompt to save?
            if obj.AllowMultipleSessions || obj.promptToSave()
                obj.loadFromFile(varargin{:});
            end
            
        end %function
        
        
        function onSave(obj)
            obj.saveToFile(false);
        end %function
        
        
        function onSaveAs(obj)
            obj.saveToFile(true);
        end %function
        
    end
    
    
    %% File operation helper methods
    methods (Sealed, Hidden=true)
        % These methods are hidden but public for unit testing
        
        function markDirty(obj)
            if ~isempty(obj.SelectedSessionIdx)
                obj.IsDirty(obj.SelectedSessionIdx) = true;
                obj.redraw();
            end
        end
        
        function markClean(obj)
            if ~isempty(obj.SelectedSessionIdx)
                obj.IsDirty(obj.SelectedSessionIdx) = false;
                obj.redraw();
            end
        end
        
        function createUntitledSession(obj)
            % Add a new session called 'untitled_x'
            
            % Clear existing sessions if needed
            if ~obj.AllowMultipleSessions
                obj.SessionPaths = cell.empty(0,1);
            end
            
            % Call subclass method to create storage for the new session
            obj.createNewSession();
            
            % Create the new session and select it
            NewName = matlab.lang.makeUniqueStrings('untitled',obj.SessionNames);
            idxNew = obj.NumSessions + 1;
            obj.SessionPaths{idxNew,1} = NewName;
            obj.IsDirty(idxNew,1) = false;
            
            % remove UDF from selected session
            obj.SelectedSession.removeUDF();
            obj.SelectedSessionIdx = idxNew;
            
            % Refresh app components
            obj.redraw();
            obj.refresh(); %Call refresh of the main app
            
        end
        
        
        function StatusOk = promptToSave(obj,idxToPrompt)
            % Prompt for each dirty file
            StatusOk = true;
            if nargin<2
                idxToPrompt = 1:obj.NumSessions;
            end
            for idx = idxToPrompt
                if obj.IsDirty(idx)
                    Prompt = sprintf('Save changes to %s?', obj.SessionNames{idx});
                    Result = questdlg(Prompt,'Save Changes','Yes','No','Cancel','Yes');
                    switch Result
                        case 'Yes'
                            StatusOk = obj.saveToFile(false, idx);
                        case 'Cancel'
                            StatusOk = false;
                    end %switch Result
                    if ~StatusOk
                        return %user cancelled
                    end
                end
            end
        end %function
        
        
        function StatusOK = saveToFile(obj,UseSaveAs,idxToSave)
            % Save the specified session to a file
            
            % Check if save index was specified, else use selected session
            if nargin<3
                idxToSave = obj.SelectedSessionIdx;
            end
            StatusOK = true;
            % Loop on each file to save
            for idx=idxToSave'
                
                % Get the save location for this sesson. If new, prepare a
                % default path.
                ThisFile = obj.SessionPaths{idx};
                IsNewFile = ~exist(ThisFile,'file');
                % If no path, use the last folder to start in
                if isempty(fileparts(ThisFile))
                    ThisFile = fullfile(obj.LastFolder,ThisFile);
                end
                
                % Do we need to prompt for a filename?
                if UseSaveAs || IsNewFile
                    
                    % Need special handling for non-PC
                    [PathName,FileName] = fileparts(ThisFile);
                    FileName = regexp(FileName,'\.','split');
                    if iscell(FileName)
                        FileName = FileName{1};
                    end
%                     ThisFile = fullfile(PathName,[FileName obj.FileSpec{1}]);
                    ThisFile = fullfile(PathName,FileName);

                    
                    [FileName,PathName,FilterIndex] = uiputfile(obj.FileSpec, ...
                        'Save as',ThisFile);
                    if isequal(FileName,0)
                        return %user cancelled
                    end
                    
                    if iscell(obj.FileSpec)
                        FileExt = obj.FileSpec{FilterIndex,1};
                    else
                        FileExt = obj.FileSpec;
                    end
                    
                    % If it's missing the full FileExt (i.e. on Mac/Linux)
                    if isempty(regexp(FileName,FileExt,'once'))
                        FileName = regexp(FileName,'\.','split');
                        if iscell(FileName)
                            FileName = FileName{1};
                        end
                        if ~isempty(FileExt)
                            FileExt = FileExt(2:end);
                        end
                        FileName = [FileName,FileExt]; %#ok<AGROW>
                    end
                    
                    ThisFile = fullfile(PathName,FileName);
                    obj.LastFolder = PathName;
                    
                end
                
                % Try save. If it returns ok, then update ui states.
                % Otherwise, return.
                OldSessionPath = obj.SessionPaths{idx};
                OldDirty = obj.IsDirty(idx);
                obj.SessionPaths{idx} = ThisFile;
                obj.IsDirty(idx) = false;
                if obj.saveSessionToFile(ThisFile,idx) %Calls subclass method implementation
                    obj.addRecentSessionPath(ThisFile);
                    
                    % Refresh app components
                    obj.redraw();
                    obj.refresh(); %Call refresh of the main app
                else
                    obj.IsDirty(idx) = OldDirty;
                    obj.SessionPaths{idx} = OldSessionPath;
                    StatusOK = false;
                    return %something failed
                end
                
            end %for idx=idxToSave'

        end %function
        
        
        function loadFromFile(obj,FilePath)
            
            % Do we need to prompt for a filename?
            if nargin<2
                Multi = uix.utility.tf2onoff(obj.AllowMultipleSessions);
                [FileName,PathName] = uigetfile(obj.FileSpec,...
                    'Open File', obj.LastFolder,...
                    'MultiSelect', Multi);
                if isequal(FileName,0)
                    return %user cancelled
                end
                FilePath = fullfile(PathName,FileName);
                obj.LastFolder = PathName;
            end
            
            % Validate the file exists and isn't already open. Otherwise prompt the user
            if ~exist(FilePath,'file')
                Message = sprintf('The specified file does not exist: \n%s',FilePath);
                hDlg = errordlg(Message,'Open File','modal'); uiwait(hDlg);
            elseif ismember(FilePath, obj.SessionPaths)
                Message = sprintf('The specified file is already open: \n%s',FilePath);
                hDlg = errordlg(Message,'Open File','modal'); uiwait(hDlg);
            else
                % Load. If it returns ok, then add the session files info
                if obj.loadSessionFromFile(FilePath) %Calls subclass method implementation
                    idxNew = obj.NumSessions + 1;
                    obj.SessionPaths{idxNew,1} = FilePath;
                    obj.IsDirty(idxNew,1) = false;
                    obj.SelectedSessionIdx = idxNew;
                    obj.addRecentSessionPath(FilePath);
                    
                    % Refresh app components
                    obj.redraw();
                    obj.refresh(); %Call refresh of the main app
                end
            end
            
        end %function
        
        
        function closeFile(obj,idx)
            
            % Close. If it returns ok, remove the session.
            if closeSession(obj,idx) %Calls subclass method implementation
                obj.SessionPaths(idx) = [];
                obj.IsDirty(idx) = [];
                if obj.NumSessions < 1
                    obj.SelectedSessionIdx = [];
                elseif obj.SelectedSessionIdx > obj.NumSessions
                    obj.SelectedSessionIdx = obj.NumSessions;
                end
                    
                    % Refresh app components
                    obj.redraw();
                    obj.refresh(); %Call refresh of the main app
            end
            
        end %function
        
        
        function addRecentSessionPath(obj,FilePaths)
            
            % If this file is already in the list, remove it for reordering
            IsInRecent = ismember(obj.RecentSessionPaths, FilePaths);
            obj.RecentSessionPaths(IsInRecent) = [];
            
            % Add the file to the top of the list
            obj.RecentSessionPaths = vertcat(FilePaths, obj.RecentSessionPaths);
            
            % Crop the list to 8 entries
            obj.RecentSessionPaths(9:end) = [];
            
            % Redraw the menu items
            obj.redrawRecentFiles();
            
        end %function
        
    end %methods
    
    
    
    %% Redraw methods
    methods (Access=protected)
        
        function redraw(obj)
            
            % Get some criteria on selection and whether it's dirty
            SelectionNotEmpty = ~isempty(obj.SessionNames) && ~isempty(obj.SelectedSessionIdx);
            SelectionIsDirty = SelectionNotEmpty && any(obj.IsDirty(obj.SelectedSessionIdx));
            
            % Update title bar
            if SelectionNotEmpty
                CurrentFile = obj.SessionNames{obj.SelectedSessionIdx};
            else
                CurrentFile = '';
            end
            if SelectionIsDirty
                StarStr = ' *';
            else
                StarStr = '';
            end
            obj.Title = sprintf('%s - %s%s', obj.AppName, CurrentFile, StarStr);
            
            % Enable File->Save only if selection is dirty
            set(obj.h.FileMenu.Save,...
                'Enable',uix.utility.tf2onoff(SelectionIsDirty))
            
            % Enable File->SaveAs and File->Close only if selection is made
            set([obj.h.FileMenu.SaveAs, obj.h.FileMenu.Close],...
                'Enable',uix.utility.tf2onoff(SelectionNotEmpty))
            
        end %function
        
        
        function redrawRecentFiles(obj)
            
            % Refresh the list of Recent Files
            
            % Add new items
            hItems = obj.h.FileMenu.OpenRecent.Children;
            if isempty(hItems)
                ItemsToAdd = obj.RecentSessionPaths;
            else
                ExistingItems = {hItems.UserData};
                ToAdd = ~ismember(obj.RecentSessionPaths, ExistingItems);
                ItemsToAdd = obj.RecentSessionPaths(ToAdd);
            end
            for idx=1:numel(ItemsToAdd)
                uimenu(...
                    'Parent', obj.h.FileMenu.OpenRecent,...
                    'Label', ItemsToAdd{idx},...
                    'UserData', ItemsToAdd{idx},...
                    'Callback', @(h,e)onOpen(obj, ItemsToAdd{idx}) );
            end
            
            % Remove old items and order the rest
            hItems = obj.h.FileMenu.OpenRecent.Children;
            if ~isempty(hItems)
                ExistingItems = {hItems.UserData}';
                [ToKeep1, idxKeep] = ismember(ExistingItems, obj.RecentSessionPaths);
                delete(hItems(~ToKeep1));
                hItems(~ToKeep1) = [];
                Order = idxKeep(ToKeep1);
                hItems = flipud(hItems(Order));
                obj.h.FileMenu.OpenRecent.Children = hItems;
            end
            
            % If no recent items, disable the menu item
            HasRecent = uix.utility.tf2onoff( ~isempty(hItems) );
            set(obj.h.FileMenu.OpenRecent,'Enable',HasRecent)
            
        end %function
        
        
    end %methods
    
    
    
    %% Get/Set methods
    methods
        
        function value = get.SessionNames(obj)
            [~,value,ext] = cellfun(@fileparts, obj.SessionPaths,...
                'UniformOutput', false);
            value = strcat(value,ext);
        end
        
        function value = get.LastFolder(obj)
            % If the LastFolder doesn't exist, update it
            if ~exist(obj.LastFolder,'dir')
                obj.LastFolder = pwd;
            end
            value = obj.LastFolder;
        end %function
        
        function value = get.SelectedSessionPath(obj)
            % Grab the session object for the selected session
            sIdx = obj.SelectedSessionIdx;
            if isempty(sIdx) || isempty(obj.SessionPaths)
                value = '';
            else
                value = obj.SessionPaths{obj.SelectedSessionIdx};
            end
        end
        
        function value = get.SelectedSessionName(obj)
            % Grab the session object for the selected session
            sIdx = obj.SelectedSessionIdx;
            if isempty(sIdx) || isempty(obj.SessionPaths)
                value = '';
            else
                value = obj.SessionNames{obj.SelectedSessionIdx};
            end
        end
        
        function value = get.NumSessions(obj)
            value = numel(obj.SessionPaths);
        end
        
        function value = get.SelectedSessionIdx(obj)
            ns = obj.NumSessions;
            if ns==0
                value = double.empty(0,1);
            elseif obj.SelectedSessionIdx > ns
                value = ns;
            else
                value = obj.SelectedSessionIdx;
            end
        end
        function set.SelectedSessionIdx(obj,value)
            if isempty(value)
                obj.SelectedSessionIdx = double.empty(0,1);
            else
                validateattributes(value, {'double'},...
                    {'scalar','positive','integer','<=',obj.NumSessions}) %#ok<MCSUP>
                obj.SelectedSessionIdx = value;
            end
            obj.redraw()
        end
        
        function set.SessionPaths(obj,value)
            if isempty(value)
                obj.SessionPaths = cell.empty(0,1);
            else
                obj.SessionPaths = value;
            end
            obj.redraw()
        end
        
    end %methods
    
    
    
end %classdef