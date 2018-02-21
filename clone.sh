#!/bin/bash
set -e

URL=https://kubernetes-charts.storage.googleapis.com/index.yaml

mkdir -p charts
cd charts

download_image()
{
    HASH=$(echo $ICON | sha256sum - | awk '{print $1}')
    if [ ! -e images/$HASH ]; then
        IMGTMP=$(mktemp)
        mkdir -p images
        echo Downloading $ICON
        curl -sL $ICON > $IMGTMP
        mv $IMGTMP images/$HASH
    fi
    ln -s ../../images/$HASH $TMP/$(basename $ICON)
}

while read DIGEST TGZ ICON; do
    PREFIX=${DIGEST:0:2}
    FOLDER=${PREFIX}/${DIGEST}
    if [ -d $FOLDER ]; then
        continue
    fi

    TMP=$(mktemp -d -p .)
    trap "rm -rf $TMP" exit

    echo Downloading $TGZ
    curl -sfL $TGZ | tar xzf - -C $TMP
    if [ -n "$ICON" ] && [ "$ICON" != "null" ]; then
        download_image
    fi

    mkdir -p $PREFIX
    mv $TMP $FOLDER
    rm -rf $TMP
done < <(curl -sfL $URL | ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' | jq -r '.entries[][]|"\(.digest) \(.urls[0]) \(.icon)"')
