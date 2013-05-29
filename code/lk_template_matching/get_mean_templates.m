function [E_left E_right] = get_mean_templates(rootPath)

[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_intensity_clean(rootPath);

E_left = zeros(50, 100, 9);;
E_right = zeros(50, 100, 9);;

total_left = zeros(50, 100, 9);
total_right = zeros(50, 100, 9);
for i=1:size(X_left, 1)
    left = reshape(X_left(i, :), 50, 100);
    right = reshape(X_right(i, :), 50, 100);
    total_left(:, :, Y_left(i, 1)) = total_left(:, :, Y_left(i, 1))+left;
    total_right(:, :, Y_right(i, 1)) = total_right(:, :, Y_right(i, 1))+right;
end

for k=1:9
   ysum_left = sum(Y_left(:, 1)==k);
   ysum_right = sum(Y_right(:, 1)==k);
   E_left(:, :, k) = (total_left(:, :, k)/ysum_left).^2;
   E_left(:, :, k) = E_left(:, :, k)/max(max(E_left(:, :, k)));
   E_right(:, :, k) = (total_right(:, :, k)/ysum_right).^2;
   E_right(:, :, k) = E_right(:, :, k)/max(max(E_right(:, :, k)));
end

end