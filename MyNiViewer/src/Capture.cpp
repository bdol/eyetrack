/****************************************************************************
*                                                                           *
*  OpenNI 1.x Alpha                                                         *
*  Copyright (C) 2011 PrimeSense Ltd.                                       *
*                                                                           *
*  This file is part of OpenNI.                                             *
*                                                                           *
*  OpenNI is free software: you can redistribute it and/or modify           *
*  it under the terms of the GNU Lesser General Public License as published *
*  by the Free Software Foundation, either version 3 of the License, or     *
*  (at your option) any later version.                                      *
*                                                                           *
*  OpenNI is distributed in the hope that it will be useful,                *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the             *
*  GNU Lesser General Public License for more details.                      *
*                                                                           *
*  You should have received a copy of the GNU Lesser General Public License *
*  along with OpenNI. If not, see <http://www.gnu.org/licenses/>.           *
*                                                                           *
****************************************************************************/
// --------------------------------
// Includes
// --------------------------------
#include "Capture.h"
#include "Device.h"
#include "Draw.h"
#include <XnCppWrapper.h>
#include <XnCodecIDs.h>
#include <sstream>
using namespace xn;

#if (XN_PLATFORM == XN_PLATFORM_WIN32)
#include <Commdlg.h>
#endif

// --------------------------------
// Defines
// --------------------------------
#define CAPTURED_FRAMES_DIR_NAME captured_frames_dir_name

// --------------------------------
// Types
// --------------------------------
typedef enum
{
	NOT_CAPTURING,
	SHOULD_CAPTURE,
	CAPTURING,
	SEQUENCE_SHOULD_CAPTURE,
	SEQUENCE_BURST_CAPTURE,
	SEQUENCE_MAIN_CAPTURE,
	THANKYOU,
} CapturingState;

typedef enum
{
	CAPTURE_DEPTH_NODE,
	CAPTURE_IMAGE_NODE,
	CAPTURE_IR_NODE,
	CAPTURE_AUDIO_NODE,
	CAPTURE_NODE_COUNT
} CaptureNodeType;

typedef struct NodeCapturingData
{
	XnCodecID captureFormat;
	XnUInt32 nCapturedFrames;
	bool bRecording;
	xn::Generator* pGenerator;
} NodeCapturingData;

typedef struct CapturingData
{
	NodeCapturingData nodes[CAPTURE_NODE_COUNT];
	Recorder* pRecorder;
	char csFileName[XN_FILE_MAX_PATH];
	XnUInt32 nStartOn; // time to start, in seconds
	bool bSkipFirstFrame;
	CapturingState State;
	XnUInt32 nCapturedFrameUniqueID;
	char csDisplayMessage[500];
	int command_count;
	int sequence_delay;
	int total_number_commands;
	XnUInt32 sequence_nStartOn; // time to start, in seconds for sequence capturing
	int total_bursts;
	int burst_count;
	XnUInt32 sequence_burst_delay; // time between bursts of capture during sequence captures
} CapturingData;

// --------------------------------
// Global Variables
// --------------------------------
CapturingData g_Capture;

NodeCodec g_DepthFormat;
NodeCodec g_ImageFormat;
NodeCodec g_IRFormat;
NodeCodec g_AudioFormat;

static const XnCodecID CODEC_DONT_CAPTURE = XN_CODEC_NULL;

char* captured_frames_dir_name = "CapturedFrames";

