function [l_pts_corrected r_pts_corrected] = keyboard_annotate(im, l_pts, r_pts, w, h)
% Takes an image IM, and left and right points returned by FaceTracker
% (l_pts, r_pts, resp.). Use keyboard controls to correct the points. Save
% the changes to data f.
%
% CONTROLS:
%   l: Edit the left eye image points
%   r: Edit the right eye image points
%   1-6: Select the point to edit
%   Arrow keys: manipulate point
%   Backspace key: reset all changes
%   Esc key: skip this image
%   Enter key: save all changes
%
% The image you are currently editing will have GREEN points.
%
% Brian Dolhansky 2013. bdol@seas.upenn.edu

close all;

save_data = 0;
colors = [0 255 0; 255 0 0];

[eye_l cx_l cy_l] = crop_eye(im, l_pts, w, h);
eye_l = mat2gray(eye_l);
[eye_r cx_r cy_r] = crop_eye(im, r_pts, w, h);
eye_r = mat2gray(eye_r);

% Actual eye points
current_eye = 'R';
r_pts_cropped = bsxfun(@minus, r_pts, [cx_r cy_r]);
r_cdata = repmat(colors(1, :), size(r_pts_cropped, 1), 1);
l_pts_cropped = bsxfun(@minus, l_pts, [cx_l cy_l]);
l_cdata = repmat(colors(2, :), size(l_pts_cropped, 1), 1);
% Circle around currently selected point
current_pt_r = 1;
r_selected = r_pts_cropped(current_pt_r, :);
current_pt_l = 1;
l_selected = l_pts_cropped(current_pt_l, :);

% Plot the initial data
% Left eye
fig_l = figure;

imshow(eye_l); hold on;
set(fig_l, 'OuterPosition', [200 500 700 500]);
set(gca, 'Position', [0 0 1 1]);
h_l = scatter(l_pts_cropped(:, 1), l_pts_cropped(:, 2), 'CData', l_cdata, 'Marker', 'x');
title('Left');
set(h_l, 'XDataSource', 'l_pts_cropped(:, 1)');
set(h_l, 'YDataSource', 'l_pts_cropped(:, 2)');
set(h_l, 'CDataSource', 'l_cdata');
h_l_sel = plot(l_selected(1, 1), l_selected(1, 2), 'Color', 'w', 'Marker', 'o', 'MarkerSize', 20);
set(h_l_sel, 'XDataSource', 'l_selected(1)');
set(h_l_sel, 'YDataSource', 'l_selected(2)');
hold off;
% Right eye
fig_r = figure;
imshow(eye_r); hold on;
set(fig_r, 'OuterPosition', [600 500 700 500]);
set(gca, 'Position', [0 0 1 1]);
h_r = scatter(r_pts_cropped(:, 1), r_pts_cropped(:, 2), 'CData', r_cdata, 'Marker', 'x');
title('Right');
set(h_r, 'XDataSource', 'r_pts_cropped(:, 1)');
set(h_r, 'YDataSource', 'r_pts_cropped(:, 2)');
set(h_r, 'CDataSource', 'r_cdata');
h_r_sel = plot(r_selected(1, 1), r_selected(1, 2), 'Color', 'w', 'Marker', 'o', 'MarkerSize', 20);
set(h_r_sel, 'XDataSource', 'r_selected(1)');
set(h_r_sel, 'YDataSource', 'r_selected(2)');
hold off;


cc = 0;
while cc~=27 && cc~=13
    k = waitforbuttonpress;
    cc = get(gcf, 'CurrentCharacter');
    
    if k==1 && cc>=49 && cc<=54 % Pressed a number
        if strcmp(current_eye, 'R')
            current_pt_r = cc-48;
            r_selected = r_pts_cropped(current_pt_r, :);
        else
            current_pt_l = cc-48;
            l_selected = l_pts_cropped(current_pt_l, :);
        end
    elseif cc==32 % Spacebar pressed
        [x y] = ginput(1);
        if strcmp(current_eye, 'R')
            r_pts_cropped(current_pt_r, :) = [x y];
            r_selected = [x y];
        else
            l_pts_cropped(current_pt_l, :) = [x y];
            l_selected = [x y];
        end
    elseif cc>=28 && cc<=31 % Pressed an arrow key
        if strcmp(current_eye, 'R')
            if cc==28 % Left arrow
                r_pts_cropped(current_pt_r, 1) = r_pts_cropped(current_pt_r, 1)-1;
            elseif cc==29 % Right arrow
                r_pts_cropped(current_pt_r, 1) = r_pts_cropped(current_pt_r, 1)+1;
            elseif cc==30 % Up arrow
                r_pts_cropped(current_pt_r, 2) = r_pts_cropped(current_pt_r, 2)-1;
            elseif cc==31 % Down arrow
                r_pts_cropped(current_pt_r, 2) = r_pts_cropped(current_pt_r, 2)+1;
            end
            r_selected = r_pts_cropped(current_pt_r, :); 
        else
            if cc==28 % Left arrow
                l_pts_cropped(current_pt_l, 1) = l_pts_cropped(current_pt_l, 1)-1;
            elseif cc==29 % Right arrow
                l_pts_cropped(current_pt_l, 1) = l_pts_cropped(current_pt_l, 1)+1;
            elseif cc==30 % Up arrow
                l_pts_cropped(current_pt_l, 2) = l_pts_cropped(current_pt_l, 2)-1;
            elseif cc==31 % Down arrow
                l_pts_cropped(current_pt_l, 2) = l_pts_cropped(current_pt_l, 2)+1;
            end
            l_selected = l_pts_cropped(current_pt_l, :); 
        end
    elseif cc==108 % 'l' key pressed
        current_eye = 'L';
        r_cdata = repmat(colors(2, :), size(r_pts_cropped, 1), 1);
        l_cdata = repmat(colors(1, :), size(l_pts_cropped, 1), 1);
        figure(fig_l);
        
    elseif cc==114 % 'r' key pressed
        current_eye = 'R';
        r_cdata = repmat(colors(1, :), size(r_pts_cropped, 1), 1);
        l_cdata = repmat(colors(2, :), size(l_pts_cropped, 1), 1);
        figure(fig_r);
      
    elseif cc==13 % Enter key pressed
        save_data = 1;
    end
    refreshdata(h_r, 'caller');
    refreshdata(h_r_sel, 'caller');
    refreshdata(h_l, 'caller');
    refreshdata(h_l_sel, 'caller');    
end

l_pts_corrected = [];
r_pts_corrected = [];
if save_data
    l_pts_corrected = bsxfun(@plus, l_pts_cropped, [cx_l cy_l]);
    r_pts_corrected = bsxfun(@plus, r_pts_cropped, [cx_r cy_r]);
end

close all;


end
