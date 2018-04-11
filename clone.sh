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

curl -sfL $URL > cached.yaml

while read CHART VERSION DIGEST TGZ ICON; do
    FOLDER=${CHART}/${VERSION}
    DIGESTFILE=${CHART}/${VERSION}/.${DIGEST}
    if [ -f $DIGESTFILE ]; then
        continue
    fi

    rm -rf $FOLDER
    mkdir -p $FOLDER
    touch $DIGESTFILE
    

    TMP=$(mktemp -d -p .)
    trap "rm -rf $TMP" exit

    echo Downloading $TGZ
    curl -sfL $TGZ | tar xzf - -C $TMP
    if [ -n "$ICON" ] && [ "$ICON" != "null" ]; then
        download_image
    fi

    mv ${TMP}/${CHART}/* $FOLDER
    rm -rf $TMP
done < <(cat cached.yaml | ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' | jq -r '.entries[][]|"\(.name) \(.version) \(.digest) \(.urls[0]) \(.icon)"')
