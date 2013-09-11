//
//  TableObjectDetector.cpp
//  TableTop
//
//  Created by Brian Dolhansky on 5/9/13.
//  Copyright (c) 2013 Brian Dolhansky. All rights reserved.
//

#include <table_view_lib/TableObjectDetector.h>
#include <table_view_lib/Cluster.h>
#include <stack>

TableObjectDetector::TableObjectDetector() {
    
}

Mat TableObjectDetector::getClosestPoints(Mat depthWorld, double depthLimit) {
    Mat ltLimit = depthWorld < depthLimit;
    Mat gtZero = depthWorld > 0.0;
    Mat depthToConsider;
    bitwise_and(ltLimit, gtZero, depthToConsider);
    int Nconsider = sum(depthToConsider)[2]/255;
        
    int vind = 0;
    Mat P(Nconsider, 3, CV_64FC1);
    for (int x=0; x<depthWorld.cols; x++) {
        for (int y=0; y<depthWorld.rows; y++) {
            double z = depthWorld.at<Vec3d>(y, x)[2];
            if (z > 0.0 && z < depthLimit) {
                P.at<double>(vind, 0) = depthWorld.at<Vec3d>(y, x)[0];
                P.at<double>(vind, 1) = depthWorld.at<Vec3d>(y, x)[1];
                P.at<double>(vind, 2) = depthWorld.at<Vec3d>(y, x)[2];
                
                vind++;
            }
        }
    }
    
    return P;
}


/**
 * This function generates a matrix of Z coordinates of a plane given a
 * vector of X and Y positions and a normal vector.
 */
Mat TableObjectDetector::getPlanePoints(cv::Mat normal, double rho, cv::Mat X, cv::Mat Y) {
    int N = X.rows;
    Mat Z(N, 1, CV_64F);
    double nx = normal.at<double>(0);
    double ny = normal.at<double>(1);
    double nz = normal.at<double>(2);
    
    for (int i=0; i<N; i++) {
        double x = X.at<double>(i);
        double y = Y.at<double>(i);
        Z.at<double>(i) = (rho-nx*x-ny*y)/nz;
    }
    
    return Z;
}

/**
 * Returns an Nx1 matrix of distances to a plane of an Nx3 matrix of points.
 */
Mat TableObjectDetector::pointPlaneDist(Mat depthWorld, Mat plane) {
    double thresh = 0.015;
    
    double nx = plane.at<double>(0, 0);
    double ny = plane.at<double>(1, 0);
    double nz = plane.at<double>(2, 0);
    double x0 = plane.at<double>(0, 1);
    double y0 = plane.at<double>(1, 1);
    double z0 = plane.at<double>(2, 1);

    int c = 0;
    Mat P(depthWorld.rows*depthWorld.cols, 3, CV_64F);
    for (int x=0; x<depthWorld.cols; x++) {
        for (int y=0; y<depthWorld.rows; y++) {
            Vec3d p = depthWorld.at<Vec3d>(y, x);
            double px = p[0];
            double py = p[1];
            double pz = p[2];
            if (pz >0 && pz<=1) {
                double d = abs(nx*(px-x0) +
                        ny*(py-y0) +
                        nz*(pz-z0) )/sqrt(nx*nx+ny*ny+nz*nz);

                if (d>thresh) {
                    P.at<double>(c, 0) = px;
                    P.at<double>(c, 1) = py;
                    P.at<double>(c, 2) = pz;

                    c++;
                }
            }
        }
    }
    
    if (c==0) {
        return Mat(0, 0, CV_64F);
    }
    
    return P.rowRange(0, c-1);
}

Mat TableObjectDetector::findObjects(Mat depthWorld, Mat plane) {
    return pointPlaneDist(depthWorld, plane);
}

/**
 * Fits a plane to a 3D point cloud of data. The returned matrix is in the following format:
 * First column: plane normal
 * Next 4 columns: 4 corners of the plane that contains all the data
 */