// --------------------------------
// Code
// --------------------------------
void captureInit(char* saveToFolderName)
{
	if(strcmp(saveToFolderName, "")!=0)
	{
		captured_frames_dir_name = saveToFolderName;
	}
	// Depth Formats
	int nIndex = 0;

	g_DepthFormat.pValues[nIndex] = XN_CODEC_16Z_EMB_TABLES;
	g_DepthFormat.pIndexToName[nIndex] = "PS Compression (16z ET)";
	nIndex++;

	g_DepthFormat.pValues[nIndex] = XN_CODEC_UNCOMPRESSED;
	g_DepthFormat.pIndexToName[nIndex] = "Uncompressed";
	nIndex++;

	g_DepthFormat.pValues[nIndex] = CODEC_DONT_CAPTURE;
	g_DepthFormat.pIndexToName[nIndex] = "Not Captured";
	nIndex++;

	g_DepthFormat.nValuesCount = nIndex;

	// Image Formats
	nIndex = 0;

	g_ImageFormat.pValues[nIndex] = XN_CODEC_JPEG;
	g_ImageFormat.pIndexToName[nIndex] = "JPEG";
	nIndex++;

	g_ImageFormat.pValues[nIndex] = XN_CODEC_UNCOMPRESSED;
	g_ImageFormat.pIndexToName[nIndex] = "Uncompressed";
	nIndex++;

 	g_ImageFormat.pValues[nIndex] = CODEC_DONT_CAPTURE;
 	g_ImageFormat.pIndexToName[nIndex] = "Not Captured";
	nIndex++;

	g_ImageFormat.nValuesCount = nIndex;

	// IR Formats
	nIndex = 0;

	g_IRFormat.pValues[nIndex] = XN_CODEC_UNCOMPRESSED;
	g_IRFormat.pIndexToName[nIndex] = "Uncompressed";
	nIndex++;

	g_IRFormat.pValues[nIndex] = CODEC_DONT_CAPTURE;
	g_IRFormat.pIndexToName[nIndex] = "Not Captured";
	nIndex++;

	g_IRFormat.nValuesCount = nIndex;

	// Audio Formats
	nIndex = 0;

	g_AudioFormat.pValues[nIndex] = XN_CODEC_UNCOMPRESSED;
	g_AudioFormat.pIndexToName[nIndex] = "Uncompressed";
	nIndex++;

 	g_AudioFormat.pValues[nIndex] = CODEC_DONT_CAPTURE;
 	g_AudioFormat.pIndexToName[nIndex] = "Not Captured";
	nIndex++;

	g_AudioFormat.nValuesCount = nIndex;

	// Init
	g_Capture.csFileName[0] = 0;
	g_Capture.State = NOT_CAPTURING;
	g_Capture.nCapturedFrameUniqueID = 0;
	g_Capture.csDisplayMessage[0] = '\0';
	g_Capture.bSkipFirstFrame = false;

	g_Capture.nodes[CAPTURE_DEPTH_NODE].captureFormat = XN_CODEC_16Z_EMB_TABLES;
	g_Capture.nodes[CAPTURE_IMAGE_NODE].captureFormat = XN_CODEC_JPEG;
	g_Capture.nodes[CAPTURE_IR_NODE].captureFormat = XN_CODEC_UNCOMPRESSED;
	g_Capture.nodes[CAPTURE_AUDIO_NODE].captureFormat = XN_CODEC_UNCOMPRESSED;
}

bool isCapturing()
{
	return (g_Capture.State != NOT_CAPTURING);
}

#define START_CAPTURE_CHECK_RC(rc, what)												\
	if (nRetVal != XN_STATUS_OK)														\
	{																					\
		displayMessage("Failed to %s: %s\n", what, xnGetStatusString(rc));				\
		delete g_Capture.pRecorder;														\
		g_Capture.pRecorder = NULL;														\
		return false;																	\
	}

bool captureOpenWriteDevice()
{
	XnStatus nRetVal = XN_STATUS_OK;
	NodeInfoList recordersList;
	nRetVal = g_Context.EnumerateProductionTrees(XN_NODE_TYPE_RECORDER, NULL, recordersList);
	START_CAPTURE_CHECK_RC(nRetVal, "Enumerate recorders");
	// take first
	NodeInfo chosen = *recordersList.Begin();

	g_Capture.pRecorder = new Recorder;
	nRetVal = g_Context.CreateProductionTree(chosen, *g_Capture.pRecorder);
	START_CAPTURE_CHECK_RC(nRetVal, "Create recorder");

	nRetVal = g_Capture.pRecorder->SetDestination(XN_RECORD_MEDIUM_FILE, g_Capture.csFileName);
	START_CAPTURE_CHECK_RC(nRetVal, "Set output file");

	return true;
}

