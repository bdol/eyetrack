function xval = xval_setup(l_ims, training_subj, N_folds)

xval = struct('train_indices', {}, 'test_indices', {});
N_subjects = length(training_subj);
boxes = round(linspace(1, N_subjects, N_folds+1));
arr = [1:N_folds];
for fold = 1:N_folds-1
    test_subject_numbers = training_subj(boxes(arr==fold):boxes(arr==fold +1)-1);
    train_subject_numbers = setdiff(training_subj, test_subject_numbers);
    xval(fold).train_indices = find(ismember([l_ims(:).subject_index], train_subject_numbers));
    xval(fold).test_indices = find(ismember([l_ims(:).subject_index], test_subject_numbers));
end
fold = fold + 1;
test_subject_numbers = training_subj(boxes(arr==fold):boxes(end));
train_subject_numbers = setdiff(training_subj, test_subject_numbers);
xval(fold).train_indices = find(ismember([l_ims(:).subject_index], train_subject_numbers));
xval(fold).test_indices = find(ismember([l_ims(:).subject_index], test_subject_numbers));
