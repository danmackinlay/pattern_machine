#!/bin/sh

sox chimegongfrenzy.aif -n spectrogram -m -Y 720 -l -r -o chimegongfrenzy.png
open chimegongfrenzy.png