void captureBrowse(int)
{
#if (XN_PLATFORM == XN_PLATFORM_WIN32)
	OPENFILENAMEA ofn;
	TCHAR *szFilter = TEXT("ONI Files (*.oni)\0")
		TEXT("*.oni\0")
		TEXT("All Files (*.*)\0")
		TEXT("*.*\0");

	ZeroMemory(&ofn,sizeof(OPENFILENAME));

	ofn.lStructSize = sizeof(OPENFILENAME);
	ofn.lpstrFilter = szFilter;
	ofn.nFilterIndex = 1;
	ofn.lpstrFile = g_Capture.csFileName;
	ofn.nMaxFile = sizeof(g_Capture.csFileName);
	ofn.lpstrTitle = TEXT("Capture to...");
	ofn.Flags = OFN_EXPLORER | OFN_NOCHANGEDIR;

	GetSaveFileName(&ofn); 

	if (g_Capture.csFileName[0] != 0)
	{
		if (strstr(g_Capture.csFileName, ".oni") == NULL)
		{
			strcat(g_Capture.csFileName, ".oni");
		}
	}
#else // not Win32
	strcpy(g_Capture.csFileName, "./Captured.oni");
#endif

	// as we waited for user input, it's probably better to discard first frame (especially if an accumulating
	// stream is on, like audio).
	g_Capture.bSkipFirstFrame = true;

	captureOpenWriteDevice();
}

void captureStart(int nDelay)
{
	if (g_Capture.csFileName[0] == 0)
	{
		captureBrowse(0);
	}

	if (g_Capture.csFileName[0] == 0)
		return;

	if (g_Capture.pRecorder == NULL)
	{
		if (!captureOpenWriteDevice())
			return;
	}

	XnUInt64 nNow;
	xnOSGetTimeStamp(&nNow);
	nNow /= 1000;

	g_Capture.nStartOn = (XnUInt32)nNow + nDelay;
	g_Capture.State = SHOULD_CAPTURE;
}

void captureCloseWriteDevice()
{
	if (g_Capture.pRecorder != NULL)
	{
		g_Capture.pRecorder->Release();
		delete g_Capture.pRecorder;
		g_Capture.pRecorder = NULL;
	}
}

void captureRestart(int)
{
	captureCloseWriteDevice();
	if (captureOpenWriteDevice())
		captureStart(0);
}

void captureStop(int)
{
	if (g_Capture.State != NOT_CAPTURING)
	{
		g_Capture.State = NOT_CAPTURING;
		captureCloseWriteDevice();
	}
}

XnStatus captureFrame()
{
	XnStatus nRetVal = XN_STATUS_OK;

	if (g_Capture.State == SHOULD_CAPTURE)
	{
		XnUInt64 nNow;
		xnOSGetTimeStamp(&nNow);
		nNow /= 1000;

		// check if time has arrived
		if (nNow >= g_Capture.nStartOn)
		{
			// check if we need to discard first frame
			if (g_Capture.bSkipFirstFrame)
			{
				g_Capture.bSkipFirstFrame = false;
			}
			else
			{
				// start recording
				for (int i = 0; i < CAPTURE_NODE_COUNT; ++i)
				{
					g_Capture.nodes[i].nCapturedFrames = 0;
					g_Capture.nodes[i].bRecording = false;
				}
				g_Capture.State = CAPTURING;

				// add all captured nodes
				if (getDevice() != NULL)
				{
					nRetVal = g_Capture.pRecorder->AddNodeToRecording(*getDevice(), XN_CODEC_UNCOMPRESSED);
					START_CAPTURE_CHECK_RC(nRetVal, "add device node");
				}

				if (isDepthOn() && (g_Capture.nodes[CAPTURE_DEPTH_NODE].captureFormat != CODEC_DONT_CAPTURE))
				{
					nRetVal = g_Capture.pRecorder->AddNodeToRecording(*getDepthGenerator(), g_Capture.nodes[CAPTURE_DEPTH_NODE].captureFormat);
					START_CAPTURE_CHECK_RC(nRetVal, "add depth node");
					g_Capture.nodes[CAPTURE_DEPTH_NODE].bRecording = TRUE;
					g_Capture.nodes[CAPTURE_DEPTH_NODE].pGenerator = getDepthGenerator();
				}

				if (isImageOn() && (g_Capture.nodes[CAPTURE_IMAGE_NODE].captureFormat != CODEC_DONT_CAPTURE))
				{
					nRetVal = g_Capture.pRecorder->AddNodeToRecording(*getImageGenerator(), g_Capture.nodes[CAPTURE_IMAGE_NODE].captureFormat);
					START_CAPTURE_CHECK_RC(nRetVal, "add image node");
					g_Capture.nodes[CAPTURE_IMAGE_NODE].bRecording = TRUE;
					g_Capture.nodes[CAPTURE_IMAGE_NODE].pGenerator = getImageGenerator();
				}

				if (isIROn() && (g_Capture.nodes[CAPTURE_IR_NODE].captureFormat != CODEC_DONT_CAPTURE))
				{
					nRetVal = g_Capture.pRecorder->AddNodeToRecording(*getIRGenerator(), g_Capture.nodes[CAPTURE_IR_NODE].captureFormat);
					START_CAPTURE_CHECK_RC(nRetVal, "add IR stream");
					g_Capture.nodes[CAPTURE_IR_NODE].bRecording = TRUE;
					g_Capture.nodes[CAPTURE_IR_NODE].pGenerator = getIRGenerator();
				}

				if (isAudioOn() && (g_Capture.nodes[CAPTURE_AUDIO_NODE].captureFormat != CODEC_DONT_CAPTURE))
				{
					nRetVal = g_Capture.pRecorder->AddNodeToRecording(*getAudioGenerator(), g_Capture.nodes[CAPTURE_AUDIO_NODE].captureFormat);
					START_CAPTURE_CHECK_RC(nRetVal, "add Audio stream");
					g_Capture.nodes[CAPTURE_AUDIO_NODE].bRecording = TRUE;
					g_Capture.nodes[CAPTURE_AUDIO_NODE].pGenerator = getAudioGenerator();
				}
			}
		}
	}

	if (g_Capture.State == CAPTURING)
	{
		// There isn't a real need to call Record() here, as the WaitXUpdateAll() call already makes sure
		// recording is performed.
		nRetVal = g_Capture.pRecorder->Record();
		XN_IS_STATUS_OK(nRetVal);

		// count recorded frames
		for (int i = 0; i < CAPTURE_NODE_COUNT; ++i)
		{
			if (g_Capture.nodes[i].bRecording && g_Capture.nodes[i].pGenerator->IsDataNew())
				g_Capture.nodes[i].nCapturedFrames++;
		}
	}
	return XN_STATUS_OK;
}

