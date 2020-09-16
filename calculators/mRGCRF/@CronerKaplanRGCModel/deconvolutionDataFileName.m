function dataFileName = deconvolutionDataFileName(obj, patchEccRadiusDegs, imposedRefractionErrorDiopters, subregionName)
    if (strcmpi(subregionName, 'center'))
        dataFileName = fullfile(obj.psfDeconvolutionDir, ...
            sprintf('EccRadius_%2.1fdegs_RefractionError_%2.2fD_CenterDeconvolution.mat', ...
            patchEccRadiusDegs, imposedRefractionErrorDiopters));
    else
        dataFileName = fullfile(obj.psfDeconvolutionDir, ...
            sprintf('EccRadius_%2.1fdegs_RefractionError_%2.2fD_SurroundDeconvolution.mat', ...
            patchEccRadiusDegs, imposedRefractionErrorDiopters));
    end
    
end
