%% ADD PATHS
clear
clc
% external libraries used
addpath(genpath('../../../third_party_libs/vlfeat-0.9.16/'));
addpath(genpath('../../../third_party_libs/libsvm/'));
% data processing tools used
addpath(genpath('../../data_processing'));
% path to images
subj_names = {'../../../all_images/cropped_eyes_transformed_tps_new/'};

%% ORGANISE DATA
N_boardnums = 9;
N_folds = 4;
N_models = 8;
% HOG Parameters
cellSize = 8;
svm_g = 0.2;
% xval params
c_arr = zeros(N_models,1); c_arr(1) = 0.01; c_arr(2) = 0.01; c_arr(3) = 0.02; c_arr(4) = 0.02; c_arr(5) = 0.1; c_arr(6) = 0.1; c_arr(7) = 0.2; c_arr(8) = 0.2;
numorient_arr = zeros(N_models,1); numorient_arr(1) = 9; numorient_arr(2) = 21; numorient_arr(3) = 9; numorient_arr(4) = 21; numorient_arr(5) = 9; numorient_arr(6) = 21; numorient_arr(7) = 9; numorient_arr(8) = 21;

[l_ims r_ims] = load_cropped_eye_intensity_linux(subj_names{1});
N = length(l_ims);
subjectwise_split = 1;
frames_per_subject = N_boardnums * 2;
percent = 85;
[train_ind test_ind] = train_test_setup(N, percent, subjectwise_split, frames_per_subject);
N_xval = length(train_ind);
xval = xval_setup(N_xval, N_folds, subjectwise_split, frames_per_subject);

%% TRAIN LINEAR SVM - builtin multiclass
model_xval_acc = zeros(N_models, N_folds);
for model = 1:N_models
fprintf(sprintf('Running xval for model %d\n',model));
    % run cross validation
    for fold = 1:N_folds
        fprintf(sprintf('\tTesting on fold %d of %d\n',fold,N_folds));
        fold_train_ind = train_ind(xval(fold).train_indices);
        fold_test_ind = train_ind(xval(fold).test_indices);
        % extract hog features for left eye images
        training_images = [l_ims(fold_train_ind)];
        [train_mat_left sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images, cellSize, numorient_arr(model));
        % extract hog features for right eye images
        training_images = [r_ims(fold_train_ind)];
        [train_mat_right sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images, cellSize, numorient_arr(model));
        train_mat = [train_mat_left train_mat_right];
        % training labels
        train_lab = [l_ims(fold_train_ind).board_num]';
        % train multi class svm
        model_fold = svmtrain(train_lab, train_mat, sprintf('-c %g -t 0 -g %g',c_arr(model),svm_g));
        % test on left-out fold
        test_mat_left = extract_hog_features(l_ims(fold_test_ind), cellSize, numorient_arr(model));
        test_mat_right = extract_hog_features(r_ims(fold_test_ind), cellSize, numorient_arr(model));
        test_mat = [test_mat_left test_mat_right];
        test_lab = [l_ims(fold_test_ind).board_num]';
        [a,acc,p] = svmpredict(test_lab, test_mat, model_fold);
        model_xval_acc(model,fold) = acc(1);
    end
end

%% BEST MODEL
avg_model_xval_acc = mean(model_xval_acc);
[val best_model_ind] = max(avg_model_xval_acc);
% train best model on all training data
training_images = [l_ims(train_ind)];
[train_mat_left sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images, cellSize, numorient_arr(best_model_ind));
training_images = [r_ims(train_ind)];
[train_mat_right sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images, cellSize, numorient_arr(best_model_ind));
train_mat = [train_mat_left train_mat_right];
train_lab = [l_ims(train_ind).board_num]';
% train multi class svm
best_model = svmtrain(train_lab, train_mat, sprintf('-c %g -t 0 -g %g',c_arr(best_model_ind),svm_g));

% test on best model
test_mat_left = extract_hog_features(l_ims(test_ind), cellSize, numorient_arr(best_model_ind));
test_mat_right = extract_hog_features(r_ims(test_ind), cellSize, numorient_arr(best_model_ind));
test_mat = [test_mat_left test_mat_right];
test_lab = [l_ims(test_ind).board_num]';
[linear_svm_pred,acc,p] = svmpredict(test_lab, test_mat, best_model);
linear_svm_accuracy = acc(1)/100;

