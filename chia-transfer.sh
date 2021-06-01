#!/bin/bash

CONF_FILE="/home/$USER/.config/chia-transfer/config";
FILE_TYPE="";
# TODO define the actual K32 size 108644374730 (arch iso is 792014848, image will be 20000)
K32=792014848;

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

for targetDrive in "${TARGET[@]}";
do
    if [ ! -d "$targetDrive" ]; then
        echo "The target drive you provided [$targetDrive] doesn't exist!";
        echo "Exiting...";
        exit 1;
    fi
done

# Parse files on source dir to an array, excluding files that contain '.tmp' in their file names
FILES=($(ls $SRC | grep ".tmp" -v | grep $FILE_TYPE))

tmp="${FILES[@]}"
if [ -z "$tmp" ]; then
    echo "There are no files to move... exiting with code 0...";
    exit 0;
fi

# Log the moveable files
echo "There are moveable files: $tmp";

# Create pending dirs if they don't exist
if [ ! -d "/home/$USER/.cache/chia-transfer" ]; then mkdir "/home/$USER/.cache/chia-transfer"; fi
if [ ! -d "/home/$USER/.cache/chia-transfer/files" ]; then mkdir "/home/$USER/.cache/chia-transfer/files"; fi
if [ ! -d "/home/$USER/.cache/chia-transfer/drives" ]; then mkdir "/home/$USER/.cache/chia-transfer/drives"; fi

checkPendingFiles() {
    # Get pending moveable files if there are any (files that are already being transferred)
    PENDING=($(ls /home/$USER/.cache/chia-transfer/files/));

    ISMOVING=false
    for pendingfile in "${PENDING[@]}"; do
        if [ "$pendingfile" == "$1" ]; then
            # If the filename matches a pending filename, then skip the moving process
            ISMOVING=true
            break;
        fi
    done
}

checkPendingDrives() {
    # Get pending drives that being moved to
    USEDDRIVES=($(ls /home/$USER/.cache/chia-transfer/drives/));

    ISDRIVEUSED=false
    for pendingDrive in "${USEDDRIVES[@]}"; do
        if [ "${pendingDrive//\//"_"}" == "$1" ]; then
            ISDRIVEUSED=true
            break;
        fi
    done
}

getDriveFreeSize() {
    freekb=$(df -P $1 | awk 'NR==2' | awk '{print $4}')
    DRIVEFREESIZE=$((freekb * 1024));
    echo -e  "Free space of $drive is $DRIVEFREESIZE bytes [$((DRIVEFREESIZE / 1024 / 1024 /1024)) GB]";
}

for file in "${FILES[@]}";
do
    FILESIZE=$(ls -l "${SRC}${file}" | cut -d " " -f 5)
    # echo "The $file is $FILESIZE bytes large.";

    if [ ! $FILESIZE -gt $K32 ] && [ ! $FILESIZE -eq $K32 ]; then
        echo "The $file is smaller than $K32 bytes, skipping...";
        continue;
    fi

    checkPendingFiles $file

    if [ $ISMOVING == true ]; then
        echo "$file is being moved, skipping...";
        continue;
    fi

    TARGET_DRIVE=""
    TARGET_DRIVE_SLUG=""

    for drive in "${TARGET[@]}"; do
        cleandrivename="${drive//\//"_"}"
        checkPendingDrives $cleandrivename
        getDriveFreeSize $drive
        if [ $DRIVEFREESIZE -gt $K32 ] && [ $ISDRIVEUSED == false ]; then
            TARGET_DRIVE="$drive";
            TARGET_DRIVE_SLUG="$cleandrivename";
        fi
    done
    

    # Create pending status for drive
    touch "/home/$USER/.cache/chia-transfer/drives/${TARGET_DRIVE_SLUG}";
    echo "Created pending status for drive ${TARGET_DRIVE}";    
    
    # Create pending status for file
    touch "/home/$USER/.cache/chia-transfer/files/${file}";
    echo "Created pending status for file ${file}";

    mv "${SRC}${file}" "${TARGET_DRIVE}";

    # Cleanup after move
    rm "/home/$USER/.cache/chia-transfer/files/${file}";
    echo "Removed pending status for file ${file}";
    rm "/home/$USER/.cache/chia-transfer/drives/${TARGET_DRIVE_SLUG}";
    echo "Removed pending status for drive ${TARGET_DRIVE}";
done

exit 0;