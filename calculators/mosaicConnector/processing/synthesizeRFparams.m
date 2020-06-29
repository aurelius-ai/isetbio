function synthesizedRFParams = synthesizeRFparams(conePositionsMicrons, coneSpacingsMicrons, ...
            RGCRFPositionsMicrons, ...
            midgetRGCconnectionMatrix, ...
            patchEccDegs, patchSizeDegs)
    
    [rfCenterRadiiMicrons, rfCenterPositionsMicrons, rgcIndices] = ...
        computeRFcenterSizeAndPositionsFromConnectivityMatrix(...
            conePositionsMicrons, coneSpacingsMicrons, ...
            RGCRFPositionsMicrons, ...
            midgetRGCconnectionMatrix, patchEccDegs, patchSizeDegs);
    
    % Compute visual and retinal RF params from the retinal rf center radii
    % and positions (both in microns)
    ck = CronerKaplanRGCModel('generateAllFigures', false, 'instantiatePlotLab', false);
    synthesizedRFParams = ck.synthesizeRetinalRFparamsConsistentWithVisualRFparams(rfCenterRadiiMicrons, rfCenterPositionsMicrons);
    
    % Add the corresponding rgcIndices, and patch ecc/size
    synthesizedRFParams.rgcIndices = rgcIndices;     % indices of RGCs within the target patch
    synthesizedRFParams.centerPositionMicrons = rfCenterPositionsMicrons;  % position as computed by the summed inputs to the center
    synthesizedRFParams.patchEccDegs = patchEccDegs;
    synthesizedRFParams.patchSizeDegs = patchSizeDegs;
end

function [rfCenterRadiiMicrons, rfCenterPositionsMicrons, subregionRGCidx] = ...
    computeRFcenterSizeAndPositionsFromConnectivityMatrix(...
            conePositionsMicrons, coneSpacingsMicrons, ...
            RGCRFPositionsMicrons, ...
            midgetRGCconnectionMatrix, ...
            patchEccDegs, patchSizeDegs)

    % Subregion center and size in microns
    subregion.center = round(1000*WatsonRGCModel.rhoDegsToMMs(patchEccDegs));
    subregion.size(1) = round(1000*WatsonRGCModel.rhoDegsToMMs(patchEccDegs(1) + patchSizeDegs(1)/2)) - ...
                        round(1000*WatsonRGCModel.rhoDegsToMMs(patchEccDegs(1) - patchSizeDegs(1)/2));
    subregion.size(2) = round(1000*WatsonRGCModel.rhoDegsToMMs(patchEccDegs(2) + patchSizeDegs(2)/2)) - ...
                        round(1000*WatsonRGCModel.rhoDegsToMMs(patchEccDegs(2) - patchSizeDegs(2)/2));
                    
    % Determine RFs within the patch region
    xPos = RGCRFPositionsMicrons(:,1);
    yPos = RGCRFPositionsMicrons(:,2);

    subregionRGCidx = find( (xPos> subregion.center(1) - subregion.size(1)/2) & ...
                             (xPos< subregion.center(1) + subregion.size(1)/2) & ...
                             (yPos> subregion.center(2) - subregion.size(2)/2) & ...
                             (yPos< subregion.center(2) + subregion.size(2)/2));

    % Extract the connectivity matrix for the patch region
    midgetRGCconnectionMatrix = midgetRGCconnectionMatrix(:,subregionRGCidx);
    
    % Preallocate memory
    rgcsNum = size(midgetRGCconnectionMatrix,2);
    rfCenterRadiiMicrons = zeros(rgcsNum,1);
    rfCenterPositionsMicrons = zeros(rgcsNum,2);
    
    % Compute RGC RF center positions and radii
    for RGCindex = 1:rgcsNum
        fprintf('Computing rf center and size for RGC %d of %d\n', RGCindex, rgcsNum);
        connectivityVector = full(squeeze(midgetRGCconnectionMatrix(:, RGCindex)));
        inputIDs = find(connectivityVector>0);
        inputsNum = numel(inputIDs);
        if (inputsNum == 0)
            error('RGC %d has zero inputs\n', RGCindex);
        end
        
        % Generate RFs of RGCs based on cone positions and connection matrix
        [rfCenterPosition, rfCenterSize, rfRotationDegs] = computeRFcenterAndSizeFromConnectivityMatrix(...
            connectivityVector(inputIDs), conePositionsMicrons(inputIDs,:), coneSpacingsMicrons(inputIDs));
        
        rfCenterPositionsMicrons(RGCindex,:) = rfCenterPosition;
        rfCenterRadiiMicrons(RGCindex) = 0.5*rfCenterSize;
    end 
end

    
function [rfCenterPosition, rfCenterSize, rfRotationDegs] = computeRFcenterAndSizeFromConnectivityMatrix(connectivityVector, conePositionsMicrons, coneSpacingsMicrons)
    % Determine spatial support
    minXY = min(conePositionsMicrons,[],1);
    maxXY = max(conePositionsMicrons,[],1);
    s = max(coneSpacingsMicrons);
    xMin = minXY(1)-s; xMax = maxXY(1)+s;
    yMin = minXY(2)-s; yMax = maxXY(2)+s;
    deltaX = min(coneSpacingsMicrons)/9;
    xAxis = (xMin: deltaX: xMax);
    yAxis = (yMin: deltaX: yMax);
    [X,Y] = meshgrid(xAxis,yAxis);
    theRF = [];
    for coneIndex = 1:numel(connectivityVector)
        cP = squeeze(conePositionsMicrons(coneIndex,:));
        coneSigma = 0.5*coneSpacingsMicrons(coneIndex)/3;
        coneProfile = exp(-0.5*((X-cP(1))/coneSigma).^2) .* exp(-0.5*((Y-cP(2))/coneSigma).^2).^0.1;
  
        if (isempty(theRF))
            theRF = coneProfile * connectivityVector(coneIndex);
        else
            theRF = theRF + coneProfile * connectivityVector(coneIndex);
        end 
    end
    
    % Find all the points that are greater than 1/e
    theRF = theRF/max(theRF(:));
    idx = find(theRF >= exp(-1));
    [row,col] = ind2sub(size(theRF), idx);

    % Determine semiAxes and rotation angle of the cloud point
    [rfCenterPosition, semiAxes, rfRotationDegs] = determineRotationAndSemiaxes(xAxis(col), yAxis(row));
    rfCenterSize = mean(semiAxes);
end

function  [center, semiAxes, rotationAngleDegs] = determineRotationAndSemiaxes(xx,yy)
    
    % Determine rotation of point cloud
    xo = mean(xx); yo = mean(yy);
    xx = xx - xo; yy = yy - yo;
    coeffs = polyfit(xx, yy, 1);
    slope = coeffs(1);
    rotationAngleDegs = atand(slope);
    if (abs(slope)>1)
        coeffs = polyfit(yy, xx, 1);
        slope = coeffs(1);
        rotationAngleDegs = 90-atand(slope);
    end
    
    % rotate to either 0 or 90 axis
    rotAngle = -rotationAngleDegs;
    xx2 = xo + xx*cosd(rotAngle) - yy*sind(rotAngle);
    yy2 = yo + xx*sind(rotAngle) + yy*cosd(rotAngle);

    % Compute semiAxes
    semiAxes(1) = max(xx2)-min(xx2);
    semiAxes(2) = max(yy2)-min(yy2);
    
	% Center of RF
    center = [xo yo];
end
