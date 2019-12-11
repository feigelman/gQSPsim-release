function [value,idx] = findArg( argname, varargin )
%findArg  Find a specific property value from a property-value pairs list
%
%   value = findParentArg(propname,varargin) parses the inputs as property-value
%   pairs looking for the named property. If found, the corresponding
%   value is returned. If not found an empty array is returned.
%
%   Examples:
%   >> uiextras.findArg('Parent','Padding',5,'Parent',1,'Visible','on')
%   ans =
%     1

%   Copyright 2009 The MathWorks Ltd.
%   $Revision: 272 $    
%   $Date: 2016-08-31 12:42:59 -0400 (Wed, 31 Aug 2016) $

narginchk( 1, inf ) ;

value = [];
idx = [];
if nargin>1
    props = varargin(1:2:end);
    values = varargin(2:2:end);
    if ( numel( props ) ~= numel( values ) ) || any( ~cellfun( @ischar, props ) )
        error( 'UIExtras:FindArg:BadSyntax', 'Arguments must be supplied as property-value pairs' );
    end
    myArg = find( strcmpi( props, argname ), 1, 'last' );
    if ~isempty( myArg )
        value = values{myArg};
        idx = myArg*2-1;
    end
end
