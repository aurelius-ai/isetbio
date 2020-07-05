function fullfilename = navarroLensCreate(filename,varargin)
% Write out the Navarro lens file for a given accomodation
%
% Syntax:
%   fullfilename = navarroLensCreate(filename,varargin)
%
% Description:
%    Write out a Navarro lens file.
%
% Inputs:
%    filename - String. The filename to write to
%
% Optional key/value pairs:
%    accommodation: The accommodation in diopters (this is the distance to
%                   the in-focus object plane.  In ISET3d recipes this is
%                   the object distance.)  Default is 0.1 diopters (10
%                   meters).
%
% Outputs:
%    None.
%
% See also
%   setNavarroAccommodation

% Examples:
%{
  fname = fullfile(isetRootPath,'data','lens','navarro.dat');
  fullName = navarroLensCreate(fname);
  edit(fullName);
%}

%% 
p = inputParser;
p.addRequired('filename',@ischar);
p.addParameter('accommodation',0.1,@isnumeric);  % Distant accommodation by default
p.parse(filename,varargin{:});
A = p.Results.accommodation;

%% These equations are from Table 4 in Navarro's paper.
anteriorRadius   = 10.2 - 1.75 * log(A + 1);
posteriorRadius  = -6 + 0.2294 * log(A + 1);
aqueousThickness = 3.05 - 0.05 * log(A + 1);
lensThickness    = 4 + 0.1 * log(A + 1);
anteriorAsph     = -3.1316 - 0.34 * log(A + 1);
posteriorAsph    = -1 - 0.125 * log(A + 1);

% Columns are: radiusX, radiusY, thickness, materialIndex, semiDiameter, 
% conicConstantX, and conicConstantY
corneaA = [-7.72, -7.72, 0.55, 1, 4.820, -0.26, -0.26];
corneaP = [-6.5, -6.5, 3.050, 2, 4.341, 0, 0];
pupil   = [0, 0, 0, 2, 2, 0, 0];
lensA   = [-10.2, -10.2, 4, 3, 3.750, -3.132, -3.132];
lensP   = [6, 6, 0, 4, 3.750, -1, -1];

% flip these because of sign conventions
lensA(1:2) = [anteriorRadius anteriorRadius] * -1;
lensP(1:2) = [posteriorRadius posteriorRadius] * -1;

corneaP(3) = aqueousThickness;
lensA(3)   = lensThickness;
lensA(6:7) = [anteriorAsph anteriorAsph];
lensP(6:7) = [posteriorAsph posteriorAsph];

%% Build matrix

lensMatrix = [corneaA; corneaP; pupil; lensA; lensP];

focalLength = 1 / (60.6061 + A) * 10 ^ 3; % mm
fid = fopen(filename, 'w');

str = sprintf('# Focal length (mm) \n');
fprintf(fid, '%s', str);
str = sprintf('%.3f\n', focalLength);
fprintf(fid, '%s', str);
str = sprintf(['# radiusX radiusY thickness materialIndex semiDiameter' ...
    ' conicConstantX conicConstantY\n']);
fprintf(fid, '%s', str);
for ii = 1:size(lensMatrix, 1)
    fprintf(fid, '%f\t%f\t%f\t%f\t%f\t%f\t%f\n', ...
        lensMatrix(ii, 1), lensMatrix(ii, 2), lensMatrix(ii, 3), ...
        lensMatrix(ii, 4), lensMatrix(ii, 5), lensMatrix(ii, 6), ...
        lensMatrix(ii, 7));
end

str = sprintf('\n# Accommodation (Diopters) %f \n',A);
fprintf(fid, '%s', str);
str = '# See navarroLensCreate.m for adjusting accommodation';
fprintf(fid,'%s\n',str);
fclose(fid);

%%
fullfilename = which(filename);

end
