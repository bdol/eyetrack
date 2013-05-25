function [X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_iris(rootPath)
% Loads the cropped eye dataset. X* contains the pixel values, and Y*
% contains the class label (1-9, for each position on the board) and the
% subject index. S is a metadata structure containing the left/right image
% filenames, the subject number, and the subject index (just a mapping from
% the subject number to an integer index, which is needed for correct cross
% validation).
D = rdir([rootPath '*/*/*.png']);
N = numel(D);
I = rgb2gray(imread(D(1).name));
M = numel(I);

X_left = zeros(N/2, M);
Y_left = zeros(N/2, 2);
X_right = zeros(N/2, M);
Y_right = zeros(N/2, 2);
S(N/2).left_filename = '';
subjNums = [];

subjIrisColorsLeft = containers.Map;
subjIrisColorsRight = containers.Map;
t = 1E-3;

leftCounter = 1;
rightCounter = 1;

% First get average iris colors
D = rdir([rootPath '*/' num2str(2) '/*.png']);
for j=1:numel(D)
    I = imread(D(j).name);
    
    % Get subject number
    ind = regexp(D(j).name, '[0-9]*.2.[NPE]');
    subjNum = str2num(D(j).name(ind:ind+3));
    % Add it to the dictionary if it's not there
    if ~isKey(subjIrisColorsLeft, num2str(subjNum))
        subjIrisColorsLeft(num2str(subjNum)) = zeros(3, 1);
        subjIrisColorsRight(num2str(subjNum)) = zeros(3, 1);
    end
    
    % Skip the first frame, whose name contains '_1_1'
    if ~isempty(strfind(D(j).name, 'left')) && isempty(regexp(D(j).name, '_1_[lr]'))
        c_subj = subjIrisColorsLeft(num2str(subjNum));
        c_im = get_iris_color(I, 50, 100, 10);
        if (all(c_subj==zeros(3, 1)))
            subjIrisColorsLeft(num2str(subjNum)) = c_im;
        else
            subjIrisColorsLeft(num2str(subjNum)) = (c_subj+c_im)/2;
        end
    elseif ~isempty(strfind(D(j).name, 'right')) && isempty(regexp(D(j).name, '_1_[lr]'))
        c_subj = subjIrisColorsRight(num2str(subjNum));
        c_im = get_iris_color(I, 50, 100, 10);
        if (all(c_subj==zeros(3, 1)))
            subjIrisColorsRight(num2str(subjNum)) = c_im;
        else
            subjIrisColorsRight(num2str(subjNum)) = (c_subj+c_im)/2;
        end
    end
end

for i=1:9
    D = rdir([rootPath '*/' num2str(i) '/*.png']);
    for j=1:numel(D)
        I = imread(D(j).name);

        % Get subject number
        ind = regexp(D(j).name, '[0-9]*.2.[NPE]');
        subjNum = str2num(D(j).name(ind:ind+3));
        s_index = find(subjNum==subjNums);
        if isempty(s_index)
            subjNums = [subjNums; subjNum];
            s_index = numel(subjNums);
        end
        
        % Skip the first frame, whose name contains '_1_1'
        if ~isempty(strfind(D(j).name, 'left')) && isempty(regexp(D(j).name, '_1_[lr]'))
            iris = get_iris(I, subjIrisColorsLeft(num2str(subjNum)));
            iris = 1-(iris-min(min(iris)))/(max(max(iris))-min(min(iris)));
            X_left(leftCounter, :) = reshape(iris, 1, M);
            Y_left(leftCounter, 1) = i;
            Y_left(leftCounter, 2) = s_index;
            
            S(leftCounter).left_filename = D(j).name;
            S(leftCounter).subj_index = s_index;
            
            leftCounter = leftCounter+1;
            
        elseif ~isempty(strfind(D(j).name, 'right')) && isempty(regexp(D(j).name, '_1_[lr]'))
            iris = get_iris(I, subjIrisColorsRight(num2str(subjNum)));
            iris = 1-(iris-min(min(iris)))/(max(max(iris))-min(min(iris)));
            X_right(rightCounter, :) = reshape(iris, 1, M);
            Y_right(rightCounter, 1) = i;
            Y_right(rightCounter, 2) = s_index;
            
            keyboard;
            
            S(rightCounter).right_filename = D(j).name;
            S(rightCounter).subj_index = s_index;
            
            rightCounter = rightCounter+1;
        end
    end
    
    fprintf('Loaded class %d of 9.\n', i);
end

% Remove all zero entry rows
zero_left = bsxfun(@eq, sum(X_left, 2), 0);
zero_right = bsxfun(@eq, sum(X_right, 2), 0);
assert(all(zero_left==zero_right));
X_left(zero_left, :) = [];
Y_left(zero_left, :) = [];
X_right(zero_right, :) = [];
Y_right(zero_right, :) = [];
S(zero_left) = [];

fprintf('Done!\n');

end