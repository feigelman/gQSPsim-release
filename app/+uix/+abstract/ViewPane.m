classdef (Abstract) ViewPane < uix.abstract.Widget & matlab.mixin.Heterogeneous & uix.mixin.HasCallback
    % ViewPane - A base class for building view panes
    % ---------------------------------------------------------------------
    % This is an abstract base class and cannot be instantiated. It
    % provides the basic properties needed for a view pane that will
    % contain a group of graphics objects to build a complex view pane.
    %
    
    %   Copyright 2008-2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 272 $
    %   $Date: 2016-08-31 12:42:59 -0400 (Wed, 31 Aug 2016) $
    % ---------------------------------------------------------------------
    
    properties ( SetObservable )
        Data
    end
    
    events( NotifyAccess = protected )
        DataEdited
    end
    
    %% Constructor
    methods
        function obj = ViewPane( varargin )
            
            % First step is to create the parent class. We pass the
            % arguments (if any) just incase the parent needs setting
            obj = obj@uix.abstract.Widget( varargin{:} );
            
            % Finally, parse any input arguments
            if nargin>1
                set( obj, varargin{:} );
            end
            obj.redraw();
        end        
    end
    
    methods (Access=protected)
        function redraw(obj)
        end
    end
    
    methods (Abstract=true,Access=public)
        refresh(obj)        
    end
    
    methods
        function set.Data(obj,Value)            
            obj.Data = Value;
            refresh(obj);            
        end
    end 
    
end % classdef
