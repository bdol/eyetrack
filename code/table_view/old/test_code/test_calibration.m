clear; close all; addpath ../../../util/raw_processing/

rgb = imread('/Applications/RGBDemo/low/A00362807515047A/view0000-70.446999/raw/color.png');
imshow(rgb);

% depth = 255*convert_rgbdemo_raw('/Applications/RGBDemo/test/A00362807515047A/view0000-134.171005/raw/depth.raw');
% figure; imagesc(depth);

figure;
rgbhigh = imread('/Applications/RGBDemo/highdepth/A00362807515047A/view0000-11.087000/raw/color.png');
rgbhigh = rgbhigh(1:960, :, :);
rgbhigh = imresize(rgbhigh, [480 640]);
imshow(rgbhigh);

figure;
depthhigh = 255*convert_rgbdemo_raw('/Applications/RGBDemo/highdepth/A00362807515047A/view0000-11.087000/raw/depth.raw');
imagesc(depthhigh);

