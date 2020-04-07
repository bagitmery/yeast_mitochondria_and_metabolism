%batch_cellstar_segmentation(path_to_bfs, fluor)
% Performs headless segmentation of brightfield images using cellstar
% Uses maximum precision of 20

% Designed to be accompanied by a shell script that transfers over a specific 
% set of brightfield and accompanying fluorescent images
% in an enclosed directorty, 'fluorescence_projections'

% fluor is an boolean indicating the presence of a fluorophore to be
% connected to the brightfields

function batch_cellstar_segmentation(path_to_bfs, fluor)

% open a parallel pool
% parpool('local', 2);
parpool('local', str2num(getenv('SLURM_CPUS_PER_TASK')))

% import CellStar code
addpath('CellStar');
addpath('CellStar/ExampleFiles', 'CellStar/UserInterface', ...
    'CellStar/Segmentation', 'CellStar/Misc', 'CellStar/Tracking');

directory = dir(path_to_bfs);

% construct a list of files: all .tifs 
files = {fullfile(path_to_bfs, ['*w1*.tif'])};

% a subdirectory "segments", for output
outputdir = [path_to_bfs, 'segments'];

% start with default parameters, highest precision, and 35-pixel cell
% diameter
parameters = DefaultParameters('precision', 20, 'avgCellDiameter', 35);
parameters.debugLevel = 3;

% set to batch mode
parameters.interfaceMode = 'batch';


% EXCLUDED use the ML-optimized contour parameters from
% 2019_02_14_glucose/s1
parameters.segmentation.stars.smoothness = 4.3129;
parameters.segmentation.stars.gradientWeight = 15.4820;
parameters.segmentation.stars.brightnessWeight = 0.0442;
parameters.segmentation.stars.sizeWeight = [20.1022853773585,28.1431995283019,40.2045707547170,64.3273132075472,104.531883962264,160.818283018868,241.227424528302,402.045707547170,643.273132075472];
parameters.segmentation.stars.cumBrightnessWeight = 304.4500;
parameters.segmentation.stars.points = 80;
parameters.segmentation.stars.parameterLearningRingResize = 0;
parameters.segmentation.stars.step = 0.0067;

% EXCLUDED use the ML-optimized ranking parameters from
% 2019_02_14_glucose/s1
parameters.segmentation.ranking.avgBorderBrightnessWeight = 0.5131;
parameters.segmentation.ranking.avgInnerBrightnessWeight = 1;
parameters.segmentation.ranking.avgInnerDarknessWeight = -0.0824;
parameters.segmentation.ranking.maxInnerBrightnessWeight = 0.0292;
parameters.segmentation.ranking.logAreaBonus = 0.2629;
parameters.segmentation.ranking.stickingWeight = 0.2917;
parameters.segmentation.ranking.shift = 0.6800;

% increase iterations on segmentation and tracking
% (should automatically increase as a function of precision, though)
parameters.segmentation.steps = 10;
parameters.tracking.iterations = 65;

% use the seeding parameters from 1_15_16/s1_to_t36
parameters.segmentation.seeding.from.houghTransform = 0;
parameters.segmentation.seeding.from.cellBorder = 1;
parameters.segmentation.seeding.from.cellBorderRandom = 4;
parameters.segmentation.seeding.from.cellContent = 1;
parameters.segmentation.seeding.from.cellContentRandom = 4;
parameters.segmentation.seeding.from.cellBorderRemovingCurrSegments = 1;
parameters.segmentation.seeding.from.cellBorderRemovingCurrSegmentsRandom = 2;
parameters.segmentation.seeding.from.cellContentRemovingCurrSegments = 1;
parameters.segmentation.seeding.from.cellContentRemovingCurrSegmentsRandom = 4;
parameters.segmentation.seeding.from.snakesCentroids = 1;
parameters.segmentation.seeding.from.snakesCentroidsRandom = 4;
parameters.segmentation.seeding.from.mouseclick = 0;
parameters.segmentation.seeding.from.mouseclickRandom = 10;

% set output directory
parameters.files.destinationDirectory = outputdir;

% set background output
%parameters.files.background.imageFile = fullfile(outputdir, 'background.png');

% automated generation of background
parameters.segmentation.background.manualEdit = false;

% specify input brightfield files
parameters.files.imagesFiles = files;

% when applicable, map fluorescent files to their brightfield analogues
if fluor
    fluorfiles = {fullfile(path_to_bfs, ['*w[2-9]*.tif'])};
    parameters.files.additionalChannels{1, 1}.fileMap = '';
    parameters.files.additionalChannels{1, 1}.files = fluorfiles;
    parameters.files.additionalChannels{1, 1}.computeFluorescence = 'max';
end

parameters.maxTheads = 4;

% EXCLUDED ensure a complete set of parameters
%parameters = CompleteParameters(parameters);

% segment
parameters = RunSegmentation(parameters);

% track
tracking = ComputeFullTracking(parameters);


delete(gcp);
exit;
end





