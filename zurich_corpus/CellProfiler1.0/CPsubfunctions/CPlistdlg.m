function [selection,value] = CPlistdlg(varargin)

% This CP function is present only so we can easily replace the
% listdlg if necessary.  See documentation for helpdlg for usage.

% $Revision: 5791 $

[selection,value] = listdlg(varargin{:});
