classdef FolderSelector < uix.abstract.Editable
    % FolderSelector - A widget for selecting a folder
    % ---------------------------------------------------------------------
    % Create a widget that allows you to specify a folder by editable
    % text or by dialog. Optimum height of this control is 25 pixels.
    %
    % Syntax:
    %           w = uix.widget.FolderSelector('Property','Value',...)
    %
    % Examples:
    %
    %   hFig = figure();
    %   hFs = uix.widget.FolderSelector(...
    %       'Parent', hFig, ...
    %       'Value', 'C:\', ...
    %       'Title', 'Choose a folder:', ...
    %       'Units', 'pixels', ...
    %       'Position', [10 10 400 25], ...
    %       'InvalidBackgroundColor', [1 .7 .7], ...
    %       'Callback', @(src,~) disp( src.Value ) );
    %
    %
    % uix.widget.FileSelector properties:
    %
    %   Pattern - cell array of all items to select from
    %   [{'*.mat';'MATLAB MAT files (*.*)'}]
    %
    %   Title - Title to use for the file selection dialog
    %   ['Select a file']
    %
    %   Mode - File selection dialog mode: [('get')|'put']
    %   'get'=uigetfile, 'put'=uiputfile
    %
    %   InvalidBackgroundColor - Color for text background when file is
    %   invalid (If empty, no change)
    %
    %   InvalidForegroundColor - Color for text when file is invalid (If
    %   empty, no change)
    %
    %   RootDirectory - Optional root directory. If unspecified, the
    %   editable text uses an absolute path (default). If specified, the
    %   editable text field will show a relative path to the root
    %   directory. ['']
    %
    %   RequireSubdirOfRoot - Indicates whether the Value must be a
    %   subdirectory of the RootDirectory. If false, the value could be a
    %   directory above RootDirectory expressed with '..\' to go up levels
    %   in the hierarchy. [(true)|false].
    %
    %   FullPath - Absolute path to the file. If RootDirectory is used,
    %   this equals fullfile(obj.RootDirectory, obj.Value). Otherwise, it
    %   is the same as obj.Value.
    %
    %
    % Inherited properties from uix.abstract.Editable:
    %
    %   Callback - Function to call when the value changes
    %
    %   TextEditable - Can the text be manually edited
    %
    %   Value - Current value shown in the widget
    %
    %   BackgroundColor - Color for text background
    %
    %   ForegroundColor - Color for text
    %
    %   FontAngle - Text font angle [normal|italic|oblique]
    %
    %   FontName - Text font name
    %
    %   FontSize - Text font size
    %
    %   FontUnits - Text font units [inches|centimeters|normalized|points|pixels]
    %
    %   FontWeight - Text font weight [light|normal|demi|bold]
    %
    %   HorizontalAlignment - Text alignment [left|center|right]
    %
    %   Tooltip - Tooltip for the eit field
    %
    %
    % Inherited properties from uix.abstract.Widget:
    %
    %   BeingDeleted - Is the object in the process of being deleted
    %   [on|off]
    %
    %   DeleteFcn - Callback to execute when the object is deleted
    %
    %   Enable - allow interaction with this widget [on|off]
    %
    %   Parent - Handle of the parent container or figure [handle]
    %
    %   Position - Position [left bottom width height]
    %
    %   Tag - Tag [char]
    %
    %   Type - The object type (class) [char]
    %
    %   Units - Position units
    %   [inches|centimeters|normalized|points|pixels|characters]
    %
    %   UIContextMenu - Context menu for the object
    %
    %   Visible - Is the control visible on-screen [on|off]
    %
    %
    % Methods:
    %       none
    %


    % Copyright 2005-2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 297 $
    %   $Date: 2016-09-06 14:30:32 -0400 (Tue, 06 Sep 2016) $
    % ---------------------------------------------------------------------


    %% Public properties
    properties
        Title = 'Select a folder'
        InvalidBackgroundColor = []
        InvalidForegroundColor = []
        RootDirectory = ''
        RequireSubdirOfRoot = true
    end

    properties (SetAccess = protected, Dependent = true)
        FullPath
    end

    properties (SetAccess = protected, GetAccess = protected)
        HGButton = []
        ForegroundColor_
        BackgroundColor_
    end


    %% Constructor / Destructor
    methods

        function obj = FolderSelector(varargin)

            % Parent input is needed right away
            Parent = uix.utility.findArg('Parent',varargin{:});
            if isempty(Parent)
                Parent = gcf;
            end

            % Create the parent editable widget
            obj = obj@uix.abstract.Editable('Parent',Parent);

            % Create the base graphics
            obj.create();

            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});

            % Assign the construction flag
            obj.IsConstructed = true;

            % Redraw the widget
            obj.redraw();

        end % constructor

    end %methods - constructor/destructor



    %% Protected methods
    methods (Access = 'protected')

        function create(obj)

            obj.HGButton = uicontrol( ...
                'Parent', obj.UIContainer, ...
                'Visible', 'on', ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'folder_24.png' ), ...
                'Tag', 'uix:widget:FolderSelector:Button', ...
                'Callback', @obj.onButtonClick, ...
                'Tooltip', 'Click to browse' );

            % Now update some details in the GUI elements
            set( obj.HGEditBox,  'HorizontalAlignment', 'left', ...
                'Tooltip', 'Edit the path' );

            obj.Value = '';

        end %function create


        function redraw(obj)

            % Ensure the construction is complete
            if obj.IsConstructed

                sz = getpixelsize( obj );
                width = sz(1);
                height = sz(2);

                % End buttons should have aspect of 2:1
                butWidth = 25;
                txtWidth = width-butWidth;

                % Check space is big enough
                if width<(2*butWidth)
                    butWidth = max(1,width/3);
                    txtWidth = max(1,width-butWidth);
                end
                set( obj.HGButton, 'Position', [1+width-butWidth 1 butWidth height] );
                set( obj.HGEditBox, 'Position', [1 1 txtWidth height] );

            end %if obj.IsConstructed

        end %function redraw


        function StatusOk = checkValue(obj, value)
            % This method must be implemented per the base class

            StatusOk = true;

            % Ensure the construction is complete
            if obj.IsConstructed

                if ~ischar(value)
                    error( 'uix:Editable:BadValue',...
                        'Value must be a character array' )
                end

                PathExists = checkPathExists(obj,value);

                % If file is not valid, change coloring
                if PathExists
                    % Restore normal colors
                    if ~isempty(obj.ForegroundColor_)
                        obj.ForegroundColor = obj.ForegroundColor_;
                        obj.ForegroundColor_ = [];
                    end
                    if ~isempty(obj.BackgroundColor_)
                        obj.BackgroundColor = obj.BackgroundColor_;
                        obj.BackgroundColor_ = [];
                    end
                else
                    % Change to invalid color scheme
                    if ~isempty(obj.InvalidForegroundColor) && isempty(obj.ForegroundColor_)
                        obj.ForegroundColor_ = obj.ForegroundColor;
                        obj.ForegroundColor = obj.InvalidForegroundColor;
                    end
                    if ~isempty(obj.InvalidBackgroundColor) && isempty(obj.BackgroundColor_)
                        obj.BackgroundColor_ = obj.BackgroundColor;
                        obj.BackgroundColor = obj.InvalidBackgroundColor;
                    end
                end %if FileValid

            end %if obj.IsConstructed

        end %function checkValue
        
        
        function PathExists = checkPathExists(obj,RelPath)
            
            ThisPath = fullfile(obj.RootDirectory, RelPath);
            PathExists = exist(ThisPath,'dir');
            
        end %function checkValidPath


        function value = interpretStringAsValue(~, str)
            % This method must be implemented per the base class

            value = str;

        end %function interpretStringAsValue


        function str = interpretValueAsString(~, value)
            % This method must be implemented per the base class

            str = value;

        end %function interpretValueAsString


        function onButtonClick(obj,~,~)

            if exist(obj.FullPath, 'dir')                
                StartPath = obj.FullPath;
            else
                StartPath = obj.RootDirectory;
            end
            
            if strcmpi( obj.Enable, 'ON' )
                foldername = uigetdir( ...
                    StartPath, ...
                    'Select a folder' );
                if isempty( foldername ) || isequal( foldername, 0 )
                    % Cancelled
                else
                    oldValue = obj.Value;
                    obj.FullPath = foldername;

                    % Call callback
                    evt = struct( 'Source', obj, ...
                        'InteractionType', 'Dialog', ...
                        'OldValue', oldValue, ...
                        'NewValue', obj.Value );
                    uix.utility.callCallback( obj.Callback, obj, evt );
                end

            end %if strcmpi(obj.Enable,'ON')
        end % onButtonClick

    end % Protected methods



    %% Get/Set methods
    methods

        function set.Title( obj, value )
            if ~ischar( value )
                error( 'uix:widget:FileSelector:BadString', 'Property ''Title'' must be a character array.' );
            end
            obj.Title = value;
        end


        function set.RootDirectory(obj,value)
            validateattributes(value,{'char'},{},'','RootDirectory')
            %if isempty(value) || exist(value,'dir')
            obj.RootDirectory = value;
            %else
            %    error( 'uix:widget:FileSelector:InvalidRootDirectory',...
            %        'Property ''RootDirectory'' must be a valid path.' );
            %end
        end


        function set.RequireSubdirOfRoot(obj,value)
            validateattributes(value,{'logical'},{'scalar'},'','RequireSubdirOfRoot')
            obj.RequireSubdirOfRoot = value;
        end


        function value = get.FullPath(obj)
            value = fullfile(obj.RootDirectory, obj.Value);
        end
        function set.FullPath(obj,value)
            validateattributes(value,{'char'},{})
            try
                obj.Value = uix.utility.getRelativeFilePath(value,...
                    obj.RootDirectory, obj.RequireSubdirOfRoot);
            catch err
                hDlg = errordlg(err.message,'File Selection','modal');
                uiwait(hDlg);
            end
        end


    end % Get/Set methods

end % classdef