// Effects DSP component registration
//
// Each effect registers its own dsp_factory_t<> in its .cpp file.
// This file provides the component version declaration.

#include "Effects/Echo.h"
#include "Effects/Tremolo.h"
#include "Effects/IIRFilter.h"
#include "Effects/Reverb.h"
#include "Effects/Phaser.h"
#include "Effects/WahWah.h"
#include "Effects/Chorus.h"
#include "Effects/Vibrato.h"
#include "Effects/PitchShift.h"
#include "Effects/TempoShift.h"
#include "Effects/RateShift.h"
#include "../../shared/version.h"

DECLARE_COMPONENT_VERSION(
    "Effects DSP",
    EFFECTS_DSP_VERSION,
    "Audio effects collection for foobar2000 macOS.\n"
    "Echo, Tremolo, IIR Filter, Reverb, Phaser, WahWah,\n"
    "Chorus, Vibrato, Pitch Shift, Tempo Shift, Rate Shift.\n\n"
    "Based on foo_dsp_effect by mudlord (Unlicense).\n"
    "Copyright (c) 2025 Jenda Legenda. MIT License."
);

VALIDATE_COMPONENT_FILENAME("foo_jl_effects_dsp.component");
