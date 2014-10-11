FLustre
========

Spectrographic sound playground for the layperson

TODO:
-----

* autocorrelation instead of bandpass
* SendReply instead of SendTrig
* pause unused (analysis) synths
* record samples live
* switch to TCP instead of UDP to avoid dropped packets
* communcate from processing direct to supercollider.
* spectral improvements
  * colourise spectral display to indicate chromaticity
  * detect (and visualise) noisiness vs percussiveness?
  * check pixel dimensions of the vizualiser app
  * what does weird with high amplitude bands?
* web version
* sound nicer
  * reverb. C'mon, the kids love reverb.
* eliminate, or at least document, dependencies
  * For processing
  * oscp5
  * syphon
* ditch processing, ditch analysis in supercollider; send images to Quartz composer from Python
  * even nacked objc syphon calls from python
