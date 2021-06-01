#!/bin/bash

CONF_FILE="/home/$USER/.config/chia-transfer/config";
FILE_TYPE="";
K32=108644374730;

if [ -d "/home/$USER/.cache/chia-transfer" ]; then
    # Cleanup cache dir on fresh start
    rm -rf "/home/$USER/.cache/chia-transfer/*";
fi

# Set file type that should be moved
if [ -z "$1" ]; then FILE_TYPE=".plot"; else FILE_TYPE=".$1"; fi

# Parse config file for source and target directories
if [ -f "$CONF_FILE" ]; then
    echo "Parsing config file...";

    # Parse source into a string path
    SRC=$(cat $CONF_FILE | grep "src" | cut -d ":" -f 2);
    echo "Set source directory to [$SRC] ==> [Looking for files ($FILE_TYPE)]";

    # Parse targets into an array (reads as: except for line 'targets' and 'src', get all other lines as targets in an array)
    TARGET=($(cat $CONF_FILE | grep 'targets' -v | grep 'src' -v | cut -f 2));
    echo "Set target directories to [${TARGET[@]}]";
else
    # Create dir if it doesn't exist
    if [ ! -d "/home/$USER/.config/chia-transfer" ]; then mkdir "/home/$USER/.config/chia-transfer"; fi
    # Print help commands
    echo "You must create a config file at the [/home/$USER/.config/chia-transfer/] folder!";
    echo -e "Run the following commands: \n\n";
    echo "echo 'src:/run/media/$USER/{YOUR_SOURCE_DRIVE_COMES_HERE}' > /home/$USER/.config/chia-transfer/config";
    echo "echo -e 'targets:\n\t/run/media/$USER/TARGET_DRIVE_UUID' >> /home/$USER/.config/chia-transfer/config";
    echo "Now open the file, and replace/add your target drives after the 'targets:' line with tabs before the path.";
    echo -e "For example, a line like this: [\t/run/media/$USER/7f1f91f7-3833-45ed-af52-ba621bb98c59]";
    exit 1;
fi

# Check source dir
if [ -z "$SRC" ]; then
    echo "Failed to parse source path!";
    exit 1;
fi

# Check target dir
if [ -z "$TARGET" ]; then
    echo "Failed to parse target paths!";
    exit 1;
fi

# Parse files on source dir to an array, excluding files that contain '.tmp' in their file names
FILES=($(ls $SRC | grep ".tmp" -v | grep $FILE_TYPE))

tmp="${FILES[@]}"
if [ -z "$tmp" ]; then
    echo "There are no files to move... exiting with code 0...";
    exit 0;
fi

# Log the moveable files
echo "There are moveable files: $tmp";

# Create pending dir if it doesn't exist
if [ ! -d "/home/$USER/.cache/chia-transfer" ]; then
    mkdir "/home/$USER/.cache/chia-transfer";
fi

checkPending() {
    # Get pending moveable files if there are any (files that are already being transferred)
    PENDING=($(ls /home/$USER/.cache/chia-transfer/));

    ISMOVING=false
    for pendingfile in "${PENDING[@]}"; do
        if [ "$pendingfile" == "$1" ]; then
            # If the filename matches a pending filename, then skip the moving process
            ISMOVING=true
            break;
        fi
    done
}

for file in "${FILES[@]}";
do
    FILESIZE=$(ls -l "$SRC$file" | cut -d " " -f 5)
    # echo "The $file is $FILESIZE bytes large.";

    # TODO replace 2000 with the $K32 variable! arch iso is 792014848 bytes
    if [ ! $FILESIZE -gt 20000 ]; then
        echo "The $file is smaller than $K32 bytes, skipping...";
        continue;
    fi

    checkPending $file

    if [ $ISMOVING == true ]; then
        echo "$file is being moved, skipping...";
        continue;
    fi

    # create pending status for file
    touch "/home/$USER/.cache/chia-transfer/$file";
    echo "Created pending status for file $file";

    sleep 3;

    # cleanup after move
    rm "/home/$USER/.cache/chia-transfer/$file";
    echo "Removed pending status for file $file";
done

exit 0;