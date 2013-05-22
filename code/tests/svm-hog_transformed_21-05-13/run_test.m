%% ADD PATHS
clear
clc
addpath(genpath('../../../../eyetrack/'));
subj_names = {'../../../all_images/cropped_eyes_transformed_new/'};
% subj_names = {'../../../all_images/cropped_eyes_transformed/1027.2.E/'};

%% ORGANISE DATA
tot_board_nums = 9;
N_folds = 4;

[l_ims r_ims] = load_cropped_eye_intensity_linux(subj_names{1});
N = length(l_ims);
subjectwise_split = 1;
frames_per_subject = tot_board_nums * 2;
percent = 85;
xval = xval_setup(N, N_folds, subjectwise_split, frames_per_subject);
[train_ind test_ind] = train_test_setup(N, percent, subjectwise_split, frames_per_subject);

%% one-vs-all linear svm
% TRAINING
c_arr = zeros(N_folds,1); c_arr(1) = 0.01; c_arr(2) = 0.1; c_arr(3) = 1; c_arr(4) = 10;
model = cell(tot_board_nums,1);
accuracy = cell(tot_board_nums,1);
chosen_c = ones(tot_board_nums,1);
for board_num = 1:tot_board_nums
    fprintf('Training model for board number %d\n',board_num);
    simple_progress_bar(N_folds);
    best_c_acc = 0;
    for fold = 1:N_folds
        training_images = [l_ims(xval(fold).train_indices)];
        [train_mat_left sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images);
        training_images = [r_ims(xval(fold).train_indices)];
        [train_mat_right sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images);
        train_mat = [train_mat_left train_mat_right];
        train_lab = [l_ims([xval(fold).train_indices]).board_num]';
        model_xval = svmtrain(double(train_lab==board_num), train_mat, sprintf('-c %d -t 0 -g 0.2',c_arr(fold)));
        test_mat_left = extract_hog_features(l_ims(xval(fold).test_indices));
        test_mat_right = extract_hog_features(l_ims(xval(fold).test_indices));
        test_mat = [test_mat_left test_mat_right];
        test_lab = [l_ims([xval(fold).test_indices]).board_num]';
        [a,acc,p] = svmpredict(double(test_lab==board_num), test_mat, model_xval);
        % probability of class==board_num
        if(acc(1) > best_c_acc)
            best_c_acc = acc(1);
            chosen_c(board_num,1) = c_arr(fold);
        end
        simple_progress_bar;
    end
    training_images = [l_ims(train_ind)];
    [train_mat_left sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images);
    training_images = [r_ims(train_ind)];
    [train_mat_right sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images);
    train_mat = [train_mat_left train_mat_right];
    train_lab = [l_ims(train_ind).board_num]';
    model{board_num} = svmtrain(double(train_lab==board_num), train_mat, sprintf('-c %d -t 0 -g 0.2 -b 1',chosen_c(board_num,1)));
end
%% Testing accuracy
test_mat_left = extract_hog_features(l_ims(test_ind));
test_mat_right = extract_hog_features(r_ims(test_ind));
test_mat = [test_mat_left test_mat_right];
test_lab = [l_ims(test_ind).board_num]';
prob = zeros(length(test_lab), tot_board_nums);
for board_num = 1:tot_board_nums
    [a,acc,p] = svmpredict(double(test_lab==board_num), test_mat, model{board_num},'-b 1');
    prob(:,board_num) = p(:, model{board_num}.Label==1);
end
[temp pred] = max(prob,[],2);
acc = sum(pred == test_lab) ./ numel(test_lab);
C = confusionmat(test_lab, pred);
imagesc(C);

% %% one-vs-all RBF svm
% % TRAINING
% c_arr = zeros(N_folds,1); c_arr(1) = 0.001; c_arr(2) = 0.01; c_arr(3) = 0.1; c_arr(4) = 1;
% model = cell(tot_board_nums,1);
% accuracy = cell(tot_board_nums,1);
% chosen_c = ones(tot_board_nums,1);
% for board_num = 1:tot_board_nums
%     fprintf('Training model for board number %d\n',board_num);
%     simple_progress_bar(N_folds);
%     best_c_acc = 0;
%     for fold = 1:N_folds
%         training_images = [l_ims(xval(fold).train_indices) r_ims(xval(fold).train_indices)];
%         [train_mat sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images);
%         train_lab = [[l_ims([xval(fold).train_indices]).board_num]'; [r_ims([xval(fold).train_indices]).board_num]'];
%         model_xval = svmtrain(double(train_lab==board_num), train_mat, sprintf('-c %d -t 2 -g 0.2',c_arr(fold)));
%         test_mat = extract_hog_features([l_ims(xval(fold).test_indices) r_ims(xval(fold).test_indices)]);
%         test_lab = [[l_ims([xval(fold).test_indices]).board_num]'; [r_ims([xval(fold).test_indices]).board_num]'];
%         [a,acc,p] = svmpredict(double(test_lab==board_num), test_mat, model_xval);
%         % probability of class==board_num
%         if(acc(1) > best_c_acc)
%             best_c_acc = acc(1);
%             chosen_c(board_num,1) = c_arr(fold);
%         end
%         simple_progress_bar;
%     end
%     training_images = [l_ims(train_ind) r_ims(train_ind)];
%     [train_mat sample_hog ind_rowvec_to_hog num_orient] = extract_hog_features(training_images);
%     train_lab = [[l_ims(train_ind).board_num]'; [r_ims(train_ind).board_num]'];
%     model{board_num} = svmtrain(double(train_lab==board_num), train_mat, sprintf('-c %d -t 0 -g 0.2 -b 1',chosen_c(board_num,1)));
% end
% %% Testing accuracy
% test_mat = extract_hog_features([l_ims(test_ind) r_ims(test_ind)]);
% test_lab = [[l_ims(test_ind).board_num]'; [r_ims(test_ind).board_num]'];
% prob = zeros(length(test_lab), tot_board_nums);
% for board_num = 1:tot_board_nums
%     [a,acc,p] = svmpredict(double(test_lab==board_num), test_mat, model{board_num},'-b 1');
%     prob(:,board_num) = p(:, model{board_num}.Label==1);
% end
% [temp pred] = max(prob,[],2);
% acc = sum(pred == test_lab) ./ numel(test_lab);
% C = confusionmat(test_lab, pred);
% imagesc(C);
% 
