
#include <FaceTracker/Tracker.h>
#include <opencv/highgui.h>
#include <iostream>
#include <fstream>
#include <sstream>

using namespace std;
using namespace cv;

#define FACE_CROP_WIDTH 300.0

/**
 * We set the face centroid as the tip of the nose. This corresponds the point
 * at position 30
 */
Point determineFaceCentroid(Mat &shape)
{
    int N = shape.rows/2;
    Point p = cv::Point(shape.at<double>(30,0),shape.at<double>(30+N,0));
    return p;
}

/**
 */
Mat getCorrespondenceMatrix(Mat &shape)
{
    int N = shape.rows/2;
    Mat X = Mat_<Vec2d>(N, 1);
    for (int i=0; i<N; i++) {
        double x = shape.at<double>(i, 0);
        double y = shape.at<double>(i+N, 0);
        X.at<Vec2d>(i) = Vec2d(x, y);
    }


    return X;
}

/**
 * Find x which minimizes ||A*x|| subject to ||x||=1
 *
 * @return x as a row vector
 */
Mat minimizeAx(const Mat &A)
{
	// First compute the SVD decomposition of A
	SVD svd(A, SVD::FULL_UV);

	// The eigenvector associated with the lowest eigenvalue is the last row of svd.vt
	int cols = A.size.p[1];
	Mat x = Mat_<double>::zeros(1, cols);
	svd.vt.row(svd.vt.size.p[0]-1).copyTo(x.row(0));

  return x;
}

/**
 * Fit a homography (ie, perspective transformation) between two
 * sets of points. Each element of X1 is a point which corresponds
 * to the point in the same element of X2.
 *
 * @return a matrix H s.t. p2 ~ H * p1 where p1 and p2 are
 *         corresponding points in X1 and X2 respectively.
 */
Mat fitHomography(const Mat &X1, const Mat &X2)
{
  assert(X1.type() == CV_64FC2);
  assert(X2.type() == CV_64FC2);
  const size_t N = X1.rows;
  assert(N == X2.rows);
  assert(1 == X1.cols);
  assert(1 == X2.cols);

  Mat_<double> M(2*N, 9);
  
	for (int i=0; i<2*N; i+=2) {
		double x = X1.at<Vec2d>(i/2)[0];
		double y = X1.at<Vec2d>(i/2)[1];
		double xp = X2.at<Vec2d>(i/2)[0];
		double yp = X2.at<Vec2d>(i/2)[1];
		M.at<double>(i, 0) = x;
		M.at<double>(i, 1) = y;
		M.at<double>(i, 2) = 1;
		M.at<double>(i, 3) = 0;
		M.at<double>(i, 4) = 0;
		M.at<double>(i, 5) = 0;
		M.at<double>(i, 6) = -x*xp;
		M.at<double>(i, 7) = -y*xp;
		M.at<double>(i, 8) = -xp;
		M.at<double>(i+1, 0) = 0;
		M.at<double>(i+1, 1) = 0;
		M.at<double>(i+1, 2) = 0;
		M.at<double>(i+1, 3) = x;
		M.at<double>(i+1, 4) = y;
		M.at<double>(i+1, 5) = 1;
		M.at<double>(i+1, 6) = -x*yp;
		M.at<double>(i+1, 7) = -y*yp;
		M.at<double>(i+1, 8) = -yp;
	}
  Mat A(9, 1, CV_64FC1);
	A = minimizeAx(M);
	double vMag = A.at<double>(8);
	for (int i=0; i<9; i++) {
		A.at<double>(i) = A.at<double>(i)/vMag;
	}

  return A.reshape(1, 3); // reshapes the 9x1 vector to single channel, 3 rows matrix
}

