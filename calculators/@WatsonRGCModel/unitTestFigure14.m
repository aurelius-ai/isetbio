function unitTestFigure14()
    
    eccMinDegs = 0.1;
    eccMaxDegs = 100;
    eccSamplesNum = 100;
    eccDegs = logspace(log10(eccMinDegs), log10(eccMaxDegs), eccSamplesNum);
    eccUnits = 'deg';
    densityUnits = 'deg^2';
    meridianLabeling = 'Watson'; %'retinal';   % choose from {'retinal', 'Watson'}
    
    doIt(eccDegs, eccUnits, densityUnits, meridianLabeling, 'mRGCToConesRatio');
end

function doIt(eccentricities, eccUnits, densityUnits, meridianLabeling, figureName)
    obj = WatsonRGCModel();
    plotlabOBJ = obj.setUpPlotLab();
    
    hFig = figure(1); clf;
    theAxesGrid = plotlabOBJ.axesGrid(hFig, ...
            'leftMargin', 0.18, ...
            'bottomMargin', 0.18, ...
            'rightMargin', 0.04, ...
            'topMargin', 0.05);
    theAxesGrid = theAxesGrid{1,1};
    hold(theAxesGrid, 'on');
    
    meridianNames = obj.enumeratedMeridianNames;
    theLegends = cell(numel(meridianNames),1);
    
     % Loop over meridians
    for k = 1:numel(meridianNames)
        % Compute the data
        rightEyeVisualFieldMeridianName = meridianNames{k};
        
        % cone RF spacing/density
        [coneRFSpacing, coneRFDensity] = obj.coneRFSpacingAndDensityAlongMeridian(eccentricities, ...
            rightEyeVisualFieldMeridianName, eccUnits, densityUnits);
       
        % mRGC spacing/density
        [mRGCRFSpacing, mRGCRFDensity] = obj.mRGCRFSpacingAndDensityAlongMeridian(eccentricities, ...
            rightEyeVisualFieldMeridianName, eccUnits, densityUnits);
        
        % ratios
        mRGCtoConeRatio = mRGCRFDensity./coneRFDensity;
        
        plot(eccentricities, mRGCtoConeRatio);
        if (strcmp(meridianLabeling, 'retinal'))
            theLegends{k} = rightEyeRetinalMeridianName;
        else
            theLegends{k} = rightEyeVisualFieldMeridianName;
        end
        
    end
    
    % Ticks and Lims
    if (strcmp(eccUnits, 'retinal mm'))
        xLims = obj.rhoDegsToMMs([0.005 100]);
        xTicks = [0.01 0.03 0.1 0.3 1 3 10];
        xLabelString = sprintf('eccentricity (%s)', eccUnits);
    else
        xLims = [0.05 100];
        xTicks = [0.1 0.3 1 3 10 30 100];
        xLabelString = sprintf('eccentricity (%s)', strrep(eccUnits, 'visual', ''));
    end
    
    yLims = [0.02 2.2];
    yTicks = [0.05 0.1 0.2 0.5 1 2];
    yTicksLabels = {'.05', '.10', '.20', '.50', '1.0', '2.0'};
    yLabelString = 'mRGC/cone ratio';
    
    
    % Labels and legends
    xlabel(xLabelString);
    ylabel(yLabelString);
    legend(theLegends, 'Location', 'SouthWest');
   
    set(gca, 'XLim', xLims, 'YLim', yLims, ...
        'XScale', 'log', 'YScale', 'log', ...
        'XTick', xTicks, ...
        'YTick', yTicks, 'YTickLabel', yTicksLabels);
    
    % Export figure
    plotlabOBJ.exportFig(hFig, 'png', figureName, fullfile(pwd(), 'exports'));
      
end
