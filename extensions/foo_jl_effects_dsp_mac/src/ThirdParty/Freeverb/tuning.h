// Freeverb tuning constants
// Written by Jezar at Dreampoint, June 2000
// http://www.dreampoint.co.uk
// This code is public domain

#pragma once

const int numcombs    = 8;
const int numallpasses = 4;
const float muted     = 0;
const float fixedgain = 0.015f;
const float scalewet  = 3;
const float scaledry  = 2;
const float scaledamp = 0.4f;
const float scaleroom = 0.28f;
const float offsetroom = 0.7f;
const float initialroom = 0.5f;
const float initialdamp = 0.5f;
const float initialwet  = 1.0f / scalewet;
const float initialdry  = 0;
const float initialwidth = 1;
const int   initialmode = 0;
const float freezemode = 0.5f;
const int   stereospread = 23;

// Comb filter tunings (at 44100 Hz)
const int combtuning_L1 = 1116;
const int combtuning_L2 = 1188;
const int combtuning_L3 = 1277;
const int combtuning_L4 = 1356;
const int combtuning_L5 = 1422;
const int combtuning_L6 = 1491;
const int combtuning_L7 = 1557;
const int combtuning_L8 = 1617;

const int combtuning_R1 = 1116 + stereospread;
const int combtuning_R2 = 1188 + stereospread;
const int combtuning_R3 = 1277 + stereospread;
const int combtuning_R4 = 1356 + stereospread;
const int combtuning_R5 = 1422 + stereospread;
const int combtuning_R6 = 1491 + stereospread;
const int combtuning_R7 = 1557 + stereospread;
const int combtuning_R8 = 1617 + stereospread;

// Allpass filter tunings
const int allpasstuning_L1 = 556;
const int allpasstuning_L2 = 441;
const int allpasstuning_L3 = 341;
const int allpasstuning_L4 = 225;

const int allpasstuning_R1 = 556 + stereospread;
const int allpasstuning_R2 = 441 + stereospread;
const int allpasstuning_R3 = 341 + stereospread;
const int allpasstuning_R4 = 225 + stereospread;
