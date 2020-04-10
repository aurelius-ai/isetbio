function unitTestFigure1()
    
    eccMinDegs = 0.1;
    eccMaxDegs = 80;
    eccSamplesNum = 100;
    eccDegs = logspace(log10(eccMinDegs), log10(eccMaxDegs), eccSamplesNum);
    eccUnits = 'deg';
    densityUnits = 'deg^2';
    meridianLabeling = 'Watson'; %'retinal';   % choose from 'retinal', 'Watson'

    doIt(eccDegs, eccUnits, densityUnits, meridianLabeling, 'coneDensity');
end

function doIt(eccentricities, eccUnits, densityUnits, meridianLabeling, figureName)
    
    obj = WatsonRGCModel();
    plotlabOBJ  = obj.setUpPlotLab();
    
    
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
        rightEyeVisualFieldMeridianName = meridianNames{k};
        [coneRFSpacing, coneRFDensity, rightEyeRetinalMeridianName] = obj.coneRFSpacingAndDensityAlongMeridian(eccentricities, rightEyeVisualFieldMeridianName, eccUnits, densityUnits);
        plot(theAxesGrid, eccentricities, coneRFDensity);
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
    
    if (strcmp(densityUnits, 'retinal mm^2'))
        yLims = [2000 250*1000];
        yTicks = [2000 5*1000 10*1000 20*1000 50*1000 100*1000 200*1000];
        yTicksLabels = {'2k', '5k', '10k', '20k', '50k', '100k', '200K'};
        yLabelString = sprintf('density (cones / %s)', densityUnits);
    else
        yLims = [1 40000];
        yTicks = [1 10 100 1000 10000];
        yTicksLabels = {'1' '10' '100', '1000', '10000'};
        yLabelString = sprintf('density (cones / %s)', strrep(densityUnits, 'visual', ''));
    end
    
    % Labels and legends
    xlabel(theAxesGrid, xLabelString);
    ylabel(theAxesGrid, yLabelString);
    legend(theLegends);
   
    set(gca, 'XLim', xLims, 'YLim', yLims, ...
        'XScale', 'log', 'YScale', 'log', ...
        'XTick', xTicks, ...
        'YTick', yTicks, 'YTickLabel', yTicksLabels);
    
    % Export figure
    plotlabOBJ.exportFig(hFig, 'png', figureName, fullfile(pwd(), 'exports'));
    
end
