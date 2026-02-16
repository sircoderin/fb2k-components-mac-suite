// Allpass filter for Freeverb
// Written by Jezar at Dreampoint, June 2000
// http://www.dreampoint.co.uk
// This code is public domain

#pragma once

#include <cstring>

class allpass {
public:
    allpass() : bufidx(0), buffer(nullptr), bufsize(0) {}

    void setbuffer(float* buf, int size) {
        buffer = buf;
        bufsize = size;
    }

    void mute() {
        if (buffer) std::memset(buffer, 0, bufsize * sizeof(float));
    }

    float process(float input) {
        float bufout = buffer[bufidx];
        float output = -input + bufout;
        buffer[bufidx] = input + (bufout * feedback);
        if (++bufidx >= bufsize) bufidx = 0;
        return output;
    }

    void setfeedback(float val) { feedback = val; }
    float getfeedback() { return feedback; }

private:
    float feedback = 0.5f;
    float* buffer;
    int   bufsize;
    int   bufidx;
};