Mat TableObjectDetector::fitPlane(const Mat depthWorld) {
    Mat P = getClosestPoints(depthWorld, 1.0);
    Mat Pmean(1, 3, CV_64F);
    Pmean.at<double>(0) = mean(P.col(0))[0];
    Pmean.at<double>(1) = mean(P.col(1))[0];
    Pmean.at<double>(2) = mean(P.col(2))[0];
        
    for (int i=0; i<P.rows; i++) {
        P.row(i) = P.row(i)-Pmean;
    }
    Mat PT; transpose(P, PT);
    Mat A = PT*P;
    // Find normal of LSQ plane
    SVD svd(A, SVD::FULL_UV);
    Mat norm; transpose(svd.vt.row(2), norm);
    
    double nx = norm.at<double>(0);
    double ny = norm.at<double>(1);
    double nz = norm.at<double>(2);   
    double rho = (Pmean.at<double>(0)*nx +
                  Pmean.at<double>(1)*ny +
                  Pmean.at<double>(2)*nz);

    // Put the normal in the plane matrix
    Mat plane(3, 5, CV_64F);
    norm.col(0).copyTo(plane.col(0));

    // Generate corners of the plane
    double xmin, ymin, xmax, ymax;
    xmin = -0.5;
    xmax = 0.5;
    ymin = -0.5;
    ymax = 0.1;
    
    plane.at<double>(0, 1) = xmin;
    plane.at<double>(0, 2) = xmax;
    plane.at<double>(0, 3) = xmax;
    plane.at<double>(0, 4) = xmin;
    plane.at<double>(1, 1) = ymin;
    plane.at<double>(1, 2) = ymin;
    plane.at<double>(1, 3) = ymax;
    plane.at<double>(1, 4) = ymax;
    double z1 = (rho-nx*xmin-ny*ymin)/nz;
    double z2 = (rho-nx*xmax-ny*ymin)/nz;
    double z3 = (rho-nx*xmax-ny*ymax)/nz;
    double z4 = (rho-nx*xmin-ny*ymax)/nz;
    plane.at<double>(2, 1) = z1;
    plane.at<double>(2, 2) = z2;
    plane.at<double>(2, 3) = z3;
    plane.at<double>(2, 4) = z4;

    return plane;
}

/**
 * Fit a plane using RANSAC. c/o Varsha Shankar
 */
Mat TableObjectDetector::fitPlaneRANSAC(const Mat depthWorld) {
    Mat P = getClosestPoints(depthWorld, 1.0);
    Mat plane = Mat::zeros(3, 5, CV_64F);
    int N = P.rows;
    int n_iter = 30;
    float thresh = 0.001;
    int n_inliers = 0;
    Mat n_est;

    int current_n_inliers = 0;
    Mat dist;
    for (int i=0; i<n_iter; i++) {
        // Randomly pick 3 points
        Mat randPoints(3, 3, CV_64F);
        for (int j=0; j<3; j++) {
            int r_idx = rand() % N;
            P.row(r_idx).copyTo(randPoints.row(j));
        }

        // Calculate the plane that these points lie on
        Mat normal = (randPoints.row(0)-randPoints.row(1)).cross(randPoints.row(0)-randPoints.row(2));
        normal = normal/cv::norm(normal);

        // Calculate the distance of each point to this plane
        Mat v(P.rows, P.cols, CV_64F);
        for (int j=0; j<N; j++) {
            v.row(j) = P.row(j)-randPoints.row(0);
        }
        transpose(normal, normal);
        dist = cv::abs(v*normal);

        // Calculate inliers
        current_n_inliers = 0;
        for (int j=0; j<N; j++) {
            if (dist.at<double>(j) < thresh) {
                current_n_inliers++;
            }  
        }

        // Update if this is a good fit
        if (current_n_inliers > n_inliers) {
            n_est = normal;
            n_inliers = current_n_inliers;
        }

        cout << "RANSAC step " << i << "/" << n_iter << endl;

    }

    n_est.copyTo(plane.col(0));
    int n_inlier_pts = 0;
    while (n_inlier_pts < 4) {
        int r_idx = rand() % N;
        if (dist.at<double>(r_idx) < thresh) {
            Mat rand_pt;
            P.row(r_idx).copyTo(rand_pt);
            transpose(rand_pt, rand_pt);
            rand_pt.copyTo(plane.col(n_inlier_pts+1));
            n_inlier_pts++;
        }


    }



    return plane;

}

/**
 * Takes a 3d plane and draws its transform on the given image.
 */
void TableObjectDetector::drawTablePlane(Mat img, Mat* plane, KinectCalibParams* calib) {
    Point pt[1][4];

    Mat R = calib->getR();
    Mat Rt; transpose(R, Rt);
    Mat T = calib->getT();
    Mat K = calib->getRGBIntrinsics();

    for (int i=0; i<4; i++) {
        Mat p = plane->col(i+1);
        
        // Apply extrinsics
        Mat prgbw = Rt*p - T;
        // Calculate transform to RGB plane
        Mat prgb_hat = K*prgbw;
        Point prgb((int)(prgb_hat.at<double>(0)/prgb_hat.at<double>(2)),
                      (int)(prgb_hat.at<double>(1)/prgb_hat.at<double>(2)));

        pt[0][i] = prgb;
    }
    
    const Point* ppt[1] = {pt[0]};
    int npt[] = {4};
    fillPoly(img, ppt, npt, 1, Scalar(255, 0, 255), 8);
    
}

