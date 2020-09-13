function MosaicConnector

    % Define constants
    global LCONE_ID
    global MCONE_ID
    global SCONE_ID 

    LCONE_ID = 2;
    MCONE_ID = 3;
    SCONE_ID = 4;
    
    rootDir = fileparts(which(mfilename()));
    tmpDir = fullfile(rootDir, 'tmpMatFiles');
    exportsDir = fullfile(rootDir, 'exports');
    responseFilesDir = fullfile(rootDir, 'responseFiles');
    
    doInitialMosaicCropping = ~true;                        % phase 1 - crop within circular window
    checkMosaicSeparationAndCropAgain = ~true;              % phase 2 - check separation and possibly crop within rectangular window
    assignConeTypes = ~true;                                % phase 3 - assign cone types
    
    connectConesToRGCcenters = ~true;                        % phase 4 - connect cones to RGC RF centers
    visualizeConeToRGCcenterConnections = ~true;            % phase 5 - visualize cone inputs to RGC RF centers
    computeConeWeightsToRGCcentersAndSurrounds = ~true;      % phase 6 - compute cone weights to RGC RF center/surrounds
    visualizeConeWeightsToRGCcentersAndSurrounds = ~true;   % phase 7 - visualize cone weights to RGC RF center/surrounds
    
    wirePartOfMRGCMosaicToConeMosaicPatch = true;           % phase X - wire part of a full RGC mosaic to a small cone mosaic
    
    coVisualizeRFsizeWithDendriticFieldSize = ~true;        % Phase 10
    
    % Configure the phase run parameters
    connector = containers.Map();
    
    % Large mosaic
    inputMosaic = struct('fov',40, 'eccSamples', 482);
    
    
    % Phase1: isolate the central (roiRadiusDeg) mosaic
    connector('phase1') = struct( ...
        'run', doInitialMosaicCropping, ...
        'runFunction', @runPhase1, ...
        'whichEye', 'right', ...                                    // input mosaic params
        'mosaicFOVDegs', inputMosaic.fov, ...                       // input mosaic params
        'eccentricitySamplesNumCones', inputMosaic.eccSamples, ...  // input mosaic params
        'eccentricitySamplesNumRGC', inputMosaic.eccSamples, ...    // input mosaic params
        'roiRadiusDeg', Inf, ...                 // processing params
        'outputFile','roiMosaic', ...
        'outputDir', tmpDir ...
    );
        
    % Phase 2: Check that rfs are not less than a threshold (x mean spacing). If any rfs
    % are found with a separation less than that, an error is thrown. Also
    % crop to desired size
    roiCropDegs = struct('xo', 0.0, 'yo', 0.0, 'width', 45, 'height',35);
    %roiCropDegs = struct('xo', 0.0, 'yo', 0.0, 'width', 30, 'height',4);
    postFix = sprintf('eccX_%2.1f_eccWidth_%2.1f_eccHeight_%2.1f', roiCropDegs.xo, roiCropDegs.width, roiCropDegs.height);
    
    connector('phase2') = struct( ...
        'run', checkMosaicSeparationAndCropAgain, ...
        'runFunction', @runPhase2, ...
        'inputFile', connector('phase1').outputFile, ...
        'roiRectDegs', roiCropDegs, ...                                 // cropped region to include
        'thresholdFractionForMosaicIncosistencyCorrection', 0.6, ...    // separation threshold for error
        'outputFile', sprintf('%s__CheckedStats', sprintf('%s_%s',connector('phase1').outputFile, postFix)),...
        'outputDir', tmpDir ...
    );

    % Phase 3: Assign cone types to the coneMosaic
    connector('phase3') = struct( ...
        'run', assignConeTypes, ...
        'runFunction', @runPhase3, ...
        'inputFile', connector('phase2').outputFile, ...
        'tritanopicAreaDiameterMicrons', 2.0*1000*WatsonRGCModel.rhoDegsToMMs(0.3/2), ...        // Tritanopic region size: 0.3 deg diam
        'relativeSconeSpacing', 2.7, ...                        // This results to around 8-9% S-cones
        'LtoMratio', 2.0, ...                                   // Valid range: [0 - Inf]
        'outputFile', sprintf('%s__ConesAssigned', connector('phase2').outputFile),...
        'outputDir', tmpDir ...
    );


    
    % Phase 4: Connect cones to the mRGC RF centers
    connector('phase4') = struct( ...
        'run', connectConesToRGCcenters, ...
        'runFunction', @runPhase4, ...
        'inputFile', connector('phase3').outputFile, ...
        'orphanRGCpolicy', 'steal input', ...                  // How to deal with RGCs that have no input
        'maximizeConeSpecificity', 100, ...                    // percent of RGCs for which to attempt cone specific wiring to the RF center
        'outputFile', sprintf('%s__ConeConnectionsToRGCcenters', connector('phase3').outputFile),...
        'outputDir', tmpDir ...
    );


    % Phase 5: Visualize connections at a target patch 
    connector('phase5') = struct( ...
        'run', visualizeConeToRGCcenterConnections, ...
        'runFunction', @runPhase5, ...
        'inputFile', connector('phase4').outputFile, ...
        'zLevels', [0.3 1], ...                                     // contour levels
        'whichLevelsToContour', [1], ...                            // Which level to plot the isoresponse contour
        'displayEllipseInsteadOfContour', ~true, ...                // Ellipse fitted to the sum of flat-top gaussians
        'showConnectedConePolygon', true, ...
        'patchEccMicrons', [0 0],... % [4800 0]/16*0, ...                           // Eccenticity of visualized patch
        'patchSizeMicrons', [100 50], ...                         // Size of visualized patch
        'outputFile', sprintf('%s__Visualization', connector('phase4').outputFile),...
        'exportsDir', exportsDir, ...
        'outputDir', tmpDir ...
    );
        

    % Phase 6: Compute cone weights to mRGC RF subregions
    deconvolutionOpticsParams = struct(...
        'PolansWavefrontAberrationSubjectIDsToCompute', [10]);        % Deconvolution model: which subject  
    deconvolutionOpticsParams.quadrantsToCompute = {'horizontal'};   % Deconvolution model: which quadrant to use/average (choose one or more from {'horizontal', 'superior','inferior'}
    
    connector('phase6') = struct( ...
        'run', computeConeWeightsToRGCcentersAndSurrounds, ...
        'runFunction', @runPhase6, ...
        'inputFile', connector('phase4').outputFile, ...
        'patchEccDegs', [0 0], ...                                  // Eccenticity of computed patch
        'patchSizeDegs', [48 48], ...                               // Size (width, height) of computed patch                 
        'deconvolutionOpticsParams', deconvolutionOpticsParams, ... // Deconvolution optics params
        'outputFile', sprintf('%s__ConeWeightsToRGCRFsubregions', connector('phase4').outputFile),...
        'exportsDir', exportsDir, ...
        'outputDir', tmpDir ...
    );
                             
    
    % Phase 7: Visualize cone weights to mRGC RF subregions
    connector('phase7') = struct( ...
        'run', visualizeConeWeightsToRGCcentersAndSurrounds, ...
        'runFunction', @runPhase7, ...
        'inputFile', connector('phase6').outputFile, ...
        'patchEccDegs', [0 0], ...                                 // Eccenticity of computed patch
        'patchSizeDegs', [48 48], ...                               // Size (width, height) of computed patch
        'deconvolutionOpticsParams', deconvolutionOpticsParams, ...
        'outputFile', sprintf('%s__ConeWeightsToRGCRFsubregions', connector('phase4').outputFile),...
        'exportsDir', exportsDir, ...
        'outputDir', tmpDir ...
    );


   
    coneDensities = [0.6 0.3 0.1];
    
    %coneDensities = [0 1 0];
    
    noLCA = ~true;
    noOptics = ~true;
    LconeMosaicOnly = ~true;
    MconeMosaicOnly = ~true;
    if (coneDensities(1) == 1)
        LconeMosaicOnly = true;
    end
    if (coneDensities(2) == 1)
        MconeMosaicOnly = true;
    end
    
    
   rgcMosaicPatchHorizontalEccMicrons = 150;
   rgcMosaicPatchSizeMicrons = 30;
  
  rgcMosaicPatchHorizontalEccMicrons = 300;
  rgcMosaicPatchSizeMicrons = 50;
  
%   rgcMosaicPatchHorizontalEccMicrons = 600;
%   rgcMosaicPatchSizeMicrons = 60;
%   
%   rgcMosaicPatchHorizontalEccMicrons = 900;
%   rgcMosaicPatchSizeMicrons = 70;
% %   
   rgcMosaicPatchHorizontalEccMicrons = 1500;
   rgcMosaicPatchSizeMicrons = 100;
% %   
%   rgcMosaicPatchHorizontalEccMicrons = 3000;
%   rgcMosaicPatchSizeMicrons = 200;
%   
%   rgcMosaicPatchHorizontalEccMicrons = 4500;
%   rgcMosaicPatchSizeMicrons = 250;
  
%     rgcMosaicPatchHorizontalEccMicrons = 6000;
%     rgcMosaicPatchSizeMicrons = 300;
%   
    
%     rgcMosaicPatchHorizontalEccMicrons = 300*10;
%     rgcMosaicPatchSizeMicrons = 200;
%     
%     rgcMosaicPatchHorizontalEccMicrons = 300*20;
%     rgcMosaicPatchSizeMicrons = 300;
    
    if (LconeMosaicOnly)
        responseFilesDir = fullfile(responseFilesDir,'LonlyMosaic');
        exportsDir = fullfile(exportsDir,'LonlyMosaic');
    elseif (MconeMosaicOnly)
        responseFilesDir = fullfile(responseFilesDir,'MonlyMosaic');
        exportsDir = fullfile(exportsDir,'MonlyMosaic');
    else
        responseFilesDir = fullfile(responseFilesDir,'LMSConeMosaic');
        exportsDir = fullfile(exportsDir,'LMSConeMosaic');
    end
    
    if (noLCA)
        responseFilesDir = sprintf('%sNoLCA',responseFilesDir);
        exportsDir = sprintf('%sNoLCA',exportsDir);
    end
    if (noOptics)
        responseFilesDir = sprintf('%sNoOptics',responseFilesDir);
        exportsDir = sprintf('%sNoOptics',exportsDir);
    end
    % Separate exports depending on LCA and horizontal ecc
    exportsDir = sprintf('%s_HorizontalEcc_%2.0fmicrons',exportsDir, rgcMosaicPatchHorizontalEccMicrons);
    
    % PhaseX: Connect RGC mosaic to a patch of a regular hex cone mosaic 
    connector('phaseX') = struct( ...
        'run', wirePartOfMRGCMosaicToConeMosaicPatch, ...
        'runFunction', @runPhaseX, ...
        'inputFile', connector('phase1').outputFile, ...
        'rgcMosaicPatchEccMicrons', [rgcMosaicPatchHorizontalEccMicrons 0], ... %[3000 0], ... %[600 0],
        'rgcMosaicPatchSizeMicrons', rgcMosaicPatchSizeMicrons*[1 1], ... %[200 200], ... %[75 75],  
        'coneDensities', coneDensities, ...                          // LMS mosaic
        'orphanRGCpolicy', 'steal input', ...                  // How to deal with RGCs that have no input
        'maximizeConeSpecificity', 100, ...                    // percent of RGCs for which to attempt cone specific wiring to the RF center
        'deconvolutionOpticsParams', deconvolutionOpticsParams, ...
        'pupilDiamMM', 3.0, ...
        'noLCA', noLCA, ...                                      // Optics with no longitudinal chromatic aberration
        'noOptics', noOptics, ...                                   // Optics zero Zernike coefficients
        'imposedRefractionErrorDiopters', 0, ...
        'outputFile', 'midgetMosaicConnectedWithConeMosaicPatch', ...
        'responseFilesDir', responseFilesDir, ...
        'exportsDir', exportsDir, ...
        'outputDir', tmpDir ...
        );
    
    % Phase 10: Visualize relationship between RF sizes and dendritic size data
    connector('phase10') = struct( ...
        'run', coVisualizeRFsizeWithDendriticFieldSize, ...
        'runFunction', @runPhase10, ...
        'inputFile', connector('phase4').outputFile, ...
        'zLevels', [0.3 1], ...                                     // contour levels
        'whichLevelsToContour', [1], ...                            // Which level to fit the ellipse to
        'patchEccDegs', [12 0], ...                                 // Eccenticity of visualized patch
        'patchSizeDegs', [2 2], ... 
        'outputFile', sprintf('%s__Visualization2', connector('phase4').outputFile),...
        'exportsDir', exportsDir, ...
        'outputDir', tmpDir ...
    );

    runPhases = keys(connector);
    for k = 1:numel(runPhases) 
        theRunPhase = runPhases{k};
        if (connector(theRunPhase).run)
            runParams = connector(theRunPhase);
            runFunction = connector(theRunPhase).runFunction;
            runFunction(runParams);
            return;
        end
    end  
    
end
