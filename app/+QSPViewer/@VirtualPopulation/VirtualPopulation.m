classdef VirtualPopulation < uix.abstract.CardViewPane
    % VirtualPopulation - View Pane for the object
    % ---------------------------------------------------------------------
    % Display a viewer/editor for the object
    %

    
    %   Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 285 $
    %   $Date: 2016-09-02 13:08:51 -0400 (Fri, 02 Sep 2016) $
    % ---------------------------------------------------------------------
   
       
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);        
    end
    
    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = VirtualPopulation(varargin)
            
            % Call superclass constructor
            RunVis = false;
            obj = obj@uix.abstract.CardViewPane(RunVis,varargin{:});
            
            % Create the graphics objects
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Mark construction complete to tell refresh the graphics exist
            obj.IsConstructed = true;
            
            % Refresh the view
            obj.refresh();
            
        end
        
    end %methods
    
    
    %RAJ - for callbacks:
    %notify(obj, 'DataEdited', <eventdata>);

    
    %% Callbacks
    methods
        
        function onFileSelection(vObj,h,e) %#ok<*INUSD>
            % Select file
            
            % Get string
            DataFilePath = e.NewValue;
            
            % Update the relative file path
            vObj.TempData.RelativeFilePath = DataFilePath;
            
            if exist(vObj.TempData.FilePath,'file')==2
                
                [StatusOK,Message,Header,Data] = importData(vObj.TempData, vObj.TempData.FilePath);
                if ~StatusOK
                    hDlg = errordlg(Message,'Error on Import','modal');
                    uiwait(hDlg);
                end
                
            end
            
            % Update the view
            update(vObj);
            
        end %function
        
    end
    
    
end %classdef