Mat rectifyImage(const Mat &A, const Mat &im, size_t N)
{
  Mat rectified(N, N, im.type());
	for (int x=0; x<N; x++) {
		for (int y=0; y<N; y++) {
			Mat pr = Mat::zeros(3, 1, CV_64FC1);
			pr.at<double>(0, 0) = double(x)/(double)N;
			pr.at<double>(1, 0) = double(y)/(double)N;
			pr.at<double>(2, 0) = 1.0;
			Mat po = A*pr;
			int xo = floor(po.at<double>(0, 0)/po.at<double>(2, 0));
			int yo = floor(po.at<double>(1, 0)/po.at<double>(2, 0));
			if (yo < im.size.p[0] && yo >= 0 && xo >= 0 && xo < im.size.p[1]) {
				rectified.at<Vec3b>(N-1-y, x) = im.at<Vec3b>(yo, xo);
			} else {
				rectified.at<Vec3b>(N-1-y, x) = Vec3b(0, 0);
			}
		}
	}
  return rectified;
}

int main(int argc, const char** argv)
{
    if (argc<3) {
        cout << "Usage: ./face_rectification <image list file> <out dir>" << endl;
        return -1;
    }

    // Get command line arguments
    bool fcheck = false; double scale = 1; int fpd = -1; bool show = true;
    char framesFile[1024]; strcpy(framesFile, argv[1]);
    char outDir[1024]; strcpy(outDir, argv[2]);

    // Set other tracking parameters
    char ftFile[256]; strcpy(ftFile,"../model/face2.tracker");
    char conFile[256]; strcpy(conFile,"../model/face.con");
    char triFile[256]; strcpy(triFile,"../model/face.tri");
    vector<int> wSize1(1); wSize1[0] = 7;
    vector<int> wSize2(3); wSize2[0] = 11; wSize2[1] = 9; wSize2[2] = 7;
    int nIter = 5; double clamp=3,fTol=0.01; 
    FACETRACKER::Tracker model(ftFile);
    cv::Mat tri=FACETRACKER::IO::LoadTri(triFile);
    cv::Mat con=FACETRACKER::IO::LoadCon(conFile);

    // Set up variables to read the image
    ifstream frameFile(argv[1]);
    string line;
    int i=0;
    cv::Mat frame,gray,im; string text; 
    bool failed = true;

    Mat canonicalCorresp;

    while(getline(frameFile, line)) {
        cout << "Processing " << line << endl;

        // Read the image
        cv::Mat image = cv::imread(line, 1);
        IplImage* I = cvCloneImage(&(IplImage)image);
        frame = I;
        if(scale == 1)im = frame; 
        else cv::resize(frame,im,cv::Size(scale*frame.cols,scale*frame.rows));
        cv::flip(im,im,1); cv::cvtColor(im,gray,CV_BGR2GRAY);

        // Track the image
        vector<int> wSize; if(failed)wSize = wSize2; else wSize = wSize1; 
        if(model.Track(gray,wSize,fpd,nIter,clamp,fTol,fcheck) == 0){
            int idx = model._clm.GetViewIdx(); failed = false;
            
            // We assume that the image list file contains the canonical pose first
            if (i==0) {
                canonicalCorresp = getCorrespondenceMatrix(model._shape);
            } else {
                Mat currentCorresp = getCorrespondenceMatrix(model._shape);
                Mat H = fitHomography(canonicalCorresp, currentCorresp);
                Mat rectified = rectifyImage(H, im, 500);
                stringstream s; 
                s << outDir << i << ".png";
                imwrite(s.str(), rectified);
            }

            Point centroid = determineFaceCentroid(model._shape);
            Rect faceRect = Rect(centroid.x-FACE_CROP_WIDTH/2.0, 
                                    centroid.y-FACE_CROP_WIDTH/2.0,
                                    FACE_CROP_WIDTH,
                                    FACE_CROP_WIDTH);
            Mat face = im(faceRect).clone();

            //Draw(im,model._shape,con,tri,model._clm._visi[idx]); 
        }else{
            if(show){cv::Mat R(im,cvRect(0,0,150,50)); R = cv::Scalar(0,0,255);}
            model.FrameReset(); failed = true;
        }



        i++;
    }

    return 0;
}

