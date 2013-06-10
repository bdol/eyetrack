%% This file loads the LRC dataset and outputs a set of cross validation 
%  folds in the format that libsvm takes

% rootPath should be the top-level directory containing the clean cropped
% eyes set
clear;

outDir = '/Users/bdol/code/eyetrack_data/lrc/';
if ~exist(outDir, 'dir')
    mkdir(outDir)
end

subj_names = {'/Users/bdol/code/eyetrack_data/cropped_eyes_clean/'};
[l_ims r_ims] = load_lrc_cropped_eyes('/Users/bdol/code/eyetrack_data/cropped_eyes_clean/','CenterBadImagesFile','~/code/eyetrack/code/data_processing/center_bad_ims.txt','LRBadImagesFile','~/code/eyetrack/code/data_processing/lr_bad_ims.txt');

%% Setup xval partitions
N_folds = 8;
subject_numbers = unique([l_ims(:).subject_index]);
N_subjects = length(subject_numbers);
subject_numbers = unique([l_ims(:).subject_index]);
training_subj = subject_numbers(randperm(N_subjects));
xval = xval_setup(l_ims, training_subj, N_folds);

%% Create concatenated intensity feature files for libsvm
n_pix = numel(rgb2gray(l_ims(1).img));;

for fold = 1:1
    fprintf('Creating libsvm files for fold %d of %d.\n', fold, N_folds);
    train_file = fopen([outDir 'train_' num2str(fold) '.txt'], 'w');
    test_file = fopen([outDir 'test_' num2str(fold) '.txt'], 'w');
    
    fold_train_ind = xval(fold).train_indices;
    fold_test_ind = xval(fold).test_indices;
    
    t = CTimeleft(numel(l_ims));
    
    % Write to training file
    for i=1:numel(fold_train_ind)
        t.timeleft();
        
        y_i = l_ims(i).label;

        x_i_left = reshape(mat2gray(rgb2gray(l_ims(i).img)), 1, n_pix);
        x_i_right = reshape(mat2gray(rgb2gray(r_ims(i).img)), 1, n_pix);
        x_i = [x_i_left x_i_right];
        
        fprintf(train_file, '%d ', y_i);
        for j=1:n_pix
            fprintf(train_file, '%d:%f ', j, x_i(j));
        end
        fprintf(train_file, '\n');
    end
    
    % Write to testing file
    for i=1:numel(fold_test_ind)
        t.timeleft();
        
        y_i = l_ims(i).label;

        x_i_left = reshape(mat2gray(rgb2gray(l_ims(i).img)), 1, n_pix);
        x_i_right = reshape(mat2gray(rgb2gray(r_ims(i).img)), 1, n_pix);
        x_i = [x_i_left x_i_right];
        
        fprintf(test_file, '%d ', y_i);
        for j=1:n_pix
            fprintf(test_file, '%d:%f ', j, x_i(j));
        end
        fprintf(test_file, '\n');
    end
    
    fclose(train_file);
    fclose(test_file);
end