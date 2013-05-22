#!/usr/bin/perl

my $board_num = 1;
`rm stdout.txt`;
`rm stderr.txt`;
for ($board_num=1; $board_num<10; $board_num++)
{
  print "Board number $board_num and left eye images are being trained...";
  `rm positives.dat`;
  `rm negatives.dat`;
  `rm samples.vec`;
  `cp train_left_negatives/neg_${board_num}.dat negatives.dat`;
  `cp train_left_positives/pos_${board_num}.dat positives.dat`;
  `/home/varsha/opencv-2.4.4/opencv_cmake_dir/bin/opencv_createsamples -info positives.dat -vec sample.vec -w 20 -h 10`;
  my $num_pos = `cat positives.dat|wc -l`;
  $num_pos =~ s/^\s+//;
  $num_pos =~ s/\s+$//;
  my $num_neg = `cat negatives.dat|wc -l`;
  $num_neg =~ s/^\s+//;
  $num_neg =~ s/\s+$//;
  `/home/varsha/opencv-2.4.4/opencv_cmake_dir/bin/opencv_haartraining -data haarcascade_left_${board_num} -vec sample.vec -bg negatives.dat -nstages 10 -nsplits 2 -minhitrate 0.999 -maxfalsealarm 0.5 -npos $num_pos -nneg $num_neg -w 20 -h 10 -nonsym -mem 1024 -mode ALL 1>>stdout.txt 2>>stderr.txt`;

  print "Board number $board_num and right eye images are being trained...";
  `rm positives.dat`;
  `rm negatives.dat`;
  `rm samples.vec`;
  `cp train_right_negatives/neg_${board_num}.dat negatives.dat`;
  `cp train_right_positives/pos_${board_num}.dat positives.dat`;
  `/home/varsha/opencv-2.4.4/opencv_cmake_dir/bin/opencv_createsamples -info positives.dat -vec sample.vec -w 20 -h 10`;
  my $num_pos = `cat positives.dat|wc -l`;
  $num_pos =~ s/^\s+//;
  $num_pos =~ s/\s+$//;
  my $num_neg = `cat negatives.dat|wc -l`;
  $num_neg =~ s/^\s+//;
  $num_neg =~ s/\s+$//;
  `/home/varsha/opencv-2.4.4/opencv_cmake_dir/bin/opencv_haartraining -data haarcascade_right_${board_num} -vec sample.vec -bg negatives.dat -nstages 10 -nsplits 2 -minhitrate 0.999 -maxfalsealarm 0.5 -npos $num_pos -nneg $num_neg -w 20 -h 10 -nonsym -mem 1024 -mode ALL 1>>stdout.txt 2>>stderr.txt`;
}
