function deconvolutionModel = computeDeconvolutionModel(obj, deconvolutionOpticsParams)
    
    % Validate the deconvolutionOpticsParams
    obj.validateDeconvolutionOpticsParams(deconvolutionOpticsParams);
    
    tabulatedEccentricities = [0 0.25 0.5 1 1.5 2:9 11 13:17];
    defocusMode = 'subjectDefault';
    if (strcmp(defocusMode, 'subjectDefault'))
        imposedRefractionErrorDiopters = 0; 
    else
        imposedRefractionErrorDiopters = 0.01; 
    end
    
    deconvolutionModel.center = computeCenterDeconvolutionModel(obj, tabulatedEccentricities, imposedRefractionErrorDiopters, deconvolutionOpticsParams);
    %deconvolutionModel.surround = computeSurroundDeconvolutionModel(obj, tabulatedEccentricities, imposedRefractionErrorDiopters, deconvolutionOpticsParams);
end

function deconvolutionModel = computeCenterDeconvolutionModel(obj, tabulatedEccentricities, imposedRefractionErrorDiopters, deconvolutionOpticsParams)
    
    deconvolutionQuadrant = deconvolutionOpticsParams.quadrantsToAverage{1};
    deconvolutionSubject = deconvolutionOpticsParams.PolansWavefrontAberrationSubjectIDsToAverage(1);
    
    deconvolutionModel = computeCenterDeconvolutionModelForSpecificQuadrantAndSubject(obj, ...
        tabulatedEccentricities, imposedRefractionErrorDiopters, deconvolutionQuadrant, deconvolutionSubject);

end



function deconvolutionModel = computeCenterDeconvolutionModelForSpecificQuadrantAndSubject(obj, ...
        tabulatedEccentricities, imposedRefractionErrorDiopters, deconvolutionQuadrant, deconvolutionSubject)
    
    deconvolutionModel.subjectID = deconvolutionSubject;
    deconvolutionModel.quadrant = deconvolutionQuadrant;
    deconvolutionModel.tabulatedEccentricities = tabulatedEccentricities;
    
    for eccIndex = 1:numel(tabulatedEccentricities)
        % Eccentricity
        eccDegs(1) = tabulatedEccentricities(eccIndex);
        eccDegs(2) = 0;
        deconvolutionModel.eccDegs(eccIndex,:) = eccDegs;
        
        % Load deconvolution file for this eccentricity
        dataFileName = fullfile(obj.psfDeconvolutionDir,...
            sprintf('ecc_-%2.1f_%2.1f_centerDeconvolutions_refractionError_%2.2fD.mat', eccDegs(1), eccDegs(2), imposedRefractionErrorDiopters));
        load(dataFileName, 'deconvolutionStruct', 'quadrants', 'subjectIDs');
        
        assert((numel(subjectIDs) == 1) && (subjectIDs == deconvolutionSubject), ...
            sprintf('Deconvolution file does not contain subject %d', deconvolutionSubject));
        

        assert((numel(quadrants) == 1) && (strcmp(quadrants{1},deconvolutionQuadrant)), ...
            sprintf('Deconvolution file does not contain quadrant''%s''', deconvolutionQuadrant));
        
        dataDictionary = deconvolutionStruct{1,1}.data;
        dataLabels = keys(dataDictionary);
        
        for coneInputConfigIndex = 1:numel(dataLabels)
            coneInputConfig = dataLabels{coneInputConfigIndex};
            coneInputsNum = str2double(strrep(coneInputConfig, '-coneInput', ''));
            decolvolutionData = dataDictionary(coneInputConfig);
            
            deconvolutionModel.centerConeInputsNum(eccIndex,coneInputsNum) = coneInputsNum;
            deconvolutionModel.visualGainAttenuation(eccIndex,coneInputsNum) = decolvolutionData.visualGainAttenuation;
            deconvolutionModel.visualCharacteristicRadius(eccIndex,coneInputsNum) = decolvolutionData.minVisualSigma;
        end
    end
end

