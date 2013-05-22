#!/usr/bin/perl

my $board_num = 1;
my $fold = 1;
`rm stdout.txt`;
`rm stderr.txt`;
for ($board_num=4; $board_num<10; $board_num++)
{
  for($fold=1; $fold<4; $fold++)
  {
    print "Board number $board_num and Fold $fold is being processed...";
      `rm positives.dat`;
      `rm negatives.dat`;
      `rm samples.vec`;
      `cp train_negatives/neg_${board_num}\_${fold}.dat negatives.dat`;
      `cp train_positives/pos_${board_num}\_${fold}.dat positives.dat`;
      `/home/varsha/opencv-2.4.4/opencv_cmake_dir/bin/opencv_createsamples -info positives.dat -vec sample.vec -w 20 -h 10`;
      my $num_pos = `cat positives.dat|wc -l`;
      $num_pos =~ s/^\s+//;
      $num_pos =~ s/\s+$//;
      my $num_neg = `cat negatives.dat|wc -l`;
      $num_neg =~ s/^\s+//;
      $num_neg =~ s/\s+$//;
      `/home/varsha/opencv-2.4.4/opencv_cmake_dir/bin/opencv_haartraining -data haarcascade_${board_num}\_${fold} -vec sample.vec -bg negatives.dat -nstages 10 -nsplits 2 -minhitrate 0.999 -maxfalsealarm 0.5 -npos $num_pos -nneg $num_neg -w 20 -h 10 -nonsym -mem 1024 -mode ALL 1>>stdout.txt 2>>stderr.txt`;
  }
}
