function rootPath=isetbioRootPath()
% Return the path to the root visual modeling directory
%
% This function must reside in the directory at the base of the vismodel
% directory structure.  It is used to determine the location of various
% sub-directories.
% 
% Example:
%   fullfile(isetbioRootPath,'data')

% 07/27/17  dhb  Changed to index off of Contents.m, so as not to clutter isetbio root directory.

rootPath=which('isetbio/Contents');
[rootPath,~,~]=fileparts(rootPath);

return