test_lab_alt = test_lab;
test_lab_alt(test_lab_alt==1) = 6;      test_lab_alt(test_lab_alt==6) = 1;
test_lab_alt(test_lab_alt==2) = 7;      test_lab_alt(test_lab_alt==7) = 2;
test_lab_alt(test_lab_alt==3) = 8;      test_lab_alt(test_lab_alt==8) = 3;
test_lab_alt(test_lab_alt==4) = 9;      test_lab_alt(test_lab_alt==9) = 4;
test_lab_alt(test_lab_alt==5) = -1;
linear_svm_acc_new_penalty = (sum(linear_svm_pred == test_lab) + 0.5*sum(linear_svm_pred == test_lab_alt)) ./ numel(test_lab);

%% TRAIN ONE-VS-ALL LINEAR SVM
% train a separate model for each board number
model_xval_acc = zeros(N_boardnums, N_models, N_folds);
for board_num = 1:N_boardnums
    fprintf(sprintf('Training models for board number %d\n',board_num));
    for model = 1:N_models
        fprintf(sprintf('Running xval for model %d\n',model));
        % run cross validation
        for fold = 1:N_folds
            fprintf(sprintf('\tTesting on fold %d of %d\n',fold,N_folds));
            fold_train_ind = train_ind(xval(fold).train_indices);
            fold_test_ind = train_ind(xval(fold).test_indices);
            % extract hog features for left eye images
            training_images = [l_ims(fold_train_ind)];
            [train_mat_left sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images, cellSize, numorient_arr(model));
            % extract hog features for right eye images
            training_images = [r_ims(fold_train_ind)];
            [train_mat_right sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images, cellSize, numorient_arr(model));
            train_mat = [train_mat_left train_mat_right];
            % training labels
            train_lab = [l_ims(fold_train_ind).board_num]';
            % train multi class svm
            model_fold = svmtrain(double(train_lab==board_num), train_mat, sprintf('-c %g -t 0 -g %g',c_arr(model),svm_g));
            % test on left-out fold
            test_mat_left = extract_hog_features(l_ims(fold_test_ind), cellSize, numorient_arr(model));
            test_mat_right = extract_hog_features(r_ims(fold_test_ind), cellSize, numorient_arr(model));
            test_mat = [test_mat_left test_mat_right];
            test_lab = [l_ims(fold_test_ind).board_num]';
            [a,acc,p] = svmpredict(double(test_lab==board_num), test_mat, model_fold);
            model_xval_acc(board_num, model,fold) = acc(1);
        end
    end
end

%% BEST MODEL - ONE-VS-ALL SVM
% prepare all training data
training_images = [l_ims(train_ind)];
[train_mat_left sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images, cellSize, numorient_arr(best_model_ind));
training_images = [r_ims(train_ind)];
[train_mat_right sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images, cellSize, numorient_arr(best_model_ind));
train_mat = [train_mat_left train_mat_right];
train_lab = [l_ims(train_ind).board_num]';

best_models = cell(N_boardnums,1);
for board_num = 1:N_boardnums
    avg_model_xval_acc = mean(model_xval_acc(board_num,:,:));
    [val best_model_ind] = max(avg_model_xval_acc);
    % train best model on all training data
    best_models{board_num} = svmtrain(double(train_lab==board_num), train_mat, sprintf('-c %g -t 0 -g %g -b 1',c_arr(best_model_ind),svm_g));
end

% prepare all testing data
test_mat_left = extract_hog_features(l_ims(test_ind), cellSize, numorient_arr(best_model_ind));
test_mat_right = extract_hog_features(r_ims(test_ind), cellSize, numorient_arr(best_model_ind));
test_mat = [test_mat_left test_mat_right];
test_lab = [l_ims(test_ind).board_num]';
% test on best model
for board_num = 1:tot_board_nums
    [a,acc,p] = svmpredict(double(test_lab==board_num), test_mat, best_models{board_num},'-b 1');
    linear_svm_prob(:,board_num) = p(:, best_models{board_num}.Label==1);
end

[temp linear_svm_pred] = max(linear_svm_prob,[],2);
linear_svm_acc = sum(linear_svm_pred == test_lab) ./ numel(test_lab);
linear_svm_C = confusionmat(test_lab, linear_svm_pred);
imagesc(linear_svm_C);
test_lab_alt = test_lab;
test_lab_alt(test_lab_alt==1) = 6;      test_lab_alt(test_lab_alt==6) = 1;
test_lab_alt(test_lab_alt==2) = 7;      test_lab_alt(test_lab_alt==7) = 2;
test_lab_alt(test_lab_alt==3) = 8;      test_lab_alt(test_lab_alt==8) = 3;
test_lab_alt(test_lab_alt==4) = 9;      test_lab_alt(test_lab_alt==9) = 4;
test_lab_alt(test_lab_alt==5) = -1;
linear_svm_acc_new_penalty = (sum(linear_svm_pred == test_lab) + 0.5*sum(linear_svm_pred == test_lab_alt)) ./ numel(test_lab);