void TableObjectDetector::draw3DPointsIn2D(Mat img, const Mat P, KinectCalibParams* calib) {
    Mat Pt; P.copyTo(Pt); transpose(Pt, Pt);
    Mat K = calib->getRGBIntrinsics();
    Mat R; (calib->getR()).copyTo(R); transpose(R, R);
    Mat T = calib->getT();
    // Apply extrinsics
    Pt = R*Pt;
    for (int i=0; i<Pt.cols; i++) {
        Pt.col(i) = Pt.col(i)-T;
    }
    
    Mat Pim = K*Pt;
    for (int i=0; i<Pim.cols; i++) {
        double px = Pim.at<double>(0, i)/Pim.at<double>(2, i);
        double py = Pim.at<double>(1, i)/Pim.at<double>(2, i);
       
        img.at<Vec3b>(py, px) = Vec3b(0, 0, 255);
        
    }

}

void TableObjectDetector::drawObjectPoints(Mat img, const Mat P, const Mat L, KinectCalibParams* calib) {
    Mat Pt; P.copyTo(Pt); transpose(Pt, Pt);
    Mat K = calib->getRGBIntrinsics();
    Mat R; (calib->getR()).copyTo(R); transpose(R, R);
    Mat T = calib->getT();
    // Apply extrinsics
    Pt = R*Pt;
    for (int i=0; i<Pt.cols; i++) {
        Pt.col(i) = Pt.col(i)-T;
    }
    
    Mat Pim = K*Pt;
    for (int i=0; i<Pim.cols; i++) {
        double px = Pim.at<double>(0, i)/Pim.at<double>(2, i);
        double py = Pim.at<double>(1, i)/Pim.at<double>(2, i);
        
        if (L.at<int>(i) < 8) {
            img.at<Vec3b>(py, px) = colors_Vec3b[L.at<int>(i)];
        }
        
    }
}

Mat TableObjectDetector::clusterObjects(Mat P, int K) {
    Mat L;
    int attempts = 5;
    P.convertTo(P, CV_32F);
    kmeans(P, K, L, TermCriteria(CV_TERMCRIT_ITER|CV_TERMCRIT_EPS, 10000, 0.0001), attempts, KMEANS_PP_CENTERS);
    
    return L;
}

/**
 * Run hierarchical k-means with a distance threshold of 0.15 meters
 */
Mat TableObjectDetector::clusterObjectsHierarchical(cv::Mat P) {
    Mat L = Mat::zeros	(P.rows, 1, CV_32S);
    double dthresh = 0.15;
    int currentClusterNum = 0;
    int num_iter = 30;
    std::stack<Cluster*> c_stack;
    
    // Initialize with a single cluster containing all datapoints
    Cluster* C = new Cluster();
    Mat D = Mat(P.rows, 4, CV_64F);
    P.copyTo(D.colRange(0, 3));
    // ID each point so we return them in the same order
    for (int i=0; i<D.rows; i++) {
        D.at<double>(i, 3) = i;
    }
    C->setData(D);
    c_stack.push(C);
        
    
    // Run hierarchical k-means
    for (int t=0; t<num_iter; t++) {        
        if (c_stack.empty()) {
            return L;
        }
        
        Cluster* C = (Cluster*)c_stack.top();
        c_stack.pop();
        Mat D = C->getData();
        // Calculate cluster centroid
        Mat Cmean; reduce(D, Cmean, 0, CV_REDUCE_AVG);
        // Calculate max distance
        double maxDist = 0;
        for (int i=0; i<D.rows; i++) {
            double dx = D.at<double>(i, 0) - Cmean.at<double>(0);
            double dy = D.at<double>(i, 1) - Cmean.at<double>(1);
            double dz = D.at<double>(i, 2) - Cmean.at<double>(2);
            double dist = sqrt(dx*dx + dy*dy + dz*dz);
            
            if (dist > maxDist) {
                maxDist = dist;
            }
        }
        
        // Check to see if this cluster satisfies the conditions
        if (maxDist < dthresh) {
            for (int i=0; i<D.rows; i++) {
                int idx = (int)D.at<double>(i, 3);
                L.at<int>(idx) = currentClusterNum;
            }
            currentClusterNum++;
        } else {

            Mat L_iter;
            int attempts = 5;
            Mat D32 = Mat(D.rows, 3, CV_64F);
            D.colRange(0, 3).copyTo(D32);
            D32.convertTo(D32, CV_32F);
            kmeans(D32, 2, L_iter, TermCriteria(CV_TERMCRIT_ITER|CV_TERMCRIT_EPS, 10000, 0.0001), attempts, KMEANS_PP_CENTERS);
            
            Mat D0 = Mat(0, 3, CV_64F);
            Mat D1 = Mat(0, 3, CV_64F);

            for (int i=0; i<L_iter.rows; i++) {
                if (L_iter.at<int>(i) == 0) {
                    D0.push_back(D.row(i));
                } else {
                    D1.push_back(D.row(i));
                }
            }
            
            Cluster* C0 = new Cluster();
            C0->setData(D0);
            Cluster* C1 = new Cluster();
            C1->setData(D1);
            
            c_stack.push(C0);
            c_stack.push(C1);
        }
        
    }
    
    return L;
}