void captureSetFormat(XnCodecID* pMember, XnCodecID newFormat, ProductionNode &node)
{
	if (*pMember == newFormat)
		return;

	if (g_Capture.pRecorder != NULL)
	{
		// check if it was off before
		if (*pMember == CODEC_DONT_CAPTURE)
		{
			g_Capture.pRecorder->AddNodeToRecording(node, newFormat);
		}
		// check if it is off now
		else if (newFormat == CODEC_DONT_CAPTURE)
		{
			g_Capture.pRecorder->RemoveNodeFromRecording(node);
		}
		else // just a change in compression
		{
			g_Capture.pRecorder->RemoveNodeFromRecording(node);
			g_Capture.pRecorder->AddNodeToRecording(node, newFormat);
		}
	}

	*pMember = newFormat;
}

void captureSetDepthFormat(int format)
{
	captureSetFormat(&g_Capture.nodes[CAPTURE_DEPTH_NODE].captureFormat, format, *getDepthGenerator());
}

void captureSetImageFormat(int format)
{
	captureSetFormat(&g_Capture.nodes[CAPTURE_IMAGE_NODE].captureFormat, format, *getImageGenerator());
}

void captureSetIRFormat(int format)
{
	captureSetFormat(&g_Capture.nodes[CAPTURE_IR_NODE].captureFormat, format, *getIRGenerator());
}

void captureSetAudioFormat(int format)
{
	captureSetFormat(&g_Capture.nodes[CAPTURE_AUDIO_NODE].captureFormat, format, *getAudioGenerator());
}

const char* getCodecName(NodeCodec *pNodeCodec, XnCodecID codecID)
{
	for (int i = 0; i < pNodeCodec->nValuesCount; i++)
	{
		if (pNodeCodec->pValues[i] == codecID)
		{
			return pNodeCodec->pIndexToName[i];
		}
	}
	return NULL;
}

const char* captureGetDepthFormatName()
{
	return getCodecName(&g_DepthFormat, g_Capture.nodes[CAPTURE_DEPTH_NODE].captureFormat);
}

const char* captureGetImageFormatName()
{
	return getCodecName(&g_ImageFormat, g_Capture.nodes[CAPTURE_IMAGE_NODE].captureFormat);
}

const char* captureGetIRFormatName()
{
	return getCodecName(&g_IRFormat, g_Capture.nodes[CAPTURE_IR_NODE].captureFormat);
}

const char* captureGetAudioFormatName()
{
	return getCodecName(&g_AudioFormat, g_Capture.nodes[CAPTURE_AUDIO_NODE].captureFormat);
}

