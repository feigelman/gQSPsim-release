function update(vObj)
% update - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           update(vObj)
%
% Inputs:
%           vObj - QSPViewer.Task vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 316 $  $Date: 2016-09-09 13:26:15 -0400 (Fri, 09 Sep 2016) $
% ---------------------------------------------------------------------


%% Invoke superclass's update

update@uix.abstract.CardViewPane(vObj);


%% Project, Model

FlagValidModel = true;
if ~isempty(vObj.TempData)
    set(vObj.h.ProjectFileSelector,...
        'RootDirectory',vObj.TempData.Session.RootDirectory,...
        'Value',vObj.TempData.RelativeFilePath)
    
    % check if the task data is out of date -- project file has changed
    
    if ~isempty(vObj.TempData.FilePath) % project is selected
        FileInfo = dir(vObj.TempData.FilePath);
%         if length(FileInfo)==1 && (isempty(vObj.TempData.LastSavedTime) || (vObj.TempData.LastSavedTime < FileInfo.datenum))
        if isempty(vObj.TempData.LastSavedTime) || length(FileInfo)==1 && (vObj.TempData.LastSavedTime < FileInfo.datenum)
            
            % reload model
            [StatusOK,Message] = importModel(vObj.TempData,vObj.TempData.FilePath,vObj.TempData.ModelName);
        end
    end
    
    ModelList = getModelList(vObj.TempData);
    
    if isempty(ModelList)
        FullModelList = {QSP.makeInvalid('-')};
        Value = 1;
        
        % Invalid model
        FlagValidModel = false;
    else
        Value = find(strcmpi(ModelList,vObj.TempData.ModelName));        
        % If ModelName is in the list
        if ~isempty(Value)
            FullModelList = ModelList;
        else
            FullModelList = unique(vertcat(ModelList(:),vObj.TempData.ModelName));
            MatchIdx = strcmp(FullModelList,vObj.TempData.ModelName);
            FullModelList(MatchIdx) = {QSP.makeInvalid(vObj.TempData.ModelName)};
            
            % Update Value since it is empty
            Value = numel(FullModelList);
            
            % Invalid model
            FlagValidModel = false;
        end
    end
    set(vObj.h.ModelPopup,'String',FullModelList,'Value',Value);
else
    % Invalid model
    FlagValidModel = false;
    set(vObj.h.ProjectFileSelector,'Value','')
    set(vObj.h.ModelPopup,'String',{QSP.makeInvalid('-')},'Value',1);
end
    

%% Variants, Doses, Species, Rules, Reactions

