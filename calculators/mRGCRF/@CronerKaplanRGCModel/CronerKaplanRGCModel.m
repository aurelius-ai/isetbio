classdef CronerKaplanRGCModel < handle
    % Create a CronerKaplan RGC Model
    
    % References:
    %    Croner&Kaplan (1994). 'Receptive fields of P and M Ganglion cells 
    %    across the primate retina.',Vis. Res, (35)(1), pp.7-24
    % History:
    %    11/8/19  NPC, ISETBIO Team     Wrote it.
    
    
    properties (SetAccess = private)
        % Digitized data from Figure 4 & 5
        centerData;
        surroundData;
        
        % Synthesized data
        synthesizedData;
        
        % Model of center radius with eccentricity
        centerRadiusFunction;
        centerRadiusThreshold;
        centerRadiusParams;
        centerRadiusParamsSE;
        
        % Model of surround radius with eccentricity
        surroundRadiusFunction;
        surroundRadiusThreshold;
        surroundRadiusParams;
        surroundRadiusParamsSE;
        
        % Model of center sensitivity with center radius
        centerPeakSensitivityFunction;
        centerPeakSensitivityParams;
        centerPeakSensitivityParamsSE;
        
        % Model of surround sensitivity with surround radius
        surroundPeakSensitivityFunction;
        surroundPeakSensitivityParams;
        surroundPeakSensitivityParamsSE;
        
        % Valid quadrant names for the Polans wavefront-based optics
        validPolansQuadrants = {'horizontal', 'superior', 'inferior'};
        validPolansSubjectIDs = 1:10;
        
        % Directory with psf deconvolution results
        psfDeconvolutionDir;
        
        synthesisOptions;
        
        plotlabOBJ;
    end
    
    methods
        % Constructor
        function obj = CronerKaplanRGCModel(varargin) 
            % Parse input
            p = inputParser;
            p.addParameter('generateAllFigures', true, @islogical);
            p.addParameter('instantiatePlotLab', true, @islogical);
            p.addParameter('dataSetToFit', 'medians', @(x)(ismember(x, {'medians', 'raw', 'paperFormulas'})));
            p.parse(varargin{:});
            
            obj.psfDeconvolutionDir = strrep(fileparts(which(mfilename())), ...
                '@CronerKaplanRGCModel', 'VisualToRetinalCorrectionData/DeconvolutionData');
            
            obj.loadRawData();
            obj.fitModel('dataset', p.Results.dataSetToFit);
            
            obj.synthesisOptions = struct( ...
                'randomizeCenterRadii', true, ...
                'randomizeCenterSensitivities', true, ...
                'randomizeSurroundRadii', true, ...
                'randomizeSurroundSensitivities', true);
            
            if (p.Results.instantiatePlotLab)
                obj.setupPlotLab(0, 14, 14);
            end
            
            if (p.Results.generateAllFigures)
                obj.plotDigitizedData();
            end
        end
        
        % Fit the model to a data set, either 'medians', or 'raw'
        fitModel(obj, varargin);
        
        % Method to synthesize data for a sample of eccentricity values
        synthesizeData(obj, eccDegs, synthesisOptions);
        
        % Method to plot different aspects of the synthesized data
        [hFig1, hFig2, hFig3, hFig4] = plotSynthesizedData(obj);
        
        % Method to simulate the Croner&Kaplan results
        simulateCronerKaplanResults(obj, varargin);
        
        % Generate the Gaussian-PSF deconvolution analysis data files
        generateDeconvolutionFiles(obj, deconvolutionOpticsParams, varargin);

        % Generate the deconvolution model (operates on the output of
        % performGaussianConvolutionWithPolansPSFanalysis()) - no printing
        deconvolutionModel = computeDeconvolutionModel(obj, deconvolutionOpticsParams);
        
        % Method to generate retinal RF params given the retinal center radius
        % and eccentricity as inputs. This uses (via computeDeconvolutionModel()),
        % the Gaussian-PSF convolution data generated by performGaussianConvolutionWithPolansPSFanalysis().
        % It is to be used with mRGC mosaics whose centers are determined by connectivity to an underlying
        % cone mosaic.
        synthesizedRFParams = synthesizeRetinalRFparamsConsistentWithVisualRFparams(obj, retinalCenterRadii, retinalCenterMicrons, deconvolutionOpticsParams);
    end
    
    methods (Static)
        plotSensitivities(theAxes, d, model, pointSize, color,displayYLabel, theLabel);
        
        plotRadii(theAxes, d, model, pointSize, color, displayYLabel, theLabel);
        
        
        % Generate a cone mosaic for performing the deconvolution analysis
        [theConeMosaic, theConeMosaicMetaData] = generateConeMosaicForDeconvolution(patchEcc, patchSize, varargin);
        
        % Generate Polans optics for performing the deconvolution analysis
        theOptics = generatePolansOpticsForDeconcolution(PolansSubjectID, imposedRefractionErrorDiopters, ...
            pupilDiameterMM , wavelengthSampling, micronsPerDegree, patchEcc, varargin);
        
        % Generate Polans PSF at desired eccentricitiy
        [hEcc, vEcc, thePSFs, thePSFsupportDegs, theOIs] = psfsAtEccentricity(goodSubjects, ...
            imposedRefractionErrorDiopters, desiredPupilDiamMM, wavelengthsListToCompute, ...
            micronsPerDegree, wavefrontSpatialSamples, eccXrange, eccYrange, deltaEcc, varargin);
        
        data = quadrantData(allQuadrantData, quadrantsToAverage, quadrantsComputed, subjectsToAverage, subjectsComputed);
        
        plotDeconvolutionModel(deconvolutionModel);
    end
    
    methods (Access=private)
        setupPlotLab(obj, mode, figWidthInches, figHeightInches);
        
        % Method to validate the deconvolutionOpticsParams
        validateDeconvolutionOpticsParams(obj,deconvolutionOpticsParams);
    end
    
end

