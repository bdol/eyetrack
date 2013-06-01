1. Download raw data
2. Convert raw data to pngs
    code/data_processing/
    input_dir = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/raw_data/';
    output_dir = '/fiddlestix/Users/varsha/Documents/ResearchEyetrackCode/eyetrack/all_images/png_data/';
    convert_raw_data_format(input_dir,output_dir, 'png');
3. Generate a list of the png images
    code/data_processing/
    generate_file_list(output_dir, 'png', 'image_file_list.txt');
4. Run face tracker and get the automatically annotated points for the
images
    compile util/face_tracker
    edit makefile to compile src/exe/face_tracker_manual_annotate.cc
    cd bin
    ./face_tracker -ilist image_file_list.txt -f face_tracker_points.txt
    where image_file_list.txt is the file generated from step 3.
5. Run annotation tool
    face_tracker_points_filename = '../face_tracker/bin/face_tracker_points.txt';
    output_filename = 'test.txt';
    enable_zoom = true;
    % if enable_zoom = true, the whole image is displayed and you can zoom in to 
    % the appropriate location.
    % use this for images where face tracker's points are completely wrong.
    % if enable_zoom = false, a cropped image around the centroid is displayed.
    % face tracker pts may not always be correct...so the cropped image may not always 
    % be around the eyes
    annotate_eyes(face_tracker_points_filename, output_filename,enable_zoom)