if ~isempty(vObj.TempData)
    
    InvalidNames = getInvalidActiveVariantNames(vObj.TempData);
    if iscell(vObj.TempData.VariantNames)
        VariantNames = vObj.TempData.VariantNames;
        [~,ix] = sort(upper(vObj.TempData.VariantNames));
        VariantNames = VariantNames(ix);
    else
        VariantNames = vObj.TempData.VariantNames;
    end
    ListItems = vertcat(VariantNames, InvalidNames);
    [~,AddedIndex] = ismember(vObj.TempData.ActiveVariantNames,ListItems);
    [~,InvalidIndex] = ismember(InvalidNames,ListItems);
    set(vObj.h.VariantsSelector,...
        'AllItems',ListItems,...
        'AddedIndex',AddedIndex,...
        'InvalidIndex',InvalidIndex,...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    
    InvalidNames = getInvalidActiveDoseNames(vObj.TempData);
    if iscell(vObj.TempData.DoseNames)        
        DoseNames = vObj.TempData.DoseNames;
        [~,ix] = sort(upper(vObj.TempData.DoseNames));
        DoseNames = DoseNames(ix);
        
    else
        DoseNames = vObj.TempData.DoseNames;
    end
    ListItems = vertcat( DoseNames,InvalidNames);
    [~,AddedIndex] = ismember(vObj.TempData.ActiveDoseNames,ListItems);
    [~,InvalidIndex] = ismember(InvalidNames,ListItems);
    set(vObj.h.DosesSelector,...
        'AllItems',ListItems,...
        'AddedIndex',AddedIndex,...
        'InvalidIndex',InvalidIndex,...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    
    InvalidNames = getInvalidActiveSpeciesNames(vObj.TempData);
     if iscell(vObj.TempData.SpeciesNames)
        SpeciesNames = vObj.TempData.SpeciesNames;
        [~,ix] = sort(upper(vObj.TempData.SpeciesNames));
        SpeciesNames = SpeciesNames(ix);        
     else
        SpeciesNames = vObj.TempData.SpeciesNames;
     end
    
    ListItems = vertcat( SpeciesNames,InvalidNames);
    [~,AddedIndex] = ismember(vObj.TempData.ActiveSpeciesNames,ListItems);
    [~,InvalidIndex] = ismember(InvalidNames,ListItems);
    set(vObj.h.SpeciesSelector,...
        'AllItems',ListItems,...
        'AddedIndex',AddedIndex,...
        'InvalidIndex',InvalidIndex,...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    
    InvalidNames = getInvalidInactiveReactionNames(vObj.TempData);
    if iscell(vObj.TempData.ReactionNames)
        ReactionNames = vObj.TempData.ReactionNames;
        [~,ix] = sort(upper(vObj.TempData.ReactionNames));
        ReactionNames = ReactionNames(ix);        
        
    else
        ReactionNames = vObj.TempData.ReactionNames;
    end
     
    ListItems = vertcat(ReactionNames,InvalidNames);
    [~,AddedIndex] = ismember(vObj.TempData.InactiveReactionNames,ListItems);
    [~,InvalidIndex] = ismember(InvalidNames,ListItems);
    set(vObj.h.ReactionsSelector,...
        'AllItems',ListItems,...  
        'AddedIndex',AddedIndex,...      
        'InvalidIndex',InvalidIndex,...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    
    InvalidNames = getInvalidInactiveRuleNames(vObj.TempData);
    if iscell(vObj.TempData.RuleNames)
        RuleNames = vObj.TempData.RuleNames;
        [~,ix] = sort(upper(vObj.TempData.RuleNames));
        RuleNames = RuleNames(ix);  
        
    else
        RuleNames = vObj.TempData.RuleNames;
    end
     
    ListItems = vertcat(RuleNames,InvalidNames);
    [~,AddedIndex] = ismember(vObj.TempData.InactiveRuleNames,ListItems);
    [~,InvalidIndex] = ismember(InvalidNames,ListItems);
    set(vObj.h.RulesSelector,...
        'AllItems',ListItems,...
        'AddedIndex',AddedIndex,...
        'InvalidIndex',InvalidIndex,...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
else
    set(vObj.h.VariantsSelector,'AllItems',cell(0,1),'AddedIndex',[],...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    set(vObj.h.DosesSelector,'AllItems',cell(0,1),'AddedIndex',[],...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    set(vObj.h.SpeciesSelector,'AllItems',cell(0,1),'AddedIndex',[],...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    set(vObj.h.RulesSelector,'AllItems',cell(0,1),'AddedIndex',[],...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    set(vObj.h.ReactionsSelector,'AllItems',cell(0,1),'AddedIndex',[],...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
end


%% Settings

if ~isempty(vObj.TempData)
    set(vObj.h.OutputTimesEdit,...
        'Value',vObj.TempData.OutputTimesStr,...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    set(vObj.h.MaxWallClockEdit,...
        'Value',num2str(vObj.TempData.MaxWallClockTime),...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    set(vObj.h.RunSteadyStateCheckbox,...
        'Value',vObj.TempData.RunToSteadyState,...
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    if vObj.TempData.RunToSteadyState
        set(vObj.h.TimeSteadyStateEdit,...            
        'Enable',uix.utility.tf2onoff(FlagValidModel));
    else
        set(vObj.h.TimeSteadyStateEdit,'Enable','off');
    end
    set(vObj.h.TimeSteadyStateEdit,'Value',num2str(vObj.TempData.TimeToSteadyState));
else
    set(vObj.h.OutputTimesEdit,'Value','','Enable',uix.utility.tf2onoff(FlagValidModel));
    set(vObj.h.MaxWallClockEdit,'Value','','Enable',uix.utility.tf2onoff(FlagValidModel));
    set(vObj.h.RunSteadyStateCheckbox,'Value',0,'Enable',uix.utility.tf2onoff(FlagValidModel));
    set(vObj.h.TimeSteadyStateEdit,'Value','','Enable',uix.utility.tf2onoff(FlagValidModel));
end