void getCaptureMessage(char* pMessage)
{
	switch (g_Capture.State)
	{
	case SEQUENCE_SHOULD_CAPTURE:
	{
		sprintf(pMessage, "Sequence Capturing will start immediately");
	}
	break;
	case SHOULD_CAPTURE:
		{
			XnUInt64 nNow;
			xnOSGetTimeStamp(&nNow);
			nNow /= 1000;
			sprintf(pMessage, "Capturing will start in %u seconds...", g_Capture.nStartOn - (XnUInt32)nNow);
		}
		break;
	case CAPTURING:
		{
			int nChars = sprintf(pMessage, "* Recording! Press any key or use menu to stop *\nRecorded Frames: ");
			for (int i = 0; i < CAPTURE_NODE_COUNT; ++i)
			{
				if (g_Capture.nodes[i].bRecording)
				{
					nChars += sprintf(pMessage + nChars, "%s-%d ", g_Capture.nodes[i].pGenerator->GetName(), g_Capture.nodes[i].nCapturedFrames);
				}
			}
		}
		break;
	case SEQUENCE_MAIN_CAPTURE:
	{
		sprintf(pMessage, "Sequence Capturing in progress...@Command: %d", g_Capture.command_count);
	}
	break;
	default:
		pMessage[0] = 0;
	}
}

void getImageFileName(int picnum, char* csName, int generate_capture_sequence_filenames=-1)
{
	// if the capture is for the sequence capture custom routine, then generate the filenames differently
	if(!generate_capture_sequence_filenames)
		sprintf(csName, "%s/IM_For_Katie_%d.raw", captured_frames_dir_name, picnum);
	else
		sprintf(csName, "%s/IM_%d_%d.raw", captured_frames_dir_name, g_Capture.command_count, g_Capture.burst_count);
	//sprintf(csName, "%s/Image_%d.raw", subjectName, num);
}

void getDepthFileName(int picnum, char* csName, int generate_capture_sequence_filenames=-1)
{
	if(!generate_capture_sequence_filenames)
		sprintf(csName, "%s/DP_For_Katie_%d.raw", captured_frames_dir_name, picnum);
	else
		sprintf(csName, "%s/DP_%d_%d.raw", captured_frames_dir_name, g_Capture.command_count, g_Capture.burst_count);
}

void getIRFileName(int picnum, char* csName, int generate_capture_sequence_filenames=-1)
{
	if(!generate_capture_sequence_filenames)
		sprintf(csName, "%s/IR_For_Katie_%d.raw", CAPTURED_FRAMES_DIR_NAME, picnum);
	else
		sprintf(csName, "%s/IR_%d_%d.raw", captured_frames_dir_name, g_Capture.command_count, g_Capture.burst_count);
}

int findUniqueFileName()
{
	xnOSCreateDirectory(CAPTURED_FRAMES_DIR_NAME);

	int num = g_Capture.nCapturedFrameUniqueID;

	XnBool bExist = FALSE;
	XnStatus nRetVal = XN_STATUS_OK;
	XnChar csImageFileName[XN_FILE_MAX_PATH];
	XnChar csDepthFileName[XN_FILE_MAX_PATH];
	XnChar csIRFileName[XN_FILE_MAX_PATH];

	for (;;)
	{
		// check image
		getImageFileName(num, csImageFileName);

		nRetVal = xnOSDoesFileExist(csImageFileName, &bExist);
		if (nRetVal != XN_STATUS_OK)
			break;

		if (!bExist)
		{
			// check depth
			getDepthFileName(num, csDepthFileName);

			nRetVal = xnOSDoesFileExist(csDepthFileName, &bExist);
			if (nRetVal != XN_STATUS_OK || !bExist)
				break;
		}

		if (!bExist)
		{
			// check IR
			getIRFileName(num, csIRFileName);

			nRetVal = xnOSDoesFileExist(csIRFileName, &bExist);
			if (nRetVal != XN_STATUS_OK || !bExist)
				break;
		}

		++num;
	}

	return num;
}

