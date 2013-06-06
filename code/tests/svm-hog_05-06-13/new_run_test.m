%% ADD PATHS
clear
clc
% external libraries used
addpath(genpath('../../../third_party_libs/vlfeat-0.9.16/'));
addpath(genpath('../../../third_party_libs/libsvm/'));
% path to images
subj_names = {'../../../all_images/cropped_eyes_corrected/'};

%% ORGANISE DATA
N_boardnums = 9;
N_models = 8;
% HOG Parameters
cellSize = 8;
svm_g = 0.2;
% xval params
c_arr = zeros(N_models,1); c_arr(1) = 0.01; c_arr(2) = 0.01; c_arr(3) = 0.02; c_arr(4) = 0.02; c_arr(5) = 0.1; c_arr(6) = 0.1; c_arr(7) = 0.2; c_arr(8) = 0.2;
numorient_arr = zeros(N_models,1); numorient_arr(1) = 9; numorient_arr(2) = 21; numorient_arr(3) = 9; numorient_arr(4) = 21; numorient_arr(5) = 9; numorient_arr(6) = 21; numorient_arr(7) = 9; numorient_arr(8) = 21;
crange = 10.^[-10:2:4];


N_folds = 4;

[l_ims r_ims] = load_lrc_cropped_eyes(subj_names{1});
subject_numbers = unique([l_ims(:).subject_index]);
N_subjects = length(subject_numbers);
percent = 85;

% split into training and testing sets
N_train=round(N_subjects*percent/100);
training_subj = subject_numbers(randperm(N_subjects));
% set up xval
xval = xval_setup(l_ims, training_subj, N_folds);


%% Extract HOG features
[l_ims_hog sample_hog l_ind_rowvec_to_hog num_orient] = extract_hog_features(l_ims);
[r_ims_hog sample_hog r_ind_rowvec_to_hog num_orient] = extract_hog_features(r_ims);

%% TRAIN LINEAR SVM - builtin multiclass
model_xval_acc = zeros(1, N_folds);
% run cross validation
for fold = 1:N_folds
    fprintf(sprintf('\tTesting on fold %d of %d\n',fold,N_folds));
    fold_train_ind = xval(fold).train_indices;
    fold_test_ind = xval(fold).test_indices;
    % extract hog features for left eye images
    train_mat_left = l_ims_hog(fold_train_ind,:);
    train_mat_right = r_ims_hog(fold_train_ind,:);
    train_mat = [train_mat_left train_mat_right];
    % training labels
    train_lab = [l_ims(fold_train_ind).label];
    train_lab = train_lab(:);
    % train multi class svm
    acc = zeros(1, numel(crange));
    for i = 1:numel(crange)
        mod = svmtrain(train_lab, train_mat, sprintf('-t 0 -v 10 -c %g -q 1 -g %g', crange(i), svm_g));
        acc(i) = mod;
    end
    [~, bestc] = max(acc);
    fprintf('Cross-val chose best C = %g\n', crange(bestc));

    model_fold = svmtrain(train_lab, train_mat, sprintf('-c %g -t 0 -g %g',bestc,svm_g));
    % test on left-out fold
    test_mat_left = l_ims_hog(fold_test_ind,:);
    test_mat_right = r_ims_hog(fold_test_ind,:);
    test_mat = [test_mat_left test_mat_right];
    test_lab = [l_ims(fold_test_ind).label];
    test_lab = test_lab(:);
    [pred,a,p] = svmpredict(test_lab, test_mat, model_fold);
    model_xval_acc(fold) = mean(pred==test_lab);
end

%% Print results
fprintf('Accuracy across folds = %g\n', mean(model_xval_acc));
fprintf(sprintf('Performance of model on folds\n %g  %g  %g  %g\n',...
    model_xval_acc(1), model_xval_acc(2), ...
    model_xval_acc(3), model_xval_acc(4)));

