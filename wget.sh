#!/bin/sh

wget -q -U "Mozilla/5.0" --post-file /tmp/recording.flac --header="Content-Type: audio/x-flac; rate=16000" -O - "http://www.google.com/speech-api/v1/recognize?lang=en-us&client=chromium"
