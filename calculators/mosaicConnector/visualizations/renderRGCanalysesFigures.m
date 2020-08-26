function renderRGCanalysesFigures(patchDogParams, spatialFrequenciesCPDHR, responseAmplitudeHR, spatialFrequenciesCPD, responseAmplitude, ...
        responseTimeAxis, integratedResponsesMean, responseTimeAxisHR, fittedResponsesHR, ...
        maxSpikeRateModulation, theConeMosaic, runParams, theMidgetRGCmosaic, ...
        visualizePatchStatistics, visualizeRGCTemporalResponsesAtRGCPositions, visualizeRGCSFTuningsAtRGCPositions, ...
        targetRGCsForWhichToVisualizeSpatialFrequencyTuningCurves, coVisualizedRetinalStimulus, ...
        LMScontrast,  opticsPostFix, PolansSubjectID, exportFig, figExportsDir)
    
    
    % All RGCs
    targetRGCindices = 1:size(theMidgetRGCmosaic.centerWeights,2);
    RGCconeInputInfo = returnConeInputInfoForTargetRGC(targetRGCindices, theMidgetRGCmosaic, theConeMosaic);
    
    if (visualizePatchStatistics)
        % Visualize data to contrast with Cronner and Kaplan data
        RGCpositionsMicrons = determineRGCPositionsFromCenterInputs(theConeMosaic, runParams.rgcMosaicPatchEccMicrons, theMidgetRGCmosaic.centerWeights);
        RGCeccentricityDegs = WatsonRGCModel.rhoMMsToDegs(sqrt(sum(RGCpositionsMicrons.^2,2))/1000.0);
        
        visualizePatchStatsDerivedFromSFcurves(patchDogParams, RGCconeInputInfo, RGCeccentricityDegs, ...
            LMScontrast, opticsPostFix, PolansSubjectID, figExportsDir);
        
    end
    
    labelCells = true;
    %   Visualize the temporal response of each RGC at the RGC's location
    if (visualizeRGCTemporalResponsesAtRGCPositions)
        for sfIndex = 1:numel(spatialFrequenciesCPD)
            superimposedRetinalStimulus = [];
            plotXaxisScaling = 'linear';
            plotType = 'TimeResponse';
            figureName = sprintf('%2.1fcpdResponse', spatialFrequenciesCPD(sfIndex));
            visualizeRGCmosaicWithResponses(100+sfIndex, theConeMosaic, plotXaxisScaling, plotType, ...
               responseTimeAxis, squeeze(integratedResponsesMean(sfIndex,:,:)), ...
               responseTimeAxisHR, squeeze(fittedResponsesHR(sfIndex,:,:)), ...
               runParams.rgcMosaicPatchEccMicrons, runParams.rgcMosaicPatchSizeMicrons, ...
               theMidgetRGCmosaic, 'centers', maxSpikeRateModulation, ...
               superimposedRetinalStimulus, ....
               figureName, LMScontrast, opticsPostFix, PolansSubjectID, ...
               [], labelCells, ...
               exportFig, figExportsDir);
        end
    end
    
    if (visualizeRGCSFTuningsAtRGCPositions)
        % Visualize the response tuning of each RGC at the RGC's location
        exportFig = true;
        superimposedRetinalStimulus = [];
        plotXaxisScaling = 'log';
        plotType = 'SFtuning';
        figureName = 'SFtuningAll';

        visualizeRGCmosaicWithResponses(1000, theConeMosaic, plotXaxisScaling, plotType, ...
                    spatialFrequenciesCPD, responseAmplitude, ...
                    spatialFrequenciesCPDHR, responseAmplitudeHR, ...
                    runParams.rgcMosaicPatchEccMicrons, runParams.rgcMosaicPatchSizeMicrons, ...
                    theMidgetRGCmosaic, 'centers', maxSpikeRateModulation, ...
                    superimposedRetinalStimulus, ....
                    figureName, LMScontrast, opticsPostFix, PolansSubjectID, ...
                    [], labelCells, ...
                    exportFig, figExportsDir);
    end
    
    if (~isempty(targetRGCsForWhichToVisualizeSpatialFrequencyTuningCurves))
        for iTargetRGC = 1:numel(targetRGCsForWhichToVisualizeSpatialFrequencyTuningCurves)
            figureName = sprintf('SFtuning%d', targetRGCsForWhichToVisualizeSpatialFrequencyTuningCurves(iTargetRGC));

            visualizeRGCmosaicWithResponses(1000+targetRGCsForWhichToVisualizeSpatialFrequencyTuningCurves(iTargetRGC), theConeMosaic, plotXaxisScaling, plotType, ...
                    spatialFrequenciesCPD, responseAmplitude, ...
                    spatialFrequenciesCPDHR, responseAmplitudeHR, ...
                    runParams.rgcMosaicPatchEccMicrons, runParams.rgcMosaicPatchSizeMicrons, ...
                    theMidgetRGCmosaic,  'centers', maxSpikeRateModulation, ...
                    coVisualizedRetinalStimulus, ...
                    figureName, LMScontrast, opticsPostFix, PolansSubjectID, ...
                    targetRGCsForWhichToVisualizeSpatialFrequencyTuningCurves(iTargetRGC), false, ...
                    exportFig, figExportsDir);
        end
    end
end

function visualizePatchStatsDerivedFromSFcurves(patchDogModelParams, RGCconeInputInfo, patchRGCeccentricityDegs, ...
        LMScontrast, opticsPostFix, PolansSubjectID, figExportsDir)
    
    % Preallocate memory
    rgcsNum = numel(patchDogModelParams);
    centerCharacteristicRadii = zeros(1, rgcsNum);
    surroundCharacteristicRadii = zeros(1, rgcsNum);
    centerPeakSensitivities = zeros(1, rgcsNum);
    surroundPeakSensitivities = zeros(1, rgcsNum);
    
    % Extract params from the fitted model
    for iRGC = 1:rgcsNum
        p = patchDogModelParams{iRGC};
        centerCharacteristicRadii(iRGC) = p.rC;
        surroundCharacteristicRadii(iRGC) = p.rS;
        centerPeakSensitivities(iRGC) = p.kC;
        surroundPeakSensitivities(iRGC) = p.kS;
    end

    plotlabOBJ = setupPlotLab(0, 18,10);
    
    visualizeRFparamsForConnectedPatch(555, 'ResponseDerivedParams', ...
        RGCconeInputInfo, ...
        patchRGCeccentricityDegs, ...
        centerCharacteristicRadii, surroundCharacteristicRadii, ...
        centerPeakSensitivities, surroundPeakSensitivities, ...
        sprintf('ResponseDerivedParams_LMS_%0.2f_%0.2f_%0.2f_PolansSID_%d_%s', ...
            LMScontrast(1), LMScontrast(2), LMScontrast(3), PolansSubjectID, opticsPostFix), ...
        figExportsDir, plotlabOBJ);

    setupPlotLab(-1);
end


function plotlabOBJ = setupPlotLab(mode, figWidthInches, figHeightInches)
    if (mode == 0)
        plotlabOBJ = plotlab();
        plotlabOBJ.applyRecipe(...
                'colorOrder', [1 0 0; 0 0 1], ...
                'axesBox', 'off', ...
                'axesTickDir', 'in', ...
                'renderer', 'painters', ...
                'lineMarkerSize', 8, ...
                'axesTickLength', [0.01 0.01], ...
                'legendLocation', 'SouthWest', ...
                'figureWidthInches', figWidthInches, ...
                'figureHeightInches', figHeightInches);
    else
        pause(2.0);
        plotlab.resetAllDefaults();
    end
end 
