function [X_left Y_left X_right Y_right] = ...
    load_cropped_eyes_intensity(rootPath)

D = rdir([rootPath '*/*/*.png']);
N = numel(D);
I = rgb2gray(imread(D(1).name));
M = numel(I);

X_left = zeros(N/2, M);
Y_left = zeros(N/2, 1);
X_right = zeros(N/2, M);
Y_right = zeros(N/2, 1);

leftCounter = 1;
rightCounter = 1;
for i=1:9
    D = rdir([rootPath '*/' num2str(i) '/*.png']);
    for j=1:numel(D)
        I = rgb2gray(imread(D(j).name));
        if ~isempty(strfind('left', D(j).name))
            X_left(leftCounter, :) = I(:)';
            Y_left(leftCounter) = i;
            leftCounter = leftCounter+1;
        else
            X_right(rightCounter, :) = I(:)';
            Y_right(rightCounter) = i;
            rightCounter = rightCounter+1;
        end
    end
end

end