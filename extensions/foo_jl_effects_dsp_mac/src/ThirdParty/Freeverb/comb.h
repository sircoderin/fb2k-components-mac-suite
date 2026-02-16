// Comb filter for Freeverb
// Written by Jezar at Dreampoint, June 2000
// http://www.dreampoint.co.uk
// This code is public domain

#pragma once

#include <cstring>

class comb {
public:
    comb() : filterstore(0), bufidx(0), buffer(nullptr), bufsize(0) {}

    void setbuffer(float* buf, int size) {
        buffer = buf;
        bufsize = size;
    }

    void mute() {
        if (buffer) std::memset(buffer, 0, bufsize * sizeof(float));
        filterstore = 0;
    }

    float process(float input) {
        float output = buffer[bufidx];
        filterstore = (output * damp2) + (filterstore * damp1);
        buffer[bufidx] = input + (filterstore * feedback);
        if (++bufidx >= bufsize) bufidx = 0;
        return output;
    }

    void setdamp(float val) { damp1 = val; damp2 = 1 - val; }
    float getdamp() { return damp1; }
    void setfeedback(float val) { feedback = val; }
    float getfeedback() { return feedback; }

private:
    float feedback = 0;
    float filterstore = 0;
    float damp1 = 0;
    float damp2 = 0;
    float* buffer;
    int   bufsize;
    int   bufidx;
};