void captureSingleFrame(int generate_capture_sequence_file_names)
{
	int num = findUniqueFileName();

	XnChar csImageFileName[XN_FILE_MAX_PATH];
	XnChar csDepthFileName[XN_FILE_MAX_PATH];
	XnChar csIRFileName[XN_FILE_MAX_PATH];
	// if not 0, generate names according to gCapture command_count and burst_count
	getImageFileName(num, csImageFileName, generate_capture_sequence_file_names);
	getDepthFileName(num, csDepthFileName, generate_capture_sequence_file_names);
	getIRFileName(num, csIRFileName, generate_capture_sequence_file_names);

	const ImageMetaData* pImageMD = getImageMetaData();
	if (pImageMD != NULL)
	{
		xnOSSaveFile(csImageFileName, pImageMD->Data(), pImageMD->DataSize());
	}

	const IRMetaData* pIRMD = getIRMetaData();
	if (pIRMD != NULL)
	{
		xnOSSaveFile(csIRFileName, pIRMD->Data(), pIRMD->DataSize());
	}

	const DepthMetaData* pDepthMD = getDepthMetaData();
	if (pDepthMD != NULL)
	{
		xnOSSaveFile(csDepthFileName, pDepthMD->Data(), pDepthMD->DataSize());
	}
	
	g_Capture.nCapturedFrameUniqueID = num + 1;

	displayMessage("Frames saved with ID %d", num);
//	displayMessage("Directory: %s", captured_frames_dir_name);
}


void captureSequenceStart(int main_delay, int burst_delay, int total_number_commands, int total_burst_count)
{
	XnUInt64 nNow;
	xnOSGetTimeStamp(&nNow);
	nNow /= 1000;

	g_Capture.sequence_nStartOn = (XnUInt32)nNow + main_delay;
	g_Capture.State = SEQUENCE_SHOULD_CAPTURE;
	g_Capture.command_count = 1;
	g_Capture.sequence_delay = main_delay;
	g_Capture.total_number_commands = total_number_commands;
	g_Capture.burst_count = 1;
	g_Capture.total_bursts = total_burst_count;
	g_Capture.sequence_burst_delay = burst_delay;
}

void captureSequenceCommands()
{
	XnUInt64 nNow;
	xnOSGetTimeStamp(&nNow);
	nNow /= 1000;
	if ((g_Capture.State == SEQUENCE_SHOULD_CAPTURE)||(g_Capture.State == SEQUENCE_MAIN_CAPTURE)||g_Capture.State == SEQUENCE_BURST_CAPTURE)
	{
		// check if time has arrived
		if (nNow >= g_Capture.sequence_nStartOn)
		{
			if((g_Capture.State == SEQUENCE_MAIN_CAPTURE)||(g_Capture.State == SEQUENCE_SHOULD_CAPTURE))
			{
				std::string str = ("\"C:\\Program Files\\Jampal\\ptts.vbs\" -u command_");
				std::string command_to_run;
				command_to_run.append(str);
				std::stringstream out;
				out<<g_Capture.command_count;
				command_to_run.append(out.str());
				command_to_run.append(".txt");
				system(command_to_run.c_str());
			}

			captureSingleFrame(1);

			// update burst counter
			if(g_Capture.burst_count > g_Capture.total_bursts - 1)
			{
				// update command counter
				if(g_Capture.command_count < g_Capture.total_number_commands)
				{
					g_Capture.command_count = g_Capture.command_count + 1;
					// reset burst counter (it will become outside the ifs)
					g_Capture.burst_count = 0;
					// update delay to wait for another 3seconds
					xnOSGetTimeStamp(&nNow);
					nNow /= 1000;
					g_Capture.sequence_nStartOn = (XnUInt32)nNow + g_Capture.sequence_delay;
					g_Capture.State = SEQUENCE_MAIN_CAPTURE;
				}
				else
				{
					g_Capture.State = THANKYOU;
					g_Capture.command_count = 1;
					g_Capture.burst_count = 1;
				}
			}
			else
			{
				// update delay to wait for another 0.5seconds
				xnOSGetTimeStamp(&nNow);
				nNow /= 1000;
				g_Capture.sequence_nStartOn = (XnUInt32)nNow + g_Capture.sequence_burst_delay;
				g_Capture.State = SEQUENCE_BURST_CAPTURE;
			}
			g_Capture.burst_count = g_Capture.burst_count + 1;
		}
	}
	else if(g_Capture.State == THANKYOU)
	{
		std::string str = ("\"C:\\Program Files\\Jampal\\ptts.vbs\" -u thankyou.txt");
		system(str.c_str());
		g_Capture.State = NOT_CAPTURING;
	}
}
