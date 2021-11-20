#!/system/bin/sh

scriptname=${0##*/}
notice() {
	echo "$*"
	echo "$scriptname: $*" > /dev/kmsg
}

# App compactor reclaims background apps without killing them,
# so it significantly reduces the app kills. As it also increases the swap,
# so far we only enable it on device with 6G ram and lower device.
set_app_compactor() {
    if [ "$1" == "1" ]; then
        notice "enable app compactor"
        device_config put activity_manager use_compaction true
        device_config put activity_manager compact_action_1 4
        device_config put activity_manager compact_action_2 2
    elif [ "$1" == "0" ]; then
        notice "disable app compactor"
        device_config put activity_manager use_compaction false
    fi
}

# We have too much cache level apps after Android Q due to background
# execute restrictions, tune the max_cached_processes to balance the am_kills
# and performance. Please note: below max_cahced_processes config will
# override the ro.MAX_HIDDEN_APPS.
set_max_cached_processes() {
    notice "set max_cached_processes to $1"
    device_config put activity_manager max_cached_processes $1
}

product=`getprop ro.product.name`
mem_total_string=`cat /proc/meminfo | grep MemTotal`
mem_total=$((${mem_total_string:16:8}/1024))
tuning_params=$1
app_compactor="default"
max_cached_processes="default"

notice "Moto System tuning: product:$product, memory:${mem_total}M, tuning:$tuning_params"

# Get parameters from prop
if [ "$tuning_params" != "" ] && [ "$tuning_params" != "default" ]; then
    params=$(echo $tuning_params | tr "," "\n")
    for param in $params
    do
        if [[ "$param" == compact* ]]; then
            app_compactor=${param##*=}
        fi
        if [[ "$param" == bgapps* ]]; then
            max_cached_processes=${param##*=}
        fi
    done
fi

# Tune the system based on parameters
if [ "$app_compactor" == "default" ]; then
    if [ $mem_total -le 6144 ]; then # <=6G
        set_app_compactor 1
    fi
else
    set_app_compactor $app_compactor
fi

if [ "$max_cached_processes" == "default" ]; then
    if [ $mem_total -le 2048 ]; then # <=2G
        set_max_cached_processes 28
    elif [ $mem_total -le 4096 ]; then # 3G~4G
        set_max_cached_processes 32
    elif [ $mem_total -le 6114 ]; then # 4G~6G
        set_max_cached_processes 40
    elif [ $mem_total -le 8192 ]; then # 6G~8G
        set_max_cached_processes 48
    elif [ $mem_total -le 10240 ]; then # 8G~10G
        set_max_cached_processes 56
    else
        set_max_cached_processes 60
    fi
else
    set_max_cached_processes $max_cached_processes
fi
