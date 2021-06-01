#!/bin/bash

# Download file
wget -O chia-transfer.sh https://www.dropbox.com/s/zp3vlmeh1qrnjz4/chia-transfer.sh?dl=1

# Make it executable
chmod u+x chia-transfer.sh

# Move it to the local user binaries
sudo mv chia-transfer.sh /usr/local/bin/chia-transfer.sh

# Create a wrapper script on the desktop that will execute chia-transfer.sh with watch
echo -e "#!/bin/bash\nwatch -b -e -n 60 chia-transfer.sh\n" > /home/$USER/Desktop/ChiaTransfer.sh

# Make that script executable
chmod u+x /home/$USER/Desktop/ChiaTransfer.sh