function deconvolutionModel = computeSurroundDeconvolutionModel(obj, tabulatedEccentricities, imposedRefractionErrorDiopters, deconvolutionOpticsParams)
    subjectsToAverage = deconvolutionOpticsParams.PolansWavefrontAberrationSubjectIDsToAverage;
    quadrantsToAverage = deconvolutionOpticsParams.quadrantsToAverage;
    
    % Use WatsonRGCModel to retrieve cone apertures along the nasal meridian
    % for the tabulated eccentricities
    w = WatsonRGCModel();
    coneRFSpacingsDegs  = w.coneRFSpacingAndDensityAlongMeridian(abs(tabulatedEccentricities), ...
            'nasal meridian','deg', 'deg^2', ...
            'correctForMismatchInFovealConeDensityBetweenWatsonAndISETBio', false);
    % Cone aperture is a percentage of the cone spacing
    coneApertureRadii = WatsonRGCModel.coneApertureToDiameterRatio * 0.5 * coneRFSpacingsDegs;
    coneApertureRadiusAtZeroDegs = coneApertureRadii(1);
    
    for eccIndex = 1:numel(tabulatedEccentricities)
        % Eccentricity
        eccDegs = tabulatedEccentricities(eccIndex);
        
        % Load deconvolution file for this eccentricity
        dataFileName = fullfile(obj.psfDeconvolutionDir,...
            sprintf('ecc_-%2.1f_deconvolutions_refractionError_%2.2fD.mat', eccDegs, imposedRefractionErrorDiopters));
        load(dataFileName, 'retinalPoolingRadii', 'visualRadius', 'visualGain', 'subjectIDs', 'quadrants');
        retinalPoolingRadiiOriginal = retinalPoolingRadii;
        
        % Compute the minimum possible RF center radius as the mean (over all subjects)
        % convolution of the cone aperture at 0 deg with the PSF at 0 deg 
        if (eccDegs == 0)
            % Find the 2 closest retinal pooling radius
            [dd,idx] = sort(abs( coneApertureRadiusAtZeroDegs-retinalPoolingRadii));
            % Compute the minimal visual radius as the weighed average of the
            % visual radii corresponding to the 2 closest retinal pooling radii
            d1 = dd(2)/(dd(1)+dd(2));
            d2 = dd(1)/(dd(1)+dd(2));
            visualRadii = d1 * squeeze(visualRadius(idx(1),:,:)) + d2 * squeeze(visualRadius(idx(2),:,:));
            minVisualRadiusDegs = median(median(visualRadii));
        end

        % Get data for the quadrant of interest
        visualRadius = CronerKaplanRGCModel.quadrantData(visualRadius, quadrantsToAverage, quadrants, subjectsToAverage, subjectIDs);
        visualGain = CronerKaplanRGCModel.quadrantData(visualGain, quadrantsToAverage, quadrants, subjectsToAverage, subjectIDs);
        

        % We will fit the relationship between visual and retinal radii
        % using a saturating function, but only for retinal radii >= cone aperture radii
        % So select these data here:
        idx = find(retinalPoolingRadii >= coneApertureRadii(eccIndex));
        retinalPoolingRadii = retinalPoolingRadii(1,idx);
        visualRadius = visualRadius(:,idx);
        visualGain = visualGain(:,idx);
        
        % Compute the median visual radius over subjects/ecc quadrants
        medianVisualRadius = (median(visualRadius,1, 'omitnan'))';
        
        % Compute the median gain over all subjects/ecc quadrants
        medianVisualGain = (median(visualGain,1, 'omitnan'))';
       
        % Fit the relationship: retinalRadius(visualRadius) = Model(visualRadius, params)
        [modelFunctionRadius, fittedParamsRadius(eccIndex,:)] = fitRadiusData(medianVisualRadius, retinalPoolingRadii);
        % Fit the relationship: visualGain(retinalRadius) = Model(retinalRadius, params)
        [modelFunctionGain, fittedParamsGain(eccIndex,:)] = fitGainData(medianVisualGain, retinalPoolingRadii);
        
        nonAveragedVisualRadius{eccIndex} = visualRadius;
        nonAveragedVisualGain{eccIndex} = visualGain;
    end % eccIndex
    
    deconvolutionModel = struct(...
        'retinalPoolingRadii', retinalPoolingRadiiOriginal, ...
        'tabulatedEccentricities', tabulatedEccentricities, ...
        'fittedParamsRadius', fittedParamsRadius, ...
        'fittedParamsGain', fittedParamsGain, ...
        'modelFunctionRadius', modelFunctionRadius, ...
        'modelFunctionGain', modelFunctionGain, ...
        'minVisualRadiusDegs', minVisualRadiusDegs ...
        );
     % Other meta-parameters
     deconvolutionModel.coneApertureRadii = coneApertureRadii;
     deconvolutionModel.opticsParams = deconvolutionOpticsParams;
     deconvolutionModel.nonAveragedVisualRadius = nonAveragedVisualRadius;
     deconvolutionModel.nonAveragedVisualGain = nonAveragedVisualGain;
end

function [modelFunction, fittedParams] = fitRadiusData(visualRadius, retinalRadius)
    % For better fitting extend the visual radius data to 1.5
    visual  = [visualRadius; [0.7 0.8 1 1.5]'];
    retinal = [retinalRadius [0.7 0.8 1 1.5] ]';
        
    modelFunction = @(p,x)(p(1) - (p(2)-p(1))*exp(-p(3)*x));
    initialParams = [5 10 0.2];
    [fittedParams, fittedParamsSE] = nonLinearFitData(visual, retinal, modelFunction, initialParams);
end

function [modelFunction, fittedParams] = fitGainData(visualGain, retinalRadius)
    % For better fitting extend the visual radius data to 1.5
    visual  = [visualGain; [1 1 1]'];
    retinal = [retinalRadius [0.8 1 2]]';
        
    modelFunction = @(p,x)((p(1)*x.^p(3))./(x.^p(3)+p(2)));
    initialParams = [0.9 0.002 2];
    [fittedParams, fittedParamsSE] = nonLinearFitData(retinal, visual, modelFunction, initialParams);
end

function [fittedParams, fittedParamsSE] = nonLinearFitData(x,y, modelFunction, initialParams)
    opts.RobustWgtFun = 'talwar';
    opts.MaxIter = 1000;
    [fittedParams,~,~,varCovarianceMatrix,~] = nlinfit(x,y,modelFunction,initialParams,opts);
    % standard error of the mean
    fittedParamsSE = sqrt(diag(varCovarianceMatrix));
    fittedParamsSE = fittedParamsSE';
end