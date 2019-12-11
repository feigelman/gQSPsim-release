classdef (Abstract) HasTreeReference < handle
    % HasTreeReference - Mixin to provide a reference to a tree node
    % ---------------------------------------------------------------------
    % This mixin class provides a property for an object to reference a
    % tree node.
    %
    % The class must inherit this object to access the TreeNode property.
    %
    
    % Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 1434 $  $Date: 2016-08-02 16:46:39 -0400 (Tue, 02 Aug 2016) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (Hidden=true, Transient=true)
        TreeNode
    end
    
end %classdef