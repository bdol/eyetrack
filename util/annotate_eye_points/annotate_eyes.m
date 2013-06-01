function annotate_eyes(input_file, output_filename, always_zoom_in)

% input_file = 'face_tracker_points.txt';
% output_filename = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/util/annotate_eye_points/new_face_tracker_points_corrected.txt';
% always_zoom_in = false;
output_file = fopen(output_filename,'a');
half_w = 200;
half_h = 50;

if(output_file~=-1)
    data = importdata(input_file);
    N_images = size(data.data,1);
    for i = 2:N_images
        fprintf(sprintf('Image %d of %d\n',i,N_images));
        im = imread(data.rowheaders{i});
        points = data.data(i,:);
        eye_points = reshape(points,2,length(points)/2);
        eye_points(1,:) = size(im,2) - eye_points(1,:);
        centroid = [mean(eye_points(1,:)) mean(eye_points(2,:))];

        center_x = round(centroid(1)-half_w:centroid(1)+half_w);
        center_y = round(centroid(2)-half_h:centroid(2)+half_h);
        % in case the centroid is too far off in the corners of the image,
        % just display the whole image and allow zooming in
        if((~(any(center_x<1) | any(center_y<1))) & (~always_zoom_in))
            cropped = im(center_y, center_x,:); 
            imshow(cropped); hold on;
            % plot points from face tracker -- personally, I think it tends
            % to distract during labeling
%             plot((centroid(1) - eye_points(1,:) + half_w), (centroid(2) - eye_points(2,:) + half_h), 'r.');
            new_x = zeros(6,1);
            new_y = zeros(6,1);
            for j = 1:12
                [x y] = ginput(1);
                plot(x,y,'y.');
                new_x(j) = x;
                new_y(j) = y;
            end

            uncropped_new_x = [centroid(1) + new_x(:) - half_w]';
            uncropped_new_x = uncropped_new_x(:);
            uncropped_new_y = [centroid(2) + new_y(:) - half_h]';
            uncropped_new_y = uncropped_new_y(:);
        else
            imshow(im); hold on; 
            zoom on; 
            % Press Enter to get out of the zoom mode.
            waitfor(gcf,'CurrentCharacter',13)

            zoom reset
            zoom off
           new_x = zeros(6,1);
           new_y = zeros(6,1);
           for j = 1:12
               [x y] = ginput(1);
               plot(x,y,'y.');
               new_x(j) = x;
               new_y(j) = y;
           end
           uncropped_new_x = new_x(:);
           uncropped_new_y = new_y(:);
        end
%         figure(10); 
%         imshow(im);
%         hold on;
%         plot(uncropped_new_x(1:6), uncropped_new_y(1:6), 'b*');
    
        % reshape to x y x y format
        points_file_format = round(reshape([uncropped_new_x uncropped_new_y]', 1, 2*length(uncropped_new_x)));
        fprintf(output_file,'%s',data.rowheaders{i});
        for j = 1:length(points_file_format)
            fprintf(output_file,' %d',points_file_format(j));
        end
        fprintf(output_file,'\n');
    end
    fclose(output_file);
else
    fprintf('output file could not be opened to write!\n');
end