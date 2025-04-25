#!/bin/bash

sed -i'' 's@application/zip@application/x-cbz@g' /app/calibre-web/cps/__init__.py
