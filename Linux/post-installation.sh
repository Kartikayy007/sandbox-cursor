docker exec -u 0 -it cursor-instance bash
apt update
apt install -y sudo
usermod -aG sudo cursoruser
echo "cursoruser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/cursoruser

