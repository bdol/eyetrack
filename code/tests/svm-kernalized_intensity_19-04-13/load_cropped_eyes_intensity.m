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
        % Skip the first frame, whose name contains '_1_1'
        if ~isempty(strfind(D(j).name, 'left')) && isempty(strfind(D(j).name, '_1_1'))
            X_left(leftCounter, :) = I(:)';
            Y_left(leftCounter) = i;
            leftCounter = leftCounter+1;
        elseif ~isempty(strfind(D(j).name, 'right')) && isempty(strfind(D(j).name, '_1_1'))
            X_right(rightCounter, :) = I(:)';
            Y_right(rightCounter) = i;
            rightCounter = rightCounter+1;
        end
    end
end

% Remove all zero entry rows
zero_left = bsxfun(@eq, sum(X_left, 2), 0);
zero_right = bsxfun(@eq, sum(X_right, 2), 0);
assert(all(zero_left==zero_right));
X_left(zero_left, :) = [];
Y_left(zero_left) = [];
X_right(zero_right, :) = [];
Y_right(zero_right) = [];


end