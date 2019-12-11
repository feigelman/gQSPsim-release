function [idxNew, idxMovedTo] = shiftIndexInList(idxShift, nItems, shift)
% shiftIndexInList - Shift indices within a list
% -------------------------------------------------------------------------
% This function will shift position of one or more items in a list. It is
% useful for user interfaces where the user might select item(s) from a
% listbox and move them up or down. It accounts for stops at the beginning
% and end of the list.
%
% Syntax:
%       [idxNew, idxMovedTo] = uix.utility.shiftIndexInList(idxShift, nItems, shift)
%
% Inputs:
%       idxShift - indices to shift
%       nItems - number of items in the list (can't move past this limit)
%       shift - positions to shift the indicated items, positive integer 
%               for forward, negative for back
%
% Outputs:
%       idxNew - new indices for the whole list, from 1:nItems
%       idxMovedTo - new indices in the list for the items that just moved
%
% Examples:
%
%     >> idxShift = [5 6 9 10];
%     >> nItems = 10;
%     >> shift = 1;
%     >> [idxNew, idxMovedTo] = uix.utility.shiftIndexInList([5 6 9 10], 10, 1)
% 
%     idxNew =
%          1     2     3     4     7     5     6     8     9    10
% 
%     idxMovedTo =
%          6     7     9    10
%
% Notes: 
%       If the end of the list is hit, items hitting that limit will not be
%       moved.
%

% Copyright 2016 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 272 $  $Date: 2016-08-31 12:42:59 -0400 (Wed, 31 Aug 2016) $
% ---------------------------------------------------------------------

% Validate inputs
validateattributes(nItems,{'numeric'},{'finite','nonnegative','integer'});
validateattributes(idxShift,{'numeric'},{'vector','finite','positive','integer','increasing','<=',nItems});
validateattributes(shift,{'numeric'},{'integer','scalar'});

% Make indices to all items as they are now
idxNew = 1:nItems;

% Prepare the indices of the shifted items
idxShift = sort(idxShift);

% Find the last stable item that doesn't move
[~,idxStable] = setdiff(idxNew, idxShift, 'stable');
if ~isempty(idxStable)
    idxFirstStable = idxStable(1);
    idxLastStable = idxStable(end);
else
    idxFirstStable = inf;
    idxLastStable = 0;
end

% Track the new positions
idxMovedTo = idxShift;

% Which way do we loop?
if shift > 0 %Shift to end
    
    for idxToMove=numel(idxShift):-1:1
        
        % Calculate if there's room to move this item
        idxThisBefore = idxShift(idxToMove);
        ThisShift = max( min(idxLastStable-idxThisBefore, shift), 0 );
        
        % Where does this item move from/to
        idxThisAfter = idxThisBefore + ThisShift;
        idxMovedTo(idxToMove) = idxThisAfter;
        
        % Where do other items move from/to
        idxOthersBefore = idxShift(idxToMove)+1:1:idxThisAfter;
        idxOthersAfter = idxOthersBefore - ThisShift;
        
        % Move the items
        idxNew([idxThisAfter idxOthersAfter]) = idxNew([idxThisBefore idxOthersBefore]);
            
    end
    
elseif shift < 0 %Shift to start
    
    for idxToMove=1:numel(idxShift)
        
        % Calculate if there's room to move this item
        idxThisBefore = idxShift(idxToMove);
        ThisShift = min( max(idxFirstStable-idxThisBefore, shift), 0 );
        
        % Where does this item move from/to
        idxThisAfter = idxThisBefore + ThisShift;
        idxMovedTo(idxToMove) = idxThisAfter;
        
        % Where do other items move from/to
        idxOthersBefore = idxThisAfter:1:idxShift(idxToMove)-1;
        idxOthersAfter = idxOthersBefore - ThisShift;
        
        % Move the items
        idxNew([idxThisAfter idxOthersAfter]) = idxNew([idxThisBefore idxOthersBefore]);
            
    end
    
    
else % No shift
    
    % Do nothing
    
end