vector<Box3d*> TableObjectDetector::getHulls(const Mat P, const Mat L, const Mat plane) {
    double K;
    minMaxIdx(L, NULL, &K);
    vector<Box3d*> B;
    Mat Rp = determinePlaneRotation(-plane.col(0));
    // We found a rotation from a horizontal plane to our fitted plane
    // We want a translation from our fitted plane to a horizontal plane
    transpose(Rp, Rp);
    Mat Pt; transpose(P, Pt);
    Mat P_rot = Rp*Pt;
        
    for (int k=0; k<=K; k++) {
        double xmin = 1000; double ymin = 1000; double zmin = 1000;
        double xmax = -1000; double ymax = -1000; double zmax = -1000;        
        
        for (int i=0; i<P_rot.cols; i++) {
            if (L.at<int>(i)==k) {
                double x = P_rot.at<double>(0, i);
                double y = P_rot.at<double>(1, i);
                double z = P_rot.at<double>(2, i);
                if (x < xmin) {
                    xmin = x;
                }
                if (x>xmax) {
                    xmax = x;
                }
                if (y<ymin) {
                    ymin = y;
                }
                if (y>ymax) {
                    ymax = y;
                }
                if (z<zmin) {
                    zmin = z;
                }
                if (z>zmax) {
                    zmax = z;
                }
            }
        }
        
        zmax += 0.015; // Add the threshold so that the hull touches the plane
        
        Mat Bp(3, 8, CV_64F);
        Bp.at<double>(0, 0) = xmin; Bp.at<double>(1, 0) = ymin; Bp.at<double>(2, 0) = zmin;
        Bp.at<double>(0, 1) = xmax; Bp.at<double>(1, 1) = ymin; Bp.at<double>(2, 1) = zmin;
        Bp.at<double>(0, 2) = xmax; Bp.at<double>(1, 2) = ymax; Bp.at<double>(2, 2) = zmin;
        Bp.at<double>(0, 3) = xmin; Bp.at<double>(1, 3) = ymax; Bp.at<double>(2, 3) = zmin;
        Bp.at<double>(0, 4) = xmin; Bp.at<double>(1, 4) = ymin; Bp.at<double>(2, 4) = zmax;
        Bp.at<double>(0, 5) = xmax; Bp.at<double>(1, 5) = ymin; Bp.at<double>(2, 5) = zmax;
        Bp.at<double>(0, 6) = xmax; Bp.at<double>(1, 6) = ymax; Bp.at<double>(2, 6) = zmax;
        Bp.at<double>(0, 7) = xmin; Bp.at<double>(1, 7) = ymax; Bp.at<double>(2, 7) = zmax;
        Mat Rpp; transpose(Rp, Rpp);
        Bp = Rpp*Bp;
        transpose(Bp, Bp);
        
        Box3d* Bk = new Box3d(Bp);
        B.push_back(Bk);
    }
    
    return B;
}

Mat TableObjectDetector::determinePlaneRotation(cv::Mat normal) {
    // Graham Schmidt orthogonalization
    int mind = 0; double mval = 999;
    for (int i=0; i<3; i++) {
        if (abs(normal.at<double>(i)) < mval) {
            mind = i;
            mval = abs(normal.at<double>(i));
        }
    }
    
    Mat vstart = -mval*normal;
    vstart.at<double>(mind) = 1;
    vstart = vstart/cv::norm(vstart);
    Mat v2 = normal.cross(vstart);
    v2 = v2/cv::norm(v2);
    Mat v3 = normal.cross(v2);
    v3 = v3/cv::norm(v3);
    
    Mat R(3, 3, CV_64F);
    v2.copyTo(R.col(0));
    v3.copyTo(R.col(1));
    normal.copyTo(R.col(2));
    
    return R;
}


TableObjectDetector::~TableObjectDetector() {
    
}

