function pathname = findIcon(imagefilename)
%findIcon  Find an icon path
%
%   pathname = uix.utility.findIcon(filename) returns the path to an icon
%   within the uix package.
%

%   Copyright 2016 The MathWorks Ltd.
%   $Revision: 272 $    
%   $Date: 2016-08-31 12:42:59 -0400 (Wed, 31 Aug 2016) $

persistent icon_dir

if exist(imagefilename, 'file')
    
    pathname = which(imagefilename);
    
else
    
    if isempty(icon_dir)
        this_dir = fileparts( fileparts( mfilename( 'fullpath' ) ) );
        icon_dir = fullfile( this_dir, '+resource' );
    end
    
    pathname = fullfile( icon_dir, imagefilename );
    if ~exist(pathname, 'file')
        warning( 'uix:utility:loadIcon:BadFile', 'file not found: ''%s''', imagefilename );
        pathname = '';
    end
    
end
