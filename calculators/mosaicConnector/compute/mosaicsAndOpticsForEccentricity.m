function [theConeMosaic, theMidgetRGCmosaic, theOptics, opticsPostFix, PolansSubjectID] = ...
    mosaicsAndOpticsForEccentricity(runParams, recomputeConeMosaic, recomputeRGCmosaic, recomputeOptics, saveDir, ...
    visualizeCronerKaplanDeconvolutionModel)

    % Params for the connected mRGC mosaic
    mosaicParams.rgcMosaicPatchEccMicrons = runParams.rgcMosaicPatchEccMicrons;
    mosaicParams.rgcMosaicPatchSizeMicrons = runParams.rgcMosaicPatchSizeMicrons;
    mosaicParams.orphanRGCpolicy = runParams.orphanRGCpolicy;
    mosaicParams.maximizeConeSpecificity = runParams.maximizeConeSpecificity;

    tic  
    
    % Compute filenames for mosaics and optics
    [mosaicsFilename, opticsFilename, opticsPostFix, PolansSubjectID] = mosaicsAndOpticsFileName(runParams);
    
    % Determine what we need to recompute and what can be loaded from the existing files
    recomputeOpticsOnly = ((~recomputeConeMosaic) && (~recomputeRGCmosaic)) && (recomputeOptics);
    
    if (recomputeConeMosaic) || (recomputeRGCmosaic)
        
        if (~recomputeConeMosaic)
            % Load previously generated mosaic
            fprintf('\nLoading previously-generated cone mosaic ...');
            load(fullfile(saveDir,mosaicsFilename), 'theConeMosaic', 'theConeMosaicMetaData');
        else
            fprintf('\nRecomputing cone mosaic ...');
            % Generate a regular hex cone mosaic patch with the desired eccentricity and size
            [theConeMosaic, theConeMosaicMetaData] = CronerKaplanRGCModel.generateConeMosaicForDeconvolution(...
                mosaicParams.rgcMosaicPatchEccMicrons, ...
                mosaicParams.rgcMosaicPatchSizeMicrons, ...
                'sizeUnits', 'microns', ...
                'mosaicGeometry', 'regular');
            
        end
        
        if (recomputeRGCmosaic)
            fprintf('\nRecomputing mRGC mosaic and connecting it to the cone mosaic ...');
            % Location of file with the full (50 x 50 deg) ecc-based mRGCRF lattice
            mRGCmosaicFile = fullfile(runParams.outputDir, sprintf('%s.mat',runParams.inputFile));

            % Generate connected mRGC mosaic patch
            theMidgetRGCmosaic = generateMRGCMosaicConnectedToConeMosaic(theConeMosaicMetaData, mRGCmosaicFile, mosaicParams, ...
                 runParams.deconvolutionOpticsParams, visualizeCronerKaplanDeconvolutionModel, runParams.outputFile, runParams.exportsDir);
        else
            theMidgetRGCmosaic = [];
        end
        
        % Save the mosaics
        if (~isempty(saveDir))
            save(fullfile(saveDir,mosaicsFilename), 'theConeMosaic', 'theConeMosaicMetaData', 'theMidgetRGCmosaic');
        end
        
        if (recomputeOptics)
           % Generate the optics
           fprintf('\nComputing optics with noLCA flag: %d and noOptics flag: %d\n', runParams.noLCA, runParams.noOptics);
           theOptics = CronerKaplanRGCModel.generatePolansOpticsForDeconcolution(PolansSubjectID, ...
                runParams.imposedRefractionErrorDiopters, runParams.pupilDiamMM, ...
                theConeMosaic.pigment.wave, theConeMosaic.micronsPerDegree, ...
                mosaicParams.rgcMosaicPatchEccMicrons, ...
                'eccentricityUnits', 'microns', ...
                'noLCA', runParams.noLCA, ...
                'noOptics', runParams.noOptics);
            
            % Save the optics
            if (~isempty(saveDir))
                save(fullfile(saveDir,opticsFilename),'theOptics');
            end
        else
            load(fullfile(saveDir,opticsFilename),'theOptics');
        end
        
    elseif (recomputeOpticsOnly)
        % Load previously generated mosaic
        fprintf('\nLoading previously-generated cone/mRGC mosaics ...');
        load(fullfile(saveDir,mosaicsFilename), 'theConeMosaic', 'theMidgetRGCmosaic');
        
        fprintf('\nComputing optics with noLCA flag: %d and noOptics flag: %d\n', runParams.noLCA, runParams.noOptics);
        theOptics = generatePolansOptics(PolansSubjectID, ...
            runParams.noLCA, runParams.noOptics, runParams.imposedRefractionErrorDiopters, ...
            theConeMosaic.pigment.wave, mosaicParams.rgcMosaicPatchEccMicrons);
        
        % Save mosaic and optics
        save(fullfile(saveDir,opticsFilename),'theOptics');
        
    else
        fprintf('\nLoading previously-generated cone/mRGC mosaics & optics ...');
        load(fullfile(saveDir,mosaicsFilename), 'theConeMosaic', 'theMidgetRGCmosaic');
        load(fullfile(saveDir,opticsFilename),'theOptics');
    end

    fprintf('Done in %2.1f minutes\n', toc/60);
       
end
