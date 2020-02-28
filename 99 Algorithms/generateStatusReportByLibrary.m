function st = generateStatusReportByLibrary(libraryNames)
% Go over all subjects in library(by library name) and returns status per
% slide. Sorted by subject name.
%
% INPUTS:
%   libraryNames - can be a string or a cell containing library names. 
%       Examples: 'LA' or {'LA','LB'}
% OUTPUTS:
%   st - sectionStats - structure containing stasticis for each cell. For
%       example. sectionStats.iteration(i) contains the iteration
%       assoicated with sectionPathsOut{i}.
%       see sectionStats.notes for explenation about the fields.

if ~exist('libraryNames','var')
    libraryNames = 'LE';
end

%% Input checks
if ischar(libraryNames)
    libraryNames = {libraryNames};
end
libraryNames = sort(libraryNames);

%% Get all subejcts in all libraries
subjectPaths = {};
for i=1:length(libraryNames)
    s = s3GetAllSubjectsInLib(libraryNames{i});
    subjectPaths = [subjectPaths; s(:)]; %#ok<AGROW>
end
subjectPaths = sort(subjectPaths);

%% Loop over each subject, get data that is extracted from subjects.
subjectPathsOut = {};
sectionPathsOut = {};
sectionNameOut = {};
sectionIterationOut = [];
sectionNumberOut = [];
fprintf('Processing %d subjects, wait for 10 starts [ ',length(subjectPaths));
for i=1:length(subjectPaths)
    if mod(i,round(length(subjectPaths)/10)) == 0
        fprintf('* ');
    end
    
    % Load subject's stack
    stackConfigJson = awsReadJSON([subjectPaths{i} 'Slides/StackConfig.json']);
    
    % Get section name and path
    sn = stackConfigJson.sections.names;
    sp = cellfun(@(nm)(awsModifyPathForCompetability( ...
        [subjectPaths{i} '/Slides/' nm '/'])), sn, 'UniformOutput', false);
    sectionPathsOut = [sectionPathsOut; sp(:)]; %#ok<AGROW>
    sectionNameOut = [sectionNameOut; sn(:)]; %#ok<AGROW>
    subjectPathsOut = [subjectPathsOut; repmat(subjectPaths(i),length(sp),1)]; %#ok<AGROW>

    % Get section's iteration
    sectionIterationOut = [sectionIterationOut; stackConfigJson.sections.iterations(:)]; %#ok<AGROW>
    
    % Get section's number in subject
    sectionNumberOut = [sectionNumberOut; (1:length(stackConfigJson.sections.names(:)))']; %#ok<AGROW>
end
fprintf(']. Done!\n');

%% Define st (status) structure
st.subjectNames = cellfun(@s3GetSubjectName,subjectPathsOut,'UniformOutput',false);
st.subjectPahts = subjectPathsOut;
st.sectionNames = sectionNameOut;
st.sectionPahts = sectionPathsOut;
st.iteration = sectionIterationOut;
st.sectionNumber = sectionNumberOut;
st.fluorescenceImagingDate = cell(size(st.sectionNames));
st.isHistologyInstructionsPrepared = ones(size(st.sectionNames),'logical'); %If its on this list, it has histology instructions
st.sectionDistanceFromOCTOrigin1HistologyInstructions_um = zeros(size(st.sectionNames))*NaN;
st.isFluorescenceImageUploaded = zeros(size(st.sectionNames),'logical');
st.areFiducialLinesMarked = zeros(size(st.sectionNames),'logical');
st.nOfFiducialLinesMarked =  zeros(size(st.sectionNames))*NaN;
st.sectionDistanceFromOCTOrigin2SectionAlignment_um = zeros(size(st.sectionNames))*NaN;
st.isRanStackAlignment = zeros(size(st.sectionNames),'logical');
st.isSectionProperlyAlingedWithStack = zeros(size(st.sectionNames),'logical');
st.isSectionPartOfAlingedStack = zeros(size(st.sectionNames),'logical');
st.sectionDistanceFromOCTOrigin3StackAlignment_um = zeros(size(st.sectionNames))*NaN;
st.isHistologyImageUploaded = zeros(size(st.sectionNames),'logical');
st.isCompletedHistologyFluorescenceImageRegistration = zeros(size(st.sectionNames),'logical');
st.isCompletedOCTHistologyFineAlignment = zeros(size(st.sectionNames),'logical');
st.sectionDistanceFromOCTOrigin4FineAlignment_um = zeros(size(st.sectionNames))*NaN;
st.isQualityControlMaskGenerated = zeros(size(st.sectionNames),'logical');
st.areaOfQualityData_mm2 = zeros(size(st.sectionNames))*NaN;

st.notes = sprintf([ ...
    'subjectNames, subjectPahts - direct path to the subject corresponding to the section.\n' ...
    'sectionNames, sectionPahts - section name and direct path to the specific section\n.' ...
    'iteration - iteration number that this section was taken as part of.\n' ...
    'sectionNumber - section''s number in subject\n' ...
    'fluorescenceImagingDate - section scan date - time string.\n' ...
    'isHistologyInstructionsPrepared - was histology instructions exist for this section.\n' ... 
    'sectionDistanceFromOCTOrigin1HistologyInstructions_um - distance between section to OCT origin in microns, best guess according to the time histology instructions were made.' ...
    'isFluorescenceImageUploaded - was fluorescence image scanned and uploaded for this section.\n' ...
    'areFiducialLinesMarked - are fiducial lines marked in fluorescence image?\n' ...
    'nOfFiducialLinesMarked - number of marked lines for each section. Set to nan if no lines were marked.\n' ...
    'sectionDistanceFromOCTOrigin2SectionAlignment_um - distance between section to OCT origin in microns, single plane fit of this section. Nan if doesn''t exist.\n' ...
    'isRanStackAlignment - is stack alignment algroithm ran on this section?\n' ...
    'isSectionProperlyAlingedWithStack - is section aligned with its iteration stack, was it used to generate stack alignment? If set to false it was an outlier.\n' ...
    'isSectionPartOfAlingedStack - is stack iteration associated with this section aligned, even if this section itself not alignable.\n' ...
    'sectionDistanceFromOCTOrigin3StackAlignment_um - distance between section to OCT origin in microns according to stack alignment. Nan if doesn''t exist.\n' ...
    'isHistologyImageUploaded - was H&E image uploaded.\n' ...
    'isCompletedHistologyFluorescenceImageRegistration - was H&E image aligned with fluorescence image.\n' ...
    'isCompletedOCTHistologyFineAlignment - was fine alignment completed between OCT and histology.\n' ...
    'sectionDistanceFromOCTOrigin4FineAlignment_um - distance between section to OCT origin in microns according to fine alignment. Nan if doesn''t exist.\n' ...
    'isQualityControlMaskGenerated - is ran quality control on image.\n' ...
    'areaOfQualityData_mm2 - at the aligned image, how big is the area which has high quality data.\n' ...
    ]);

%% Loop over each section, get statistics for each
fprintf('Processing %d sections, wait for 20 starts [ ',length(sectionPathsOut));
for i=1:length(sectionPathsOut)
    if mod(i,round(length(sectionPathsOut)/20)) == 0
        fprintf('* ');
    end
    
    slideConfigFilePath = awsModifyPathForCompetability(...
        [sectionPathsOut{i} '/SlideConfig.json']);
    
    % Does slide config exist?
    if ~awsExist(slideConfigFilePath,'File')
        continue;
    end
    slideConfigJson = awsReadJSON(slideConfigFilePath);
    
    % Read stack config if required
    if i==1 || strcmp(st.subjectPahts{i-1},st.subjectPahts{i})
        stackConfigJson = awsReadJSON([st.subjectPahts{i} 'Slides/StackConfig.json']);
    end
    
    % Get stack position according to histology instructions
    dist_um = arrayfun(@(hi)((-hi.estimatedDistanceFromFullFaceToOCTOrigin_um+hi.sectionDepthsRequested_um)'),...
        stackConfigJson.histologyInstructions.iterations,'UniformOutput',false);
    dist_um = [dist_um{:}];
    dirFlip = [stackConfigJson.stackAlignment.isPlaneNormalSameDirectionAsCuttingDirection];
    st.sectionDistanceFromOCTOrigin1HistologyInstructions_um(i) = ...
        dist_um(st.sectionNumber(i)).* dirFlip(st.iteration(i));
    
    % Stack alignment plane position, stack alignment can happen even if
    % nothing is known about this slide except it was requested from histology.
    if isfield(stackConfigJson,'stackAlignment')
        planeDistanceFromOCTOrigin_um = ...
            cellfun(@(x)(x(:)'),{stackConfigJson.stackAlignment.planeDistanceFromOCTOrigin_um},'UniformOutput',false);
        planeDistanceFromOCTOrigin_um = [planeDistanceFromOCTOrigin_um{:}];
        if i<length(planeDistanceFromOCTOrigin_um)
            planeDistanceFromOCTOrigin_um = planeDistanceFromOCTOrigin_um(st.sectionNumber(i));
        else
            planeDistanceFromOCTOrigin_um = nan; % No stack alignment data for this section.
        end

        % Is section part of aligned stack and what is its distance
        if ~isnan(planeDistanceFromOCTOrigin_um)
            st.isSectionPartOfAlingedStack(i) = true;
            st.sectionDistanceFromOCTOrigin3StackAlignment_um(i) = planeDistanceFromOCTOrigin_um;
        end
        % isSectionProperlyAlingedWithStack - TBD HERE!
    else
        % No stack alignment calculated yet, do nothing.
    end
    
    % Photobleached lines image uploaded
    if isfield(slideConfigJson,'photobleachedLinesImagePath')
        st.isFluorescenceImageUploaded(i) = true;
    else
        continue;
    end
    
    % Fiducial lines marked & how many?
    if isfield(slideConfigJson,'FM') && isfield(slideConfigJson.FM,'fiducialLines')
        st.areFiducialLinesMarked(i) =  true;
        st.nOfFiducialLinesMarked(i) = sum([slideConfigJson.FM.fiducialLines.group] ~= 't');
        st.fluorescenceImagingDate{i} = slideConfigJson.FM.imagedAt;
        st.sectionDistanceFromOCTOrigin2SectionAlignment_um(i) = slideConfigJson.FM.singlePlaneFit.d*1e3;
    else
        continue;
    end
    
    % Was stack alignment ran?
    if (isfield(stackConfigJson,'stackAlignment') && ...
            st.iteration(i) <= length(stackConfigJson.stackAlignment))
        st.isRanStackAlignment(i) = true;
    else
        continue;
    end
    
    % Do we have histology scanned?
    if isfield(slideConfigJson,'histologyImageFilePath')
        st.isHistologyImageUploaded(i) = true;
    else
        continue;
    end
    
    % Is histology aligned with fluorescence image?
    if isfield(slideConfigJson,'FMOCTAlignment')
        st.isCompletedHistologyFluorescenceImageRegistration(i) = true;
    else
        continue;
    end
    
    % Was fine alignment ran?
    if (    isfield(slideConfigJson.FM,'singlePlaneFit_FineAligned') && ...
            isfield(slideConfigJson,'alignedImagePath_Histology') && ...
            isfield(slideConfigJson,'alignedImagePath_OCT') ...
            )
        st.isCompletedOCTHistologyFineAlignment(i) = true;
        st.sectionDistanceFromOCTOrigin4FineAlignment_um(i) = ...
            slideConfigJson.FM.singlePlaneFit_FineAligned.distanceFromOrigin_mm*1e3;
    else
        continue;
    end
    
    % Was mask generated?
    if isfield(slideConfigJson,'alignedImagePath_Mask')
        st.isQualityControlMaskGenerated(i) = true;
    else
        continue;
    end
    
    % Figure out the area of good data
    [msk, metaData] = yOCTFromTif(...
        [st.sectionPahts{i} slideConfigJson.alignedImagePath_Mask]);
    nPixelsWithGoodData = sum(msk(:)==0);
    pixelArea_um2 = diff(metaData.x.values(1:2))*diff(metaData.z.values(1:2));
    st.areaOfQualityData_mm2(i) = nPixelsWithGoodData*pixelArea_um2/1e3^2;
end
fprintf(']. Done!\n');
