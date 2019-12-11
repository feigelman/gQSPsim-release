classdef FileSelector < uix.widget.FolderSelector
    % FileSelector - A widget for selecting a filename
    % ---------------------------------------------------------------------
    % Create a widget that allows you to specify a filename by editable
    % text or by dialog. Optimum height of this control is 25 pixels.
    %
    % Syntax:
    %           w = uix.widget.FileSelector('Property','Value',...)
    %
    % Examples:
    %
    %   hFig = figure();
    %   hFs = uix.widget.FileSelector(...
    %       'Parent', hFig, ...
    %       'Value', 'C:\matlab.mat', ...
    %       'Pattern', {'*.mat','MATLAB MAT files (*.mat)'; '*.csv','CSV files (*.csv)'}, ...
    %       'Title', 'Choose a data file:', ...
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
    %   Mode - File selection dialog mode: [('get')|'put']
    %   'get'=uigetfile, 'put'=uiputfile
    %
    %
    % Inherited properties from uix.widget.FolderSelector:
    %
    %   Title - Title to use for the file selection dialog
    %   ['Select a file']
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
    %   $Author: rjackey $
    %   $Revision: 284 $
    %   $Date: 2016-09-01 13:55:31 -0400 (Thu, 01 Sep 2016) $
    % ---------------------------------------------------------------------


    %% Properties
    properties
        Pattern = {'*.mat';'MATLAB MAT files (*.*)'}
        Mode = 'get'
    end


    %% Constructor / Destructor
    methods

        function obj = FileSelector(varargin)
            
            % Create the parent editable widget
            obj = obj@uix.widget.FolderSelector(varargin{:});

            % Modifications for file selection
            obj.Title = 'Select a file';
            set(obj.HGButton,'CData',uix.utility.loadIcon('folder_file_24.png'))


        end % constructor

    end %methods - constructor/destructor



    %% Protected methods
    methods (Access = 'protected')

        
        function PathExists = checkPathExists(obj,RelPath)
            
            ThisPath = fullfile(obj.RootDirectory, RelPath);
                ParentDir = fileparts(ThisPath);
                PathExists = ...
                    ( strcmpi(obj.Mode,'get') && exist(ThisPath,'file')==2 )|| ...
                    ( strcmpi(obj.Mode,'put') && exist(ParentDir,'dir') );
            
        end %function checkValidPath


        function onButtonClick(obj,~,~)
            if strcmpi(obj.Enable,'ON')

                StartPath = obj.FullPath;
                if strcmpi( obj.Mode, 'get' )
                    [filename,pathname] = uigetfile( ...
                        obj.Pattern, ...
                        obj.Title, ...
                        StartPath );
                else
                    [filename,pathname] = uiputfile( ...
                        obj.Pattern, ...
                        obj.Title, ...
                        StartPath );
                end

                if isempty(filename) || isequal( filename, 0 )
                    % Cancelled
                else
                    oldValue = obj.Value;
                    obj.FullPath = fullfile(pathname,filename);

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

        function set.Pattern(obj,value)
            if ~iscell( value ) ...
                    || isempty( value ) ...
                    || size( value, 2 )>2 ...
                    || any( ~cellfun( @ischar, value(:) ) )
                error( 'uix:widget:FileSelector:BadFilePattern', 'Property ''FilterSpec'' must be a valid file filter specification suitable for use with UIGETFILE. See <a href="matlab:doc uigetfile">UIGETFILE documentation</a> for details.' );
            end
            obj.Pattern = value;
        end

        function set.Mode(obj,value)
            value = validatestring(value,{'get','put'},'','RootDirectory');
            obj.Mode = value;
        end

    end % Get/Set methods

end % classdef