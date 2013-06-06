%% ADD PATHS
% clear
% clc
% addpath kernels/
% addpath libsvm/
% addpath(genpath('../../../third_party_libs/libsvm/'));
% % path to images
% subj_names = {'../../../all_images/cropped_eyes_corrected/'};

%% ORGANISE DATA
N_models = 3;
N_folds = 4;

[l_ims r_ims] = load_lrc_cropped_eyes(subj_names{1});
subject_numbers = unique([l_ims(:).subject_index]);
N_subjects = length(subject_numbers);
percent = 85;

% % split into training and testing sets
% N_train=N_subjects;
% training_subj = subject_numbers(randperm(N_subjects));
% testing_subj = training_subj(N_train+1:end);
% training_subj(N_train+1:end) = [];
% set up xval
xval = xval_setup(l_ims, subject_numbers(randperm(N_subjects)), N_folds);

%% Images to Matrix
a = arrayfun(@(x) x.img(:), l_ims, 'UniformOutput',false);
l_ims_mat = cell2mat(a);
l_ims_mat = l_ims_mat';
a = arrayfun(@(x) x.img(:), r_ims, 'UniformOutput',false);
r_ims_mat = cell2mat(a);
r_ims_mat = r_ims_mat';
ims_mat = [l_ims_mat r_ims_mat];

%% TRAIN KERNELISED SVMS

k_linear = @(x, x2)kernel_poly(x, x2, 1);
k_quadratic = @(x, x2)kernel_poly(x, x2, 2);
k_cubic = @(x, x2)kernel_poly(x, x2, 3);
models = {};
models{1} = k_linear;   models{2} = k_quadratic;
models{3} = k_cubic;    

model_xval_acc = zeros(N_models, N_folds);
model_xval = cell(N_models, N_folds);

for model_index = 1:N_models
    fprintf(sprintf('Running xval for model %d\n',model_index));
    for fold = 1:N_folds
        fold_train_ind = xval(fold).train_indices;
        fold_test_ind = xval(fold).test_indices;
        X_train = ims_mat(fold_train_ind,:);
        Y_train = [l_ims(fold_train_ind).label];    Y_train = Y_train(:);
        X_test = ims_mat(fold_test_ind,:);
        Y_test = [l_ims(fold_test_ind).label];    Y_test = Y_test(:);
        [test_error info] = kernelized_svm(X_train, Y_train, X_test, ...
            Y_test, models{model_index});

        model_xval_acc(model_index,fold) = 1-test_error;
        model_xval{model_index,fold} = info;
    end
end