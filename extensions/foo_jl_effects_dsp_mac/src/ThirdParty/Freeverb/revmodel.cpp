// Reverb model implementation for Freeverb
// Written by Jezar at Dreampoint, June 2000
// http://www.dreampoint.co.uk
// This code is public domain

#include "revmodel.h"

revmodel::revmodel() {
    combL[0].setbuffer(bufcombL1, combtuning_L1);
    combL[1].setbuffer(bufcombL2, combtuning_L2);
    combL[2].setbuffer(bufcombL3, combtuning_L3);
    combL[3].setbuffer(bufcombL4, combtuning_L4);
    combL[4].setbuffer(bufcombL5, combtuning_L5);
    combL[5].setbuffer(bufcombL6, combtuning_L6);
    combL[6].setbuffer(bufcombL7, combtuning_L7);
    combL[7].setbuffer(bufcombL8, combtuning_L8);
    combR[0].setbuffer(bufcombR1, combtuning_R1);
    combR[1].setbuffer(bufcombR2, combtuning_R2);
    combR[2].setbuffer(bufcombR3, combtuning_R3);
    combR[3].setbuffer(bufcombR4, combtuning_R4);
    combR[4].setbuffer(bufcombR5, combtuning_R5);
    combR[5].setbuffer(bufcombR6, combtuning_R6);
    combR[6].setbuffer(bufcombR7, combtuning_R7);
    combR[7].setbuffer(bufcombR8, combtuning_R8);
    allpassL[0].setbuffer(bufallpassL1, allpasstuning_L1);
    allpassL[1].setbuffer(bufallpassL2, allpasstuning_L2);
    allpassL[2].setbuffer(bufallpassL3, allpasstuning_L3);
    allpassL[3].setbuffer(bufallpassL4, allpasstuning_L4);
    allpassR[0].setbuffer(bufallpassR1, allpasstuning_R1);
    allpassR[1].setbuffer(bufallpassR2, allpasstuning_R2);
    allpassR[2].setbuffer(bufallpassR3, allpasstuning_R3);
    allpassR[3].setbuffer(bufallpassR4, allpasstuning_R4);

    allpassL[0].setfeedback(0.5f);
    allpassL[1].setfeedback(0.5f);
    allpassL[2].setfeedback(0.5f);
    allpassL[3].setfeedback(0.5f);
    allpassR[0].setfeedback(0.5f);
    allpassR[1].setfeedback(0.5f);
    allpassR[2].setfeedback(0.5f);
    allpassR[3].setfeedback(0.5f);

    setwet(initialwet);
    setroomsize(initialroom);
    setdry(initialdry);
    setdamp(initialdamp);
    setwidth(initialwidth);
    setmode(initialmode);

    mute();
}

void revmodel::mute() {
    for (int i = 0; i < numcombs; i++) {
        combL[i].mute();
        combR[i].mute();
    }
    for (int i = 0; i < numallpasses; i++) {
        allpassL[i].mute();
        allpassR[i].mute();
    }
}

void revmodel::processreplace(float* inputL, float* inputR,
                               float* outputL, float* outputR,
                               long numsamples, int skip) {
    float outL, outR, input;

    while (numsamples-- > 0) {
        outL = outR = 0;
        input = (*inputL + *inputR) * gain;

        // Accumulate comb filters in parallel
        for (int i = 0; i < numcombs; i++) {
            outL += combL[i].process(input);
            outR += combR[i].process(input);
        }

        // Feed through allpasses in series
        for (int i = 0; i < numallpasses; i++) {
            outL = allpassL[i].process(outL);
            outR = allpassR[i].process(outR);
        }

        // Apply wet/dry and width
        *outputL = outL * wet1 + outR * wet2 + *inputL * dry;
        *outputR = outR * wet1 + outL * wet2 + *inputR * dry;

        inputL += skip;
        inputR += skip;
        outputL += skip;
        outputR += skip;
    }
}

void revmodel::processmix(float* inputL, float* inputR,
                           float* outputL, float* outputR,
                           long numsamples, int skip) {
    float outL, outR, input;

    while (numsamples-- > 0) {
        outL = outR = 0;
        input = (*inputL + *inputR) * gain;

        for (int i = 0; i < numcombs; i++) {
            outL += combL[i].process(input);
            outR += combR[i].process(input);
        }

        for (int i = 0; i < numallpasses; i++) {
            outL = allpassL[i].process(outL);
            outR = allpassR[i].process(outR);
        }

        *outputL += outL * wet1 + outR * wet2 + *inputL * dry;
        *outputR += outR * wet1 + outL * wet2 + *inputR * dry;

        inputL += skip;
        inputR += skip;
        outputL += skip;
        outputR += skip;
    }
}

void revmodel::update() {
    wet1 = wet * (width / 2 + 0.5f);
    wet2 = wet * ((1 - width) / 2);

    if (mode >= freezemode) {
        roomsize1 = 1;
        damp1 = 0;
        gain = muted;
    } else {
        roomsize1 = roomsize;
        damp1 = damp;
        gain = fixedgain;
    }

    for (int i = 0; i < numcombs; i++) {
        combL[i].setfeedback(roomsize1);
        combR[i].setfeedback(roomsize1);
        combL[i].setdamp(damp1);
        combR[i].setdamp(damp1);
    }
}

void revmodel::setroomsize(float value) {
    roomsize = (value * scaleroom) + offsetroom;
    update();
}

float revmodel::getroomsize() {
    return (roomsize - offsetroom) / scaleroom;
}

void revmodel::setdamp(float value) {
    damp = value * scaledamp;
    update();
}

float revmodel::getdamp() {
    return damp / scaledamp;
}

void revmodel::setwet(float value) {
    wet = value * scalewet;
    update();
}

float revmodel::getwet() {
    return wet / scalewet;
}

void revmodel::setdry(float value) {
    dry = value * scaledry;
}

float revmodel::getdry() {
    return dry / scaledry;
}

void revmodel::setwidth(float value) {
    width = value;
    update();
}

float revmodel::getwidth() {
    return width;
}

void revmodel::setmode(float value) {
    mode = value;
    update();
}

float revmodel::getmode() {
    if (mode >= freezemode) return 1;
    return 0;
}
