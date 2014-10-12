#!/bin/sh

sox chimegongfrenzy.aif -n spectrogram -m -Y 720 -l -r -o wave_display/data/spectrogram.png
open wave_display/data/spectrogram.png
