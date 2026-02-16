// Reverb model declaration for Freeverb
// Written by Jezar at Dreampoint, June 2000
// http://www.dreampoint.co.uk
// This code is public domain

#pragma once

#include "comb.h"
#include "allpass.h"
#include "tuning.h"

class revmodel {
public:
    revmodel();
    void mute();
    void processmix(float* inputL, float* inputR, float* outputL, float* outputR, long numsamples, int skip);
    void processreplace(float* inputL, float* inputR, float* outputL, float* outputR, long numsamples, int skip);
    void setroomsize(float value);
    float getroomsize();
    void setdamp(float value);
    float getdamp();
    void setwet(float value);
    float getwet();
    void setdry(float value);
    float getdry();
    void setwidth(float value);
    float getwidth();
    void setmode(float value);
    float getmode();

private:
    void update();

    float gain;
    float roomsize, roomsize1;
    float damp, damp1;
    float wet, wet1, wet2;
    float dry;
    float width;
    float mode;

    // Comb filters
    comb combL[numcombs];
    comb combR[numcombs];

    // Allpass filters
    allpass allpassL[numallpasses];
    allpass allpassR[numallpasses];

    // Buffers for comb filters
    float bufcombL1[combtuning_L1];
    float bufcombL2[combtuning_L2];
    float bufcombL3[combtuning_L3];
    float bufcombL4[combtuning_L4];
    float bufcombL5[combtuning_L5];
    float bufcombL6[combtuning_L6];
    float bufcombL7[combtuning_L7];
    float bufcombL8[combtuning_L8];
    float bufcombR1[combtuning_R1];
    float bufcombR2[combtuning_R2];
    float bufcombR3[combtuning_R3];
    float bufcombR4[combtuning_R4];
    float bufcombR5[combtuning_R5];
    float bufcombR6[combtuning_R6];
    float bufcombR7[combtuning_R7];
    float bufcombR8[combtuning_R8];

    // Buffers for allpass filters
    float bufallpassL1[allpasstuning_L1];
    float bufallpassL2[allpasstuning_L2];
    float bufallpassL3[allpasstuning_L3];
    float bufallpassL4[allpasstuning_L4];
    float bufallpassR1[allpasstuning_R1];
    float bufallpassR2[allpasstuning_R2];
    float bufallpassR3[allpasstuning_R3];
    float bufallpassR4[allpasstuning_R4];
};
