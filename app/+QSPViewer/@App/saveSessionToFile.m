function StatusOk = saveSessionToFile(obj,FilePath,idx)
% saveSessionToFile
% -------------------------------------------------------------------------
% Abstract: This method is executed when the user wants to save the current
% session to a file
%

% Copyright 2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 196 $  $Date: 2016-07-25 15:35:50 -0400 (Mon, 25 Jul 2016) $
% ---------------------------------------------------------------------

% Save the data to MAT format
StatusOk = true;
try
    s.Session = obj.Session(idx); %#ok<STRNU>
    save(FilePath,'-struct','s');
catch err
    StatusOk = false;
    Message = sprintf('The file %s could not be saved:\n%s',...
        FilePath, err.message);
    hDlg = errordlg(Message,'Save File','modal');
    uiwait(hDlg);
end