function display_annotations(annotation_filename, image_root)

data = importdata(annotation_filename);
% image_root = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/png_data';
N_images = size(data.data,1);
for i = 1:N_images
    fprintf(sprintf('Image %d of %d\n',i,N_images));
    subject_num =  regexp(data.rowheaders{i}, '.*(\d\d\d\d\.[1-9]\.E).*','tokens');
    image_num = regexp(data.rowheaders{i}, '.*(IM_\d_\d).*', 'tokens');
    path = sprintf('%s/%s/%s.png',image_root, subject_num{1}{1}, image_num{1}{1});
    im = imread(path);
    points = data.data(i,:);
    eye_points = reshape(points,2,length(points)/2);

    imshow(im);
    hold on;
    plot(eye_points(1,:), eye_points(2,:), 'b*');
    
    pause;
end