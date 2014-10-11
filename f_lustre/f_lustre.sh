#!/usr/bin/env sh
##!/usr/bin/env PATH="$PATH":/Applications/SuperCollider/SuperCollider.app/Contents/Resources/sclang sh
export PATH=$PATH:/Applications/SuperCollider/SuperCollider.app/Contents/Resources/
sclang -d $PWD settings_icst.scd FLustre.scd
#~/processing-java --sketch=$PWD/FLustreDisplay --output=$PWD/output --force --present width=80
#https://forum.processing.org/topic/use-external-editor-is-gone-in-beta-5-now-what
#https://code.google.com/p/processing/issues/detail?id=142
