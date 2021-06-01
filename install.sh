#!/bin/bash

wget -O chia-transfer.sh https://www.dropbox.com/s/lbu2rktn6mjoe26/chia-transfer.sh?dl=1

chmod u+x chia-transfer.sh

sudo mv chia-transfer.sh /usr/local/bin/chia-transfer.sh

echo -e "#!/bin/bash\nwatch -b -e -n 60 chia-transfer.sh\n" > /home/$USER/Desktop/ChiaTransfer.sh

chmod u+x /home/$USER/Desktop/ChiaTransfer.sh


