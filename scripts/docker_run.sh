echo 'running update in the docker env'

apt update -y;apt upgrade -y;

echo 'done update and upgrade'

apt install sudo make git
