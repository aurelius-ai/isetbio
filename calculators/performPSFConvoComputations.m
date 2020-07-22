function performPSFConvoComputations

    % Polans et al subjects grouped according to different criteria
    sharpestPSFSubjectIDs = [4 9];  % Subjects with the sharpest PSFs
    mediumSharpnessPSFSubjectIDs = [5 8 10];
    blurriestPSFSubjectIDs = [7];
    noArtifactPSFSubjectIDs = [4 5 7 8 9 10];
    someArtifactPSFSubjectIDs = [1 3 6];
    largeArtifacPSFSubjectIDs = [2];
    
    ck = CronerKaplanRGCModel(...
        'generateAllFigures', false, ...
        'instantiatePlotLab', false);
%     
    % Perform the deconvolution analysis for certain Polans subjects 
    % These files are 
    generateDeconvolutionFiles = true;
    if (generateDeconvolutionFiles)
        deconvolutionOpticsParams = struct(...
            'PolansWavefrontAberrationSubjectIDsToCompute', 9 ...
            );
        eccTested = [0 0.25 0.5 1 1.5 2.0 2.5 3 4 5 6 7 8 9 10];
        %eccTested = [11 12 13 14 15 16 17 18 19 20 21 22 23 24 25];
        deconvolutionOpticsParams.quadrantsToCompute =  {'horizontal'}; % {'horizontal', 'superior', 'inferior'};
        ck.generatePolansOpticsDeconvolutionFiles(...
            deconvolutionOpticsParams, ...
            'eccTested', eccTested);
    end
    
    
    % Compute and plot deconvolution model for only the 'horizontal'
    % meridian
    deconvolutionOpticsParams = struct(...
        'PolansWavefrontAberrationSubjectIDsToAverage', 9 ...
    );
    deconvolutionOpticsParams.quadrantsToAverage = {'horizontal'};
  
    deconvolutionModel = ck.computeDeconvolutionModel(deconvolutionOpticsParams);
    CronerKaplanRGCModel.plotDeconvolutionModel(deconvolutionModel)
    
    
end
