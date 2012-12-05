#include "mex.h"
#include "math.h"
#include <XnOpenNI.h>
#include <XnCodecIDs.h>
#include <XnCppWrapper.h>

#define CHECK_RC(nRetVal, what)										\
	if (nRetVal != XN_STATUS_OK)									\
	{																\
		printf("%s failed: %s\n", what, xnGetStatusString(nRetVal));\
        mexErrMsgTxt("Kinect Error"); 							    \
	}
    
//---------------------------------------------------------------------------
// Globals
//---------------------------------------------------------------------------
xn::Context g_Context;
xn::DepthGenerator g_DepthGenerator;

/* The matlab mex function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    double *Iout;
    XnUInt64 *MXadress;
    
    if(nrhs==0)
    {
       printf("Open failed: Give Pointer to Kinect as input\n");
       mexErrMsgTxt("Kinect Error"); 
    }
    
    MXadress = (XnUInt64*)mxGetData(prhs[0]);
    if(MXadress[0]>0){ g_Context = ((xn::Context*) MXadress[0])[0]; }
    if(MXadress[2]>0)
	{ 
		g_DepthGenerator = ((xn::DepthGenerator*) MXadress[2])[0]; 
	}
	else
	{
		mexErrMsgTxt("No Depth Node in Kinect Context"); 
	}
    
    XnStatus nRetVal = XN_STATUS_OK;

	xn::DepthMetaData depthMD;
    
	// Process the data
	g_DepthGenerator.GetMetaData(depthMD);
        
  	XnUInt16 g_nXRes = depthMD.FullXRes();
	XnUInt16 g_nYRes = depthMD.FullYRes();
	const XnDepthPixel* pDepth = depthMD.Data();
    int Jdimsc[3];
    Jdimsc[0]=g_nXRes; 
    Jdimsc[1]=g_nYRes; 
    Jdimsc[2]=3;
    
    int npixels=Jdimsc[0]*Jdimsc[1];
    int index;
    XnPoint3D *pt_proj =new XnPoint3D[npixels];
    XnPoint3D *pt_world=new XnPoint3D[npixels];
    for(int y=0; y<Jdimsc[1]; y++)
    {
        for(int x=0; x<Jdimsc[0]; x++)
        {
            index=x+y*Jdimsc[0];
            pt_proj[index].X=(XnFloat)x;
            pt_proj[index].Y=(XnFloat)y;
            pt_proj[index].Z=pDepth[x+y*Jdimsc[0]];
        }
    }
    g_DepthGenerator.ConvertProjectiveToRealWorld ( (XnUInt32)npixels,   pt_proj, pt_world);
    
    plhs[0] = mxCreateNumericArray(3, Jdimsc, mxDOUBLE_CLASS, mxREAL);
    Iout = mxGetPr(plhs[0]);
    for(int y=0; y<Jdimsc[1]; y++)
    {
        for(int x=0; x<Jdimsc[0]; x++)
        {
            index=x+y*Jdimsc[0];
            Iout[index]=pt_world[index].X;
            Iout[index+npixels]=pt_world[index].Y;
            Iout[index+npixels*2]=pt_world[index].Z;
        }
    }
    
    delete[] pt_proj;
    delete[] pt_world;
}
