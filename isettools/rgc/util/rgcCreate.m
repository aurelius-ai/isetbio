function obj = rgcCreate(type, sensor, outersegment, eyeSide, patchRadius, patchAngle)
% rgcCreate: generate an @rgcLinear, @rgcLNP or @rgcGLM object.
% 
%   rgc = rgcCreate(model type, scene, sensor, os, eyeSide, patchRadius, patchAngle)
% 
% Inputs: 
%       model type: 
%            'linear' - 
%            'LNP'    - linear-nonlinear-Poisson, see Pillow paper as below; only contains post-spike filter
%            'GLM'    - coupled generalized linear model, see Pillow paper, includes coupling filters  
%            'Subunit'- cones act as individual subunits
% 
%       scene:  a scene structure
%       sensor: a sensor structure
%       os:     a outer segment structure
%
%    Optional, but highly recommended:
%       eyeSide: 'left' or 'right', which eye the retinal patch is from
%       patchRadius: radius of retinal patch in microns
%       patchAngle: polar angle of retinal patch
%     [These inputs determine the size of spatial receptive fields, and are
%       necessary to accurately model physiological responses.]
% 
% Outputs: 
%   rgc object
% 
% The coupled-GLM model is described in Pillow, Shlens, Paninski, Sher,
% Litke, Chichilnisky & Simoncelli, Nature (2008).
% 
% The LNP and GLM models here are based on code by Pillow available at 
%       http://pillowlab.princeton.edu/code_GLM.html
% under the GNU General Public License.
%  
% See the initialize method for the @rgcLinear, @rgcLNP or @rgcGLM 
% subclasses for more details of the specific implementations.
%
% Example:
% % default values assumed for eyeSide, eyeRadius, eyeAngle.
%   rgc2 = rgcCreate('GLM', scene, sensor, os); 
%
%   eyeAngle = 180; % degrees
%   eyeRadius = 3; % mm
%   eyeSide = 'right';
%   rgc1 = rgcCreate('GLM', scene, absorptions, os, eyeSide, eyeRadius, eyeAngle);
%
% 
% JRG 9/2015

p = inputParser;
p.addParameter('type','

if nargin ~= 7
        warning('\nrgcCreate: create an isetbio @rgc object.\n' ...
            'rgcCreate(type, sensor, outersegment, eyeSide, patchRadius, patchAngle)\n'...
            'rgc1 = rgcCreate(''Linear'', scene, sensor, identityOS, ''right'', 3.0, 180);');
        return;
end

rgcType = 'linear';    % Default values
if ~isempty(varargin),   rgcType = ieParamFormat(varargin{1}); end

%% Create the proper object
switch rgcType
    case {'linear','rgclinear'}
        obj = rgcLinear(varargin{2:7});
    case {'lnp','rgclnp'}
        obj = rgcLNP(varargin{2:7});
    case {'glm','rgcglm'}
        obj = rgcGLM(varargin{2:7});
    case {'subunit','rgcsubunit'}
        obj = rgcSubunit(varargin{2:7});
    otherwise
        obj = rgcLinear(varargin{2:7});
end
