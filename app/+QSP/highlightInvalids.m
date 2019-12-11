function [FullListWithInvalids,FullList,Value] = highlightInvalids(RawList,Name,varargin)
% Merge Name into the RawList into FullList. If Name does not exist in
% RawList, then mark it as invalid in FullList.

if nargin > 2 && islogical(varargin{1})
    ForceMarkAsInvalid = varargin{1};
else
    ForceMarkAsInvalid = false;
end

if ischar(Name)
    Name = {Name};
else
    Name = Name(:);
end
if ischar(RawList)
    RawList = {RawList};
else
    RawList = RawList(:);
end

if isempty(RawList) && isempty(Name)
    FullList = {'-'};
    FullListWithInvalids = {QSP.makeInvalid('-')};    
    Value = 1;
else
    FullList = unique(vertcat(RawList,Name));
    FullListWithInvalids = FullList;
    
    % Check if the Selection was in the original list
    IsNotInRawList = ~ismember(Name,RawList);
    [~,Value] = ismember(Name,FullList);
    if any(IsNotInRawList) || ForceMarkAsInvalid
        % Highlight
        for idx = 1:numel(Value)
            FullListWithInvalids{Value(idx)} = QSP.makeInvalid(FullListWithInvalids{Value(idx)});
        end
    end
    
end