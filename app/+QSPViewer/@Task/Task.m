classdef Task < uix.abstract.CardViewPane
    % Task - View Pane for the object
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
        function obj = Task(varargin)
            
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
    methods (Hidden=true)
        
        function onProjectSelection(vObj,h,e)
            
            % Get string
            DataFilePath = e.NewValue;
            
            % Update the relative file path
            vObj.TempData.RelativeFilePath = DataFilePath;
            
            if exist(vObj.TempData.FilePath,'file')==2
                
                [StatusOK,Message] = importModel(vObj.TempData,vObj.TempData.FilePath,vObj.TempData.ModelName);
                if ~StatusOK
                    hDlg = errordlg(Message,'Error on Import','modal');
                    uiwait(hDlg);
                end
                
            end
            
            % Update the view
            update(vObj);
            
        end %function
        
        
        function onModelSelection(vObj,h,e)
            
            % Get model name
            ModelNameOptions = get(h,'String');
            ModelName = ModelNameOptions{get(h,'Value')}; %get(h,'String');
            
            if strcmpi(ModelName,QSP.makeInvalid('-'))
                ModelName = '';
            end
            
            [StatusOK,Message] = importModel(vObj.TempData,vObj.TempData.FilePath,ModelName);
            if ~StatusOK
                hDlg = errordlg(Message,'Error on Import','modal');
                uiwait(hDlg);
            end
            
            if ~isempty(vObj.TempData.ModelObj) && ~isempty(vObj.TempData.ModelObj.mObj)
                % get active variant names
                allVariantNames = get(vObj.TempData.ModelObj.mObj.Variants, 'Name');
                if isempty(allVariantNames)
                    allVariantNames = {};
                end
                vObj.TempData.ActiveVariantNames = allVariantNames(cell2mat(get(vObj.TempData.ModelObj.mObj.Variants,'Active')));

                 % get inactive reactions from the model
                allReactionNames = vObj.TempData.ReactionNames; 
                if isempty(allReactionNames)
                    allReactionNames = {};
                end
                vObj.TempData.InactiveReactionNames = allReactionNames(~cell2mat(get(vObj.TempData.ModelObj.mObj.Reactions,'Active')));

                % get inactive rules from model
                allRulesNames = vObj.TempData.RuleNames;
                if isempty(allRulesNames)
                    allRulesNames = {};
                end
                vObj.TempData.InactiveRuleNames = allRulesNames(~cell2mat(get(vObj.TempData.ModelObj.mObj.Rules,'Active')));
            end
            % Update the view
            update(vObj);
            
        end %function
        
        
        function onListSelection(vObj,h,e,List)
            
            switch List
                
                case 'Variants'
                    vObj.TempData.ActiveVariantNames = h.AddedItems;
                    
                case 'Doses'
                    vObj.TempData.ActiveDoseNames = h.AddedItems;
                    
                case 'Species'
                    vObj.TempData.ActiveSpeciesNames = h.AddedItems;
                    
                case 'Reactions'
                    vObj.TempData.InactiveReactionNames = h.AddedItems;
                    
                case 'Rules'
                    vObj.TempData.InactiveRuleNames = h.AddedItems;
                    
            end %switch
            
            % Update the view
            update(vObj);
            
        end %function
        
        
        function onEdit(vObj,h,e,Control)
            
            try
            switch Control
                
                case 'OutputTimes'
                    vObj.TempData.OutputTimesStr = get(h,'Value');
                case 'MaxWallClock'
                    vObj.TempData.MaxWallClockTime = str2double(get(h,'Value'));
                case 'RunSteadyState'
                    vObj.TempData.RunToSteadyState = logical(get(h,'Value'));
                case 'TimeSteadyState'
                    vObj.TempData.TimeToSteadyState = str2double(get(h,'Value'));
            end
            catch ME
                hDlg = errordlg(sprintf('Invalid value set. %s',ME.message),'Invalid Value','modal');
                uiwait(hDlg);
            end
            
            % Update the view
            update(vObj);
            
        end %function
        
    end %methods
        
    
end %classdef
