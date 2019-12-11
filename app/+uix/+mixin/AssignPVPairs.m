classdef (Abstract) AssignPVPairs < handle
    % AssignPVPairs - Mixin to assign PV pairs to public properties
    % ---------------------------------------------------------------------
    % This mixin class provides a method to assign PV pairs to populate
    % public properties of a handle object. This is typically performed in
    % a constructor.
    %
    % The class must inherit this object to access the method. Call the
    % protected method like this to assign properties:
    %
    %     % Assign PV pairs to properties
    %     obj.assignPVPairs(varargin{:});
    %
    %       or
    %
    %     % Assign PV pairs to properties and return non-matches
    %     UnmatchedPairs = obj.assignPVPairs(varargin{:});
    %
    % Methods of uix.abstract.AssignPVPairs:
    %
    %   varargout = assignPVPairs(obj,varargin) - assigns the
    %   property-value pairs to matching properties of the object
    %
    
    % Copyright 2015-2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 1387 $  $Date: 2016-07-08 14:13:20 -0400 (Fri, 08 Jul 2016) $
    % ---------------------------------------------------------------------
    
    %RAJ - does this need to inherit from handle?
    
    methods (Access = protected)
        
        function varargout = assignPVPairs(obj,varargin)
            
            % Get a list of public properties
            metaObj = metaclass(obj);
            PropNames = {metaObj.PropertyList.Name}';
            isSettableProp = strcmp({metaObj.PropertyList.SetAccess}','public');
            PublicPropNames = PropNames(isSettableProp);
            
            % Create a parser for all public properties
            p = inputParser;
            if nargout
                p.KeepUnmatched = true;
            end
            for pIdx = 1:numel(PublicPropNames)
                p.addParameter(PublicPropNames{pIdx}, obj.(PublicPropNames{pIdx}));
            end
            
            % Parse the P-V pairs
            p.parse(varargin{:});
            
            % Set just the parameters the user passed in
            ParamNamesToSet = varargin(1:2:end);
            
            % Assign properties
            for ThisName = ParamNamesToSet
                obj.(ThisName{1}) = p.Results.(ThisName{1});
            end
            
            % Return unmatched pairs
            if nargout
                varargout{1} = p.Results.Unmatched;
            end
            
        end %function
        
    end %methods
    
end %classdef