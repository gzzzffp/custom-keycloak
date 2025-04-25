#!/bin/bash

# package verification
# verify skaffold
SKAFFOLD_VERSION=v2.1.0
CORRECT_SKAFFOLD_HASH=39f99951a97f3a4b5e8410487d5b86cc63ce5359
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/${SKAFFOLD_VERSION}/skaffold-linux-amd64
DOWNLOAD_SKAFFOLD_HASH="$(sha1sum skaffold | cut -f 1 -d ' ')"

if [ "$CORRECT_SKAFFOLD_HASH" != "$DOWNLOAD_SKAFFOLD_HASH" ]; then
  echo "The downloaded skaffold installer is not the correct file."
  exit 1
fi

# Verify release key
UBUNTU_VERSION_ID=20.04
CORRECT_RELEASE_KEY_HASH=eb6243b9215fb0272ceab3b6b42ae3f8a9f20aae

curl -Lo Release.key "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${UBUNTU_VERSION_ID}/Release.key"
DOWNLOAD_RELEASE_KEY_HASH="$(sha1sum Release.key | cut -f 1 -d ' ')"

if [ "$CORRECT_RELEASE_KEY_HASH" != "$DOWNLOAD_RELEASE_KEY_HASH" ]; then
  echo "The downloaded release key for podman is not the correct file."
  exit 1
fi

# Verify maven package
MAVEN_VERSION=3.8.7
CORRECT_MAVEN_HASH=38df5b5248c2cf7ec86f981a0290396742a84c34
wget https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${MAVEN_VERSION}/apache-maven-${MAVEN_VERSION}-bin.tar.gz

DOWNLOAD_MAVEN_HASH="$(sha1sum apache-maven-${MAVEN_VERSION}-bin.tar.gz | cut -f 1 -d ' ')"

if [ "$CORRECT_MAVEN_HASH" != "$DOWNLOAD_MAVEN_HASH" ]; then
  echo "The downloaded maven installer is not the correct file."
  exit 1
fi

# Add root CA certificate
# cp /vagrant/certs/ROOTCA-CA.crt /usr/local/share/ca-certificates
# update-ca-certificates

# Configure hosts
echo "10.10.16.16 db-nexus-01.dreambroker.local" >> /etc/hosts

# Use internal nexus apt repositories
sed -i 's#http://archive.ubuntu.com/ubuntu #https://db-nexus-01.dreambroker.local/repository/ubuntu-focal/ #g' /etc/apt/sources.list
sed -i 's#http://security.ubuntu.com/ubuntu #https://db-nexus-01.dreambroker.local/repository/ubuntu-focal/ #g' /etc/apt/sources.list
apt update

echo "----------------------------------------"
echo " Installing microk8s and all components "
echo "----------------------------------------"

# Install microk8s

snap install microk8s --classic
microk8s enable ingress registry dns host-access

usermod -a -G microk8s vagrant

microk8s stop
microk8s start

snap install kubectl --classic
snap install helm --classic

# Install skaffold
install skaffold /usr/local/bin/
echo "skaffold installation is done. Version is below."
skaffold version

#Making cluster configuration available for all required users
mkdir /home/vagrant/.kube
microk8s.kubectl config view --raw > /home/vagrant/.kube/config
chmod 600 /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

microk8s.kubectl config view --raw > /root/.kube/config
chmod 600 /root/.kube/config


# Install podman
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${UBUNTU_VERSION_ID}/ /" | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
apt-key add Release.key
rm Release.key

apt update
apt -y install podman
echo "podman installation is done. Version below"
podman --version

# configure containers registry
cp /vagrant/config/podman/registries.conf /etc/containers/registries.conf

# configure containers auth
mkdir /home/vagrant/.docker
# cp /vagrant/config/podman/auth.json /home/vagrant/.docker/config.json

service podman restart

# Install mysql server and client
apt -y install mysql-server-8.0 mysql-client-core-8.0
# microk8s 'host-access' makes it possible for the pods to access the server using 10.0.1.1:3306
# Change bind so that K8s pods and the developer (host to VM) can connect to the server
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart
while ! mysqladmin ping -u root ; do sleep 2; done && mysql -u root < /vagrant/script/mysql-init-databases-and-users.sql

#jdk17 installation
apt -y install openjdk-17-jdk-headless
java -version
echo "jdk 17 Installed-----"

#Maven installation
tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz -C  /opt/
mv /opt/apache-maven-${MAVEN_VERSION} /opt/maven
echo "export M2_HOME=/opt/maven" >> /home/vagrant/.profile
echo "export MAVEN_HOME=/opt/maven" >> /home/vagrant/.profile
echo -e "export PATH=\${M2_HOME}/bin:\${PATH}" >> /home/vagrant/.profile

export PATH=/opt/maven/bin:${PATH}

echo "maven installation is done. Version is below."
mvn -version

# configure maven auth
mkdir -p /home/vagrant/.m2
chown -R vagrant:vagrant /home/vagrant/.m2
timedatectl set-ntp true
