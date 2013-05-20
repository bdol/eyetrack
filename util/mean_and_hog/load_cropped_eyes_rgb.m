function [X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_rgb(rootPath)
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

X_left = zeros(N/2, 3*M);
Y_left = zeros(N/2, 2);
X_right = zeros(N/2, 3*M);
Y_right = zeros(N/2, 2);
S(N/2).left_filename = '';
subjNums = [];

leftCounter = 1;
rightCounter = 1;
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
            X_left(leftCounter, :) = reshape(I, 1, 3*M);
            Y_left(leftCounter, 1) = i;
            Y_left(leftCounter, 2) = s_index;
            
            S(leftCounter).left_filename = D(j).name;
            S(leftCounter).subj_index = s_index;
            
            leftCounter = leftCounter+1;
        elseif ~isempty(strfind(D(j).name, 'right')) && isempty(regexp(D(j).name, '_1_[lr]'))
            X_right(rightCounter, :) = reshape(I, 1, 3*M);
            Y_right(rightCounter, 1) = i;
            Y_right(rightCounter, 2) = s_index;
            
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