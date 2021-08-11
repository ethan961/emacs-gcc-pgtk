#!/usr/bin/env sh
docker build -t ndrvtl/emacs-gcc-pgtk .
id=$(docker create ndrvtl/emacs-gcc-pgtk)
docker cp $id:/opt/deploy .
