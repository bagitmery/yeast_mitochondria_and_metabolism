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


% EXCLUDED use the ML-optimized contour parameters from 1_15_16/s1_to_t36
%parameters.segmentation.stars.smoothness = 4.4579;
%parameters.segmentation.stars.gradientWeight = 22.8421;
%parameters.segmentation.stars.brightnessWeight = 0.0552;
%parameters.segmentation.stars.sizeWeight = [27.5643046755314, ...
%    38.5900265457440, 55.1286093510629, 88.2057749617006, ...
%    143.334384312763,220.514437404251,330.771656106377, ...
%    551.286093510629,882.057749617006];
%parameters.segmentation.stars.cumBrightnessWeight = 419.4021;
%parameters.segmentation.stars.points = 72;
%parameters.segmentation.stars.parameterLearningRingResize = 0;
%parameters.segmentation.stars.step = 0.0067;

% EXCLUDED use the ML-optimized ranking parameters from 1_15_16/s1_to_t36
%parameters.segmentation.ranking.avgBorderBrightnessWeight = 1;
%parameters.segmentation.ranking.avgInnerBrightnessWeight = 0.1917;
%parameters.segmentation.ranking.avgInnerDarknessWeight = -0.0567;
%parameters.segmentation.ranking.maxInnerBrightnessWeight = -0.0053;
%parameters.segmentation.ranking.logAreaBonus = -0.7957;
%parameters.segmentation.ranking.stickingWeight = 0.7873;
%parameters.segmentation.ranking.shift = -0.3669;

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





