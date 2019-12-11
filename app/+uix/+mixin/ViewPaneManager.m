classdef (Abstract) ViewPaneManager < handle
    % ViewPaneManager - Mixin to provide management of multiple view panes
    % ---------------------------------------------------------------------
    % This mixin class provides management of multiple view panes. The
    % panes may be constructed or deleted as needed, but inactive panes
    % will be unparented to maximize performance of the application window.
    %
    %

    % Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 1450 $  $Date: 2016-08-23 08:58:50 -0400 (Tue, 23 Aug 2016) $
    % ---------------------------------------------------------------------

    %TODO
    % 1. Put string on empty pane?
    % 2. Array obj handling?


    %% Properties
    properties (SetAccess = private)
        Panes = uix.abstract.ViewPane.empty(0,1)
        ActivePane = uix.abstract.ViewPane.empty(0,1)
    end

    properties (SetAccess=protected)
        ViewPaneParent = matlab.graphics.GraphicsPlaceholder.empty(0,0)
        DataPackage = ''
        ViewPackage = ''
    end

    properties (SetAccess=protected, Dependent=true)
        PaneTypes
    end

    properties (Access=private, Constant=true)
        NoParent_ = matlab.graphics.GraphicsPlaceholder.empty(0,0)
    end

    properties( Access = private )
        DataEditedListener = event.listener.empty(0,1)
        BusyIcon
    end


    %% Abstract Methods
    methods (Abstract, Access=protected)
        onDataChanged(obj,h,e) %Triggered when data is changed in a ViewPane
    end

    
    %% Constructor
    methods
        function obj = ViewPaneManager( )
            
            % Wait indicator is an animated gif that must be displayed on a
            % button using HTML to render correctly.
%             IconPath = uix.utility.findIcon('loading.gif');
%             IconHTMLString = sprintf('<html><img src="file:/%s"/></html>',IconPath);
            obj.BusyIcon = matlab.ui.control.UIControl(...
                'Parent',obj.NoParent_,...
                'Style','pushbutton',...
                'Enable','inactive',...
                'String','Loading...',...IconHTMLString,...
                'FontSize',14,...
                'ForegroundColor',[0 0 0],...
                'Units','normalized',...
                'Position',[0 0 1 1],...
                'Visible','on');
        end
    end
    
    

    %% Methods
    methods (Access=protected)
        
        function clearPane(obj)
            % Deactivate all panes
            obj.deactivate();
        end

        function launchPane(obj, Data, PaneType, varargin)
           % This method may be overloaded as needed

            % Is the data empty?
            if nargin < 2

                % Deactivate all panes
                obj.deactivate();

            else

                % What type of view pane do we need for the data?
                if nargin<3 || isempty(PaneType)
                    PaneType = strrep(class(Data), obj.DataPackage, obj.ViewPackage);
                end
                
                % Is the pane loaded?
                idxPane = find(strcmp(PaneType, obj.PaneTypes), 1);
                if isempty(idxPane)

                    % Launch the pane
                    obj.launch(PaneType);

                else

                    % Activate the pane
                    obj.activate(idxPane)

                end

                % Assign data
                assignPaneData(obj, Data, varargin{:});

            end %if isempty(Data)

        end %function


        function assignPaneData(obj, Data, varargin)
            % This method may be overloaded as needed. If additional inputs
            % are needed (via varargin), it must be overloaded.

            % Assign data to the pane
            if ~isempty(obj.ActivePane)
                try
                    obj.ActivePane.Data = Data;
                catch err
                    warning('uix:ViewPaneManager:AssignData',...
                        'Unable to assign data to ViewPane %s.\nError: %s',...
                        class(obj.ActivePane), err.message);
                end
            end

        end %function


    end %methods



    %% Private methods
    methods (Access=private)

        function launch(obj, PaneType)

            % Is there a view pane of this type?
            if exist(PaneType,'class')

                % Attempt to launch
                try
                    % Show wait indicator
                    % Iraj
                    set(obj.BusyIcon,'Parent',obj.ViewPaneParent); drawnow
                    
                    fLaunch = str2func(PaneType);
                    hPane = fLaunch();

                    % Validate the correct pane was launched
                    validateattributes(hPane,{'uix.abstract.ViewPane'},{'scalar'});

                    % Track the new pane
                    idxPane = numel(obj.Panes) + 1;
                    obj.Panes(idxPane,1) = hPane;

                    % Create listener
                    obj.DataEditedListener(end+1,1) = event.listener(hPane,...
                        'DataEdited', @obj.onDataChanged );

                catch err

                    warning('uix:ViewPaneManager:LaunchViewFail',...
                        'Unable to launch ViewPane for %s.\nError: %s',...
                        PaneType, err.message);
                    
                    % Update wait indicator
                    % Iraj
                    set(obj.BusyIcon,'Parent',obj.NoParent_); drawnow

                    % Deactivate all and return
                    obj.deactivate();
                    return

                end
                
                % Activate the pane
                obj.activate(idxPane)
                
                % Update wait indicator
                % Iraj
                set(obj.BusyIcon,'Parent',obj.NoParent_); drawnow
                
            else
                % No view pane available

                warning('uix:ViewPaneManager:NoView',...
                        'No available ViewPane for %s.', PaneType);

                % Deactivate all
                obj.deactivate();

            end %if exist(PaneType,'class')


        end %function

        
        function activate(obj, idxPane)

            % Default to all panes inactive
            IsActive = false(size(obj.Panes));
            IsActive(idxPane) = true;

            % Track the active pane
            obj.ActivePane = obj.Panes(IsActive);

            % Deactivate other panes
            obj.deactivate(~IsActive);

            % Parent the active panel
            set(obj.ActivePane, 'Parent', obj.ViewPaneParent);

        end

        
        function deactivate(obj, idxPane)

            % Deactivate all if unspecified
            if nargin<2
                idxPane = true(size(obj.Panes));
            end

            % Unparent inactive panes
            ThesePanes = obj.Panes(idxPane);
            for idx = 1:numel(ThesePanes)
                set(ThesePanes(idx), 'Parent', obj.NoParent_);
                
                % Track the active pane
                if ~isempty(obj.ActivePane) && any(obj.ActivePane == ThesePanes(idx))
                    obj.ActivePane = obj.NoParent_;
                end
            end

        end

    end %methods



    %% Get/set methods
    methods

        function value = get.PaneTypes(obj)
            value = cell(size(obj.Panes));
            for idx=1:numel(obj.Panes)
                value{idx} = class(obj.Panes(idx));
            end
        end
        
        function set.ViewPaneParent(obj,value)
            obj.ViewPaneParent = value;
            if ~isempty(value)
                bgColor = get(obj.ViewPaneParent,'BackgroundColor');
                % Iraj
                set(obj.BusyIcon,...
                    ...'ForegroundColor',bgColor,...
                    'BackgroundColor',bgColor) %#ok<MCSUP>
            end
        end

    end

end %classdef