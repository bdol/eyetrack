%% ADD PATHS
clear
clc
addpath(genpath('../../../../eyetrack/'));
subj_names = {'../../../all_images/'};
% subj_names = {'../../../all_images/cropped_eyes/1027.2.E/'};

%% ORGANISE DATA
tot_board_nums = 9;
N_folds = 5;

[l_ims r_ims] = load_cropped_eye_intensity_linux(subj_names{1});
N = length(l_ims);
subjectwise_split = 1;
frames_per_subject = tot_board_nums * 2;
xval = xval_setup(N, N_folds, subjectwise_split, frames_per_subject);

%% LINEAR SVM MULTI CLASS
xval_errors = zeros(N_folds,1);
for fold = 1:N_folds
   train_mat = extract_hog_features([l_ims(xval(fold).train_indices) r_ims(xval(fold).train_indices)]);
   train_lab = [[l_ims([xval(fold).train_indices]).board_num]'; [r_ims([xval(fold).train_indices]).board_num]'];
   model = svmtrain(train_lab, train_mat, '-t 0 ');
   model.Label
   test_mat = extract_hog_features([l_ims(xval(fold).test_indices) r_ims(xval(fold).test_indices)]);
   test_lab = [[l_ims([xval(fold).test_indices]).board_num]'; [r_ims([xval(fold).test_indices]).board_num]'];
   [label acc prob] = svmpredict(test_lab, test_mat, model);
   xval_errors(fold) = (sum(label~=test_lab)./length(test_lab));
end

%% LINEAR SVM 2-CLASS

xval_errors_board = zeros(N_folds,tot_board_nums);
pos_weights = {};
for board_num = 1:tot_board_nums
    for fold = 1:N_folds
       training_images = [l_ims(xval(fold).train_indices) r_ims(xval(fold).train_indices)];
       [train_mat sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images);
       train_lab = [[l_ims([xval(fold).train_indices]).board_num]'; [r_ims([xval(fold).train_indices]).board_num]'];
       train_lab(train_lab~=board_num) = -1;
       train_lab(train_lab==board_num) = 1;
       model = svmtrain(train_lab, train_mat, '-t 0 ');
       test_mat = extract_hog_features([l_ims(xval(fold).test_indices) r_ims(xval(fold).test_indices)]);
       test_lab = [[l_ims([xval(fold).test_indices]).board_num]'; [r_ims([xval(fold).test_indices]).board_num]'];
       test_lab(test_lab~=board_num) = -1;
       test_lab(test_lab==board_num) = 1;
       [label acc prob] = svmpredict(test_lab, test_mat, model);
       xval_errors_board(fold, board_num) = (sum(label~=test_lab)./length(test_lab));
       
    end
    weights = model.SVs' * model.sv_coef;
    b = -model.rho;
    if model.Label(1) == -1
        weights = -weights;
        b = -b;
    end
    % visualise svm weights on hog
    % pick a random row of the training matrix to render the hog of
    random_train_index = randi(length(training_images));
    size_hog = size(sample_hog);
    filename = sprintf('svm-wts-number-%d', board_num);
    draw_weights_on_hog_v2(training_images(random_train_index).img, ...
        train_mat(random_train_index,:), weights, ind_rowvec_to_hog, ...
        num_orient, size_hog, filename);
%     draw_weights_on_hog(sample_hog, weights, 0, sprintf('pos_wts_board_number_%d', board_num));
%     draw_weights_on_hog(sample_hog, weights, 1, sprintf('neg_wts_board_number_%d', board_num));
%     % For the nth fold?? display the positive weights
%     pos_weights{board_num} = w;
end

% pos_w = {};
% for i =1:length(pos_weights)
%     temp = pos_weights{i};
%     pos_w{i} = temp(temp>0);
% end
% I = cellfun(@(A) max(size(A)), pos_w );
% w_IM = zeros(tot_board_nums, max(I));
% for i = 1:tot_board_nums
%     w_IM(i,1:I(i)) = pos_w{i}';
% end
% imagesc(w_IM)