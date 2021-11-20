#! /system/bin/sh

if [ -d /persist/factory/regulatory ]; then
  # upgrade products PATH
  SRC_PATH="/persist/factory/regulatory"
elif [ -d /mnt/product/persist/elabel ]; then
  # NPI products PATH
  SRC_PATH="/mnt/product/persist/elabel"
fi

# make sure source directory exists
if [ -d $SRC_PATH ]; then
        # check if source folder is empty, then nothing to copy
        if [ ! -z "$(ls -A $SRC_PATH)" ]; then
                 if [ ! -f /data/misc/elabel/elabels_copied ]; then
                        cp "$SRC_PATH"/* /data/misc/elabel/
                        echo 1 > /data/misc/elabel/elabels_copied
                        chown system.system /data/misc/elabel/*
                        chmod 444 /data/misc/elabel/*
                 fi
        fi
fi
