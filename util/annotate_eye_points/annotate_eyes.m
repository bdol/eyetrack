%% PREPARE DATA FOR ANNOTATION
% download raw data
% convert raw data to pngs
% input_dir = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/raw_data/';
% output_dir = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/png_data/';
% convert_raw_data_format(input_dir,output_dir, 'png');
% generate a list of the png images
% generate_file_list(output_dir, 'png', 'image_file_list.txt');
% run face tracker and get the automatically annotated points for the
% images
% ./face_tracker -ilist image_file_list.txt -f face_tracker_points.txt

% 1-788 redo to mark the entire eye and not only sclera
%%
input_file = 'face_tracker_points.txt';
output_filename = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/util/annotate_eye_points/new_face_tracker_points_corrected.txt';
output_file = fopen(output_filename,'a');
half_w = 200;
half_h = 50;

if(output_file~=-1)
    data = importdata(input_file);
    for i = 847:length(data.data)
        fprintf(sprintf('Image %d of %d\n',i,100));
        im = imread(data.rowheaders{i});
        points = data.data(i,:);
        eye_points = reshape(points,2,length(points)/2);
        eye_points(1,:) = size(im,2) - eye_points(1,:);
        centroid = [mean(eye_points(1,:)) mean(eye_points(2,:))];

        center_x = round(centroid(1)-half_w:centroid(1)+half_w);
        center_y = round(centroid(2)-half_h:centroid(2)+half_h);
        if(~(any(center_x<1) | any(center_y<1)))
            cropped = im(center_y, center_x,:); 
            imshow(cropped); hold on;
    %         plot((centroid(1) - eye_points(1,:) + half_w), (centroid(2) - eye_points(2,:) + half_h), 'r.');
            new_x = zeros(6,1);
            new_y = zeros(6,1);
            for j = 1:12
                [x y] = ginput(1);
                plot(x,y,'y.');
                new_x(j) = x;
                new_y(j) = y;
            end

            uncropped_new_x = [centroid(1) + new_x(:) - half_w]';
            uncropped_new_y = [centroid(2) + new_y(:) - half_h]';
        else
            imshow(im); hold on; 
            zoom on; % use mouse button to zoom in or out
            % Press Enter to get out of the zoom mode.

            % CurrentCharacter contains the most recent key which was pressed after opening
            % the figure, wait for the most recent key to become the return/enter key
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
        points_file_format = round(reshape([uncropped_new_x' uncropped_new_y']', 1, 2*length(uncropped_new_x)));
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

%% TESTING OUT ANNOTATIONS
data = importdata(output_filename);
basepath = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/png_data';
for i = 1:800%size(data.data,1)
    i
    subject_num =  regexp(data.rowheaders{i}, '.*(\d\d\d\d\.[1-9]\.E).*','tokens');
    image_num = regexp(data.rowheaders{i}, '.*(IM_\d_\d).*', 'tokens');
    path = sprintf('%s/%s/%s.png',basepath, subject_num{1}{1}, image_num{1}{1});
    im = imread(path);
    points = data.data(i,:);
    eye_points = reshape(points,2,length(points)/2);

%     centroid = [mean(eye_points(1,:)) mean(eye_points(2,:))];
% 
%     center_x = round(centroid(1)-half_w:centroid(1)+half_w);
%     center_y = round(centroid(2)-half_h:centroid(2)+half_h);
%     cropped = im(center_y, center_x); 
%     imshow(cropped); hold on;
%     plot((centroid(1) - eye_points(1,:) + half_h), (centroid(2) - eye_points(2,:) + half_w), 'r*');
    imshow(im);
    hold on;
    plot(eye_points(1,:), eye_points(2,:), 'b*');
    
    pause;
end