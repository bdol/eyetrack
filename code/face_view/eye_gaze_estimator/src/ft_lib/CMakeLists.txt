set(face_tracker_sources
    CLM.cc
    FCheck.cc
    FDet.cc
    IO.cc
    Patch.cc
    PAW.cc
    PDM.cc
    Tracker.cc
)

add_library(face_tracker ${face_tracker_sources})
