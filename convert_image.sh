#!/bin/bash

###########################################################
#
# Author: noirmurir
# Sending_Grounds Bash Scripting Challenge
#
# Shell frontend that processes the filenames and calls
# the correct conversion utilities.
# Optionally we can change the size of the resulting image,
# place a colored border around an image
# NetPBM utilities are used in this script to 
# work with the images.
#
# Requirements:
# - Catches signals
# - Has a help/usage statement
# - Uses named Exit codes
# - Has arg parsing
# - Posts it to this repo here
# - and the script of course works
# 
###########################################################

# Named exit codes
EXIT_SUCCESS=0
EXIT_INVALID_ARGS=1
EXIT_SIGNAL_RECEIVED=2

# Print help/usage
usage() {
cat<<EOF
Usage: $0 [-S] [-s N] [-w N] [-c S] imagefile...

Options:
  -S          Change sharpness of a resulting image
  -s N        Change size of a resulting image
  -w N        Change width of a border of a resulting image
  -c S        Change color of a border of a resulting image
  -h          Show help/usage
EOF
}

handle_signals() {
    echo "Recieved signal - Exiting gracefully..."
    exit $EXIT_SIGNAL_RECEIVED
}

# Main function serving as entrypoint
main() {
    # Trap signals
    trap 'handle_signals' SIGINT SIGTERM

    # Set up default width and color
    width=1
    colour='-color grey'

    # Initialise the pipeline components
    standardise=' | pnmtojpeg -quiet'

    # Parse arguments
    while getopts ":Ss:w:c:h" opt; do
        case $opt in
          S  ) sharpness=' | pnmnlfilt -0.7 0.45' ;;

          s  ) size=$OPTARG
               scale=' | pnmscale -quiet -xysize $size $size' ;;

          w  ) width=$OPTARG
               border=' | pnmmargin $colour $width' ;;

          c  ) colour="-color $OPTARG"
               border=' | pnmmargin $colour $width' ;;

          h  ) usage
               exit $EXIT_SUCCESS ;;

          *  ) echo $usage
               exit 1 ;;
        esac
    done


    shift $(($OPTIND - 1))

    # Check at least one image is provided
    if [ -z "$@" ]; then
        usage
        exit $EXIT_INVALID_ARGS
    fi


    # Process the input files
    for filename in "$@"; do
        case $filename in
            *.gif ) convert='giftopnm'  ;;

            *.tga ) convert='tgatoppm'  ;;

            *.xpm ) convert='xpmtoppm'  ;;

            *.pcx ) convert='pcxtoppm'  ;;

            *.tif ) convert='tifftopnm'  ;;

            *.jpg ) convert='jpegtopnm -quiet' ;;

                * ) echo "$0: Unknown filetype '${filename##*.}'"
                    exit 1;;
        esac

        outfile=${filename%.*}.new.jpg

        eval $convert $filename $scale $border $sharpness $standardise > $outfile

    done
}

main $@
