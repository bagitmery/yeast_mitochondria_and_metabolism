% cellstar_to_mitograph(path, timepoints, microns)
% for 100x TIRF objective: 0.160 µm/pixel

function cellstar_to_mitograph_carbons(path, stagepos, microns)
parpool('local', str2num(getenv('SLURM_CPUS_PER_TASK')))

directory = dir(path);
trackpath = [path, '/segments/tracking/tracking.mat'];
tracking = load(trackpath, 'tracking');
tracking = tracking.tracking;
[cells, times] = size(tracking.traces);

segpath = [path, '/segments'];
segdirectory = dir(segpath);

stagereg = 's[0-9]{1,2}';

outellipse = fullfile(path, 'extracted_ROI_volumes.txt');
fellipse = fopen(outellipse, 'wt');
fprintf(fellipse, 'cellstar-to-mitograph.m\n');
fprintf(fellipse, ['source directory: ', path, '\n']);
fprintf(fellipse, 'roi_name	major_ellipse_axis (pixels)	minor_ellipse_axis (pixels)	projected_volume (pixels)	projected_volume (microns^3)\n\n');
fclose(fellipse);

% this saves all data in a dummy timepoint file
% to use, make sure to comment out lines 36-37)
% outdir = ['t', num2str(0, '%03i')];
% mkdir(path, outdir);


% this would save all data in a separate directory for each timepoint
outdir =  't001';
mkdir(path, outdir);

% iterate over all segmented images
for s = 1:length(segdirectory)
    % if it's indeed segmentation data
    if ~isempty(regexp(segdirectory(s).name,'_segmentation.mat', 'once'))
        segments = fullfile(segpath, segdirectory(s).name);
        % figure out the stage position, for later
        stagepoint = ['s', num2str(stagepos)];
        % regular expression for the corresponding fluorescence image
        fluorreg = 'w[2-5][^]*';
        % iterate over potential fluorescence images
        for f = 1:length(directory)
            %...and find the correct one
            if ~isempty(regexp(directory(f).name, fluorreg, 'once'))
                % find the length of the z-stack
                info = imfinfo(fullfile(path, directory(f).name));
                % load the segments
                snakes = load(segments, 'snakes');
                snakes = snakes.snakes;
                % iterate over all cells
                for c = 1:cells
                    % identify cell ID number
                    cellID = tracking.traces(c, 1);
                    % if this corresponds to a cell in the frame...
                    if (cellID~=0)
                        % extract the ROI coordinates
                        coordinates = [snakes{1, cellID}.x, snakes{1, cellID}.y];
                        % determine the name of the output file 
                        % (the fluorescence image name + cell ID)
                        outname = [directory(f).name(1:end-4), '_cell_', num2str(c, '%03i'), '.tif'];
                        output = fullfile(path, outdir, outname);                            
                        % iterate over every slice in the z-stack
                        for z = 1:length(info)
                            % open the slice
                            slice = imread(fullfile(path, directory(f).name), 'Index', z, 'Info', info);
                            % create a mask using the ROI
                            mask = roipoly(slice, coordinates(:, 1), coordinates(:, 2));
                            % create a bounding box based on the mask
                            % syntax: box.BoundingBox(1) = xmin, *(2) =
                            % ymin, *(3) = length, *(4) = width
                            % in MATLAB, (0,0)/origin is the upper left
                            box = regionprops(mask, 'BoundingBox');

                            % expand the mask
                            dilated = imdilate(mask, ones(5,5));
                            % define the band by which the mask was
                            % expanded
                            band = dilated & ~mask;
                            % background signal = median in this band
                            background = median(slice(band));
                            % backround applied to all pixels not in
                            % the ROI
                            partitioned_background = uint16(~mask) * background;
                            % foreground = pixels within the ROI
                            partitioned_foreground = slice.* uint16(mask);
                            % total image = foreground + background
                            partitioned_total = partitioned_background + partitioned_foreground;

                            % expand the bounding box from above to
                            % 100x100 pixels
                            % shift the upper left boundary of the box
                            % to center the cell within it
                            % if the box already exceeds 90 pixels in
                            % any dimension: add 10 pixel padding in
                            % both x and y, and center the cell within
                            % the box
                            %if box.BoundingBox(3) > 90
                            %    box_length = box.BoundingBox(3) + 10;
                            %    box_x = box.BoundingBox(1) - 5;
                            %else
                            %    box_length = 100;
                            %    box_x = box.BoundingBox(1) - floor((box_length - box.BoundingBox(1))/2);
                            %end
                            %if box.BoundingBox(4) > 90
                            %    box_height = box.BoundingBox(4) + 10;
                            %    box_y = box.BoundingBox(2) - 5;
                            %else
                            %    box_height = 100;
                            %    box_y = box.BoundingBox(2) - floor((box_height - box.BoundingBox(2))/2);
                            %end

                            % UPDATED: whatever the size of the
                            % bounding box, add 20 pixels to both the
                            % height and width. Shift the upper left
                            % boundary up by 10 pixels and left by 10
                            % pixels to center the cell within this
                            % padded margin
                            box_x = box.BoundingBox(1) - 10;
                            box_y = box.BoundingBox(2) - 10;
                            box_length = box.BoundingBox(3) + 20;
                            box_height = box.BoundingBox(4) + 20;


                            % crop the image down to the expanded
                            % bounding box
                            cropped = imcrop(partitioned_total, [box_x, box_y, box_length, box_height]);

                            % save
                            imwrite(cropped, output, 'Writemode', 'append', 'Compression', 'none');

                            % on the first slice of every image:
                            if z == 1
                                % fit an ellipse to the ROI
                                ellipse = fit_ellipse(coordinates(:, 1), coordinates(:, 2));
                                % find the semi-major (a_m) and
                                % semi-minor (c_m) axes in microns
                                a_m = ellipse.long_axis / 2.0 * microns;
                                c_m = ellipse.short_axis / 2.0 * microns;
                                % calculate the projected volume in
                                % pixels
                                ellipse_volume_pixels = (4/3) * pi * (ellipse.long_axis / 2.0) * (ellipse.short_axis / 2.0) * (ellipse.short_axis / 2.0);
                                % calculate the projected volume in
                                % microns
                                ellipse_volume = (4/3) * pi * a_m * c_m * c_m;
                                % write to volume file
                                fellipse = fopen(outellipse, 'at');
                                roi_name = [stagepoint, '_t001_cell_', num2str(c, '%03i')];
                                fprintf(fellipse, [roi_name, '\t', num2str(ellipse.long_axis), '\t', num2str(ellipse.short_axis), '\t', num2str(ellipse_volume_pixels), '\t', num2str(ellipse_volume), '\n']);
                                fclose(fellipse);   

                            end
                        end
                    end
                end
            end
        end
        % print file name as an indicator of progress
        disp(segdirectory(s).name);
    end
end


delete(gcp);
exit;
end
                                    
                                