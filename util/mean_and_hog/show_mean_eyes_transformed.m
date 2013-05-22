clear;
root = '~/Desktop/cropped_eyes_transformed_new_pl/';
D = rdir([root '**/*.png']);
%% Mean over the whole set
im = imread(D(1).name);
h = size(im, 1); w = size(im, 2);
total_left = zeros(h, w, 3);
total_right = zeros(h, w, 3);
N = numel(D);

fprintf('Calculating mean images...\n');
for j=1:numel(D)
    imname = D(j).name;
    im = im2double(imread(imname));
    if ~isempty(regexp(imname, 'left')) % Left eye
        total_left = total_left + im;
    else
        total_right = total_right + im;
    end
    
end
fprintf('Done!\n');

%%
mean_left = total_left/(N/2);
mean_right = total_right/(N/2);
figure;
mean_right = mean_right.^2;
mean_left = mean_left.^2;
mean_right = mean_right./max(max(max(mean_right)));
mean_left = mean_left./max(max(max(mean_left)));
subplot(2, 2, 1); imshow(mean_right);
subplot(2, 2, 2); imshow(mean_left);
subplot(2, 2, 3); imshow(rgb2gray(mean_right));
subplot(2, 2, 4); imshow(rgb2gray(mean_left));

%% 9 class mean images
clear;
dataPath = '~/Desktop/cropped_eyes_transformed_new_pl/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_intensity(dataPath);
%%
total_left = zeros(50, 100, 9);
total_right = zeros(50, 100, 9);
for i=1:size(X_left, 1)
    left = reshape(X_left(i, :), 50, 100);
    right = reshape(X_right(i, :), 50, 100);
    total_left(:, :, Y_left(i, 1)) = total_left(:, :, Y_left(i, 1))+left;
    total_right(:, :, Y_right(i, 1)) = total_right(:, :, Y_right(i, 1))+right;
end

%%
mean_left = zeros(50, 100, 9);
mean_right = zeros(50, 100, 9);
for k=1:9
   ysum_left = sum(Y_left(:, 1)==k);
   ysum_right = sum(Y_right(:, 1)==k);
   mean_left(:, :, k) = (total_left(:, :, k)/ysum_left).^2;
   mean_left(:, :, k) = mean_left(:, :, k)/max(max(mean_left(:, :, k)));
   mean_right(:, :, k) = (total_right(:, :, k)/ysum_right).^2;
   mean_right(:, :, k) = mean_right(:, :, k)/max(max(mean_right(:, :, k)));
end
close all;
figure;

for k=1:9
    subplot(9, 2, (k-1)*2+1); imshow(mean_right(:, :, k)); ylabel(num2str(k)); xlabel('right');
    subplot(9, 2, (k-1)*2+2); imshow(mean_left(:, :, k)); xlabel('left');
end
tightfig;