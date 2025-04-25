
VAGRANTFILE_API_VERSION = "2"

$wait_script = <<-SCRIPT
echo "Wait 2 mins to start container registry"
sleep 120
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.define "dev-k8s" do |microk8s|
        microk8s.vm.box = "ubuntu/focal64"
        microk8s.vm.hostname = "dev-k8s"
        microk8s.vm.network "private_network", ip: "192.168.33.44"

        microk8s.vm.provider "virtualbox" do |vb, override|
            vb.name = "dev-k8s"
            vb.memory = 6144
            vb.cpus = 2

            override.vm.synced_folder ".", "/vagrant"
        end
        microk8s.vm.provision "shell", path: "./script/prepare-dev-k8s.sh"
    end

end
