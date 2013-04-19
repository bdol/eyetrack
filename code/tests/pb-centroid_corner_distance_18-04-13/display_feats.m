function run_test

addpath(genpath('../../third_party_libs'));
subj_names = {'images/1225.2.E/', 'images/1206.2.E/', 'images/1219.2.E/', ...
    'images/1203.2.E/', 'images/1201.2.E/'};
% subj_names = {'images/1201.2.E/'};
counter = 1;
tot_board_nums = 9;
figure;

for subj_num = 1:length(subj_names)
    [l_ims r_ims] = load_eye_images(subj_names{subj_num});

    for i = 1:length(l_ims)
        % dont bother with duplicating efforts for now
        if(l_ims(i).frame_num==2)
           PB_feat = extract_pb_features(l_ims(i).img);

           % Display pb feat
           subplot(length(subj_names), tot_board_nums, counter )
           imshow(PB_feat.pb); hold on; plot(PB_feat.centroid_y, PB_feat.centroid_x, 'r*', 'MarkerSize',14);
           rectangle('Position',[PB_feat.top_left_corner(2), PB_feat.top_left_corner(1), ...
                    PB_feat.bottom_right_corner(2) - PB_feat.top_left_corner(2), PB_feat.bottom_right_corner(1) - PB_feat.top_left_corner(1)]...
                    ,'LineWidth',1,'EdgeColor', 'r', 'LineStyle','--');
           line([PB_feat.centroid_y PB_feat.top_left_corner(2)], [PB_feat.centroid_x PB_feat.top_left_corner(1)], 'LineWidth',2, 'Color','y');
           line([PB_feat.centroid_y PB_feat.bottom_right_corner(2)], [PB_feat.centroid_x PB_feat.bottom_right_corner(1)], 'LineWidth',2, 'Color','g');
           hold off;
           
           counter = counter + 1;
        end
    end
end
