classdef WatsonRGCModel
    % Create a WatsonRGCModel
    %
    %
    % Syntax:
    %   cMosaic = WatsonRGCModel('generateAllFigures', false);
    %
    % Usage:
    % - Compute peak cone density:
    %   peakConeDensityPerMM2 = WatsonRGCCalc.peakConeDensity('cones per mm2')   
    %   peakConeDensityPerMM2 = WatsonRGCCalc.peakConeDensity('cones per deg2')   
    %
    % References:
    %    Watson (2014). 'A formula for human RGC receptive field density as
    %    a function of visual field location', JOV (2014), 14(7), 1-17.
    %
    % History:
    %    11/8/19  NPC, ISETBIO Team     Wrote it.
    
    % Constant properties (model parameters)
    properties (Constant)
        % Meridian parameters
        meridianParamsTable = {
            'temporal meridian'  struct('a_k', 0.9851, 'r_2k', 1.058,  'r_ek', 22.14); ...
            'superior meridian'  struct('a_k', 0.9935, 'r_2k', 1.035,  'r_ek', 16.35); ...
            'nasal meridian'     struct('a_k', 0.9729, 'r_2k', 1.084,  'r_ek',  7.633); ...
            'inferior meridian'  struct('a_k', 0.996,  'r_2k', 0.9932, 'r_ek', 12.13);
        }
     
        % Various acronyms and their meaning in the Watson (2014) paper
        glossaryTable = {
             'mRGCf'    'midget RGC receptive field'; ...
             'g'        'RGC'; ...
             'm'        'midget RGC'; ...
             'c'        'cone'; ...
             'gf'       'RGC receptive field'; ...
             'mf'       'midget RGC receptive field'; ...
             'dc(0)'    'peak cone density (at 0 deg eccentricity)'; ...
             'f0'       'fraction of all ganglion cells that are midget at 0 deg eccentricity'; ...
             'alpha',   'Conversion factor mm^2 -> deg^2 as a function of eccentricity' ...
        };
     
        % Fraction of all ganglion cells that are midget at 0 deg eccentricity
        f0 = 1/1.12;
             
        % Peak cone density (cones/deg^2) at 0 deg eccentricity
        dc0 = 14804.6;
        
        % Conversion factor, alpha, of mm^2 -> deg^2 as a function of eccentricity in
        % degs (Equation A7)
        alpha = @(eccDegs) 0.0752 + ...
                    5.846 * 1e-5 * eccDegs    + ...
                   -1.064 * 1e-5 * eccDegs.^2 + ...
                    4.116 * 1e-8 * eccDegs.^3;
    end
   
    % Constant properties related to figure generation
    properties (Constant)
        paperTitleFull = 'Watson (2014): ''A formula for human RGC receptive field density as a function of visual field location'' ';
        paperTitleShort = 'Watson (2014) RGC model';
    end

    % Public properties (read-only)
    properties (SetAccess = private)
       % Dictionary with various acronyms of the the Watson (2014) paper and their meaning
       glossary;
       
       % Dictionary with meridian params indexed by meridian name
       meridianParams;
       
       % Struct with default preferences for all figures
       defaultFigurePrefs = struct(...
            'lineWidth', 1.5, ...
            'fontSize', 14, ...
            'fontAngle', 'italic', ...
            'grid', 'on', ...
            'backgroundColor', [1 1 1]);
    end
       
    % Public properties
    properties
        % Struct with default preferences for all figures
        figurePrefs
    end
    
    % Public methods (class interface)
    methods
        % Constructor
        function obj = WatsonRGCModel(varargin) 
            % Parse input
            p = inputParser;
            p.addParameter('generateAllFigures', false, @islogical);
            p.parse(varargin{:});
            
            % Set the default figure preferences
            obj.figurePrefs = obj.defaultFigurePrefs;
            
            % Set options
            generateAllFigures = p.Results.generateAllFigures;
            
            % Create dictionary with various acronyms of the the Watson (2014) paper and their meaning
            obj.glossary = containers.Map(obj.glossaryTable(:,1), obj.glossaryTable(:,2));
            
            % Create dictionary with meridian params 
            obj.meridianParams = containers.Map(obj.meridianParamsTable(:,1), obj.meridianParamsTable(:,2));
            
            % Generate figures
            if (generateAllFigures)
                obj.generateFigure5();
                obj.generateFigureA2();
            end
        end
        
        % Convert retinal area from deg^2 to mm^2 for a given eccentricity
        val = mmSquaredToDegSquared(obj, mmSquared, eccDegs);
        
        % Convert retinal area from deg^2 to mm^2 for a given eccentricity
        val = degSquaredToMMSquared(obj, degSquared, eccDegs);
        
        % Return peak cone density (#cones per either deg^2 or mm^2)
        val = peakConeDensity(obj, units);
        
        % Return peak midget and peak total RGC receptive field density (#RFs per either deg^2 or mm^2)
        [peakMidgetRGCRFDensity, peakRGCRFDensity] = peakRGCRFDensity(obj, units);
        
        % Return total RGC density at the requested eccentricities (#RFs per either deg^2 or mm^2)
        val = totalRGCRFDensity(obj, eccDegs, meridian, units);
        
        % Figure generation methods
        generateFigure5(obj);
        generateFigureA2(obj);
    end
end
