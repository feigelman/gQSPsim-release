classdef ListBuilderWithRunVisualize < uix.widget.ListBuilder
    % ListBuilderWithRunVisualize - A 
    % ---------------------------------------------------------------------
    % Create a ListBuilder widget with added Run and Visualize buttons. The
    % widget's Callback will be triggered and provided an eventdata
    % structure when the buttons are pressed.
    %
    % Syntax:
    %           w = uix.widget.ListBuilderWithRunVisualize('Property','Value',...)
    %
    % This widget extends uix.widget.ListBuilder and adds the following:
    %
    % Properties:
    %
    %   AllowRunVisMulti - indicates whether the Run and Visualize buttons
    %   should be enabled when multiple items are selected [true|(false)]
    %
    % Methods:
    %       none
    %
    % Examples:
    %
    %     AllItems = {'Alpha';'Bravo';'Charlie';'Delta';'Echo';'Foxtrot'};
    %     AddedIndex = 2:numel(AllItems);
    %     fig = figure;
    %     w = uix.widget.ListBuilderWithRunVisualize('Parent',fig,...
    %         'AllItems',AllItems,'AddedIndex',AddedIndex);
    %
    
    % Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 272 $
    %   $Date: 2016-08-31 12:42:59 -0400 (Wed, 31 Aug 2016) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties
        AllowRunVisMulti = false;
    end
    
    
    %% Constructor / Destructor
    methods
        
        function obj = ListBuilderWithRunVisualize( varargin )
            
            % Call superclass constructor
            obj = obj@uix.widget.ListBuilder(varargin{:});
            
            % Create additional buttons
            obj.h.Button(7) = uicontrol( ...
                'Parent', obj.UIContainer, ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'play_24.png' ), ...
                'TooltipString', 'Run the selected item.',...
                'Callback', @(h,e)onRunVisButtonPressed(obj,'Run') );
            obj.h.Button(8) = uicontrol( ...
                'Parent', obj.UIContainer, ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'visualize_24.png' ), ...
                'TooltipString', 'Visualize the selected item.',...
                'Callback', @(h,e)onRunVisButtonPressed(obj,'Visualize') );
            obj.ButtonVis(7:8) = true;
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.redraw();
            
        end %function
        
    end %methods - constructor/destructor
    
    
    %% Create and Redraw graphics
    methods ( Access = 'protected' )
        
        function redraw(obj)
            
            % Call superclass method first
            obj.redraw@uix.widget.ListBuilder();
            
            % Ensure the construction is complete
            if obj.IsConstructed && numel(obj.h.Button)>6
                NumSelected = numel(obj.SelectedListIndex);
                ThisEnable = NumSelected==1 || (obj.AllowRunVisMulti && NumSelected>1);
                set(obj.h.Button(7:8), 'Enable', uix.utility.tf2onoff(ThisEnable));
            end
            
        end %function
        
    end %methods
    
    
    %% Callback methods
    methods ( Access = 'protected' )
        
        function onRunVisButtonPressed(obj,ButtonId)
            
            % Call the callback
            evt = struct('Source',obj,...
                'Interaction', ButtonId,...
                'SelectedItems', obj.SelectedItems,...
                'SelectedAllIndex', obj.SelectedAllIndex,...
                'SelectedListIndex', obj.SelectedListIndex);
            obj.callCallback(evt);
            
            % Redraw the component
            obj.redraw();
            
        end %function onCopyButtonPressed
        
    end %methods
    
    
        %% Get/Set methods
    methods
        
        % AllowRunVisMulti
        function set.AllowRunVisMulti(obj,value)
            if obj.IsConstructed
                error('Property AllowRunVisMulti may not be changed after the ListBuilder is created.');
            end
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowRunVisMulti = value;
        end
        
    end % Get/Set methods
        
    
end %classdef