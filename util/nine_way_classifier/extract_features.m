function extract_features(image, feat_len)

% PB Feature
pb_thresh = 0.5;
[pb ~] = pbCGTG(image);
[n xout] = hist(pb(:));
highprob_ind = find(pb >  min(xout(xout>pb_thresh)));
highprob_pb = zeros(size(pb));
highprob_pb(highprob_ind) = pb(highprob_ind);
[x y] = ind2sub(size(pb), highprob_ind);
centroid_x = sum(x.*pb(highprob_ind))./sum(pb(highprob_ind));
centroid_y = sum(y.*pb(highprob_ind))./sum(pb(highprob_ind));
imshow(highprob_pb); hold on; plot(centroid_y, centroid_x, 'r*', 'MarkerSize',14); hold off;