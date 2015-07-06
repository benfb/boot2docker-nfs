# UI Object for console interactions.
@ui = Vagrant::UI::Colored.new

# Install required plugins if not present.
required_plugins = %w(vagrant-triggers)
required_plugins.each do |plugin|
  need_restart = false
  unless Vagrant.has_plugin? plugin
    system "vagrant plugin install #{plugin}"
    need_restart = true
  end
  exec "vagrant #{ARGV.join(' ')}" if need_restart
end

# Determine paths.
vagrant_root = File.dirname(__FILE__)  # Vagrantfile location
vagrant_mount_point = vagrant_root.gsub(/[a-zA-Z]:/, '')  # Trim Windows drive letters.
vagrant_folder_name = File.basename(vagrant_root)  # Folder name only. Used as the SMB share name.

# Use vagrant.yml for local VM configuration overrides.
require 'yaml'
if !File.exist?(vagrant_root + '/vagrant.yml')
  @ui.error 'Configuration file not found! You need a vagrant.yml file.'
  exit
end
$vconfig = YAML::load_file(vagrant_root + '/vagrant.yml')

# Determine if we are on Windows host or not.
is_windows = Vagrant::Util::Platform.windows?

# Check if Vagrant is running as root.
running_as_root = (Process.uid == 0)

# Vagrant should NOT be run as root/admin.
if running_as_root
# || running_as_admin
  @ui.error "Vagrant should be run as a regular user to avoid issues."
  exit
end

######################################################################

# Vagrant Box Configuration #
Vagrant.require_version ">= 1.6.3"

Vagrant.configure("2") do |config|
  config.vm.define "boot2docker"

  config.vm.box = "blinkreaction/boot2docker"
  config.vm.box_version = "1.7.0"
  config.vm.box_check_update = true
  config.vm.network "forwarded_port", guest: 8080, host: 8080, protocol: 'tcp'
  ## Network ##

  # The default box private network IP is 192.168.10.10
  # Configure additional IP addresses in vagrant.yml
  # Using Intel PRO/1000 MT Server [82545EM] network adapter - shows slightly better performance compared to "virtio".
  $vconfig['hosts'].each do |host|
    config.vm.network "private_network", ip: host['ip'], nic_type: "82545EM"
  end unless $vconfig['hosts'].nil?

 ####################################################################
 ## Synced folders configuration ##

  synced_folders = $vconfig['synced_folders']
  # nfs: better performance on Mac
  if synced_folders['type'] == "nfs"  && !is_windows
    config.vm.synced_folder vagrant_root, vagrant_mount_point,
      type: "nfs",
      mount_options: ["nolock", "vers=3", "tcp"]
    config.nfs.map_uid = Process.uid
    config.nfs.map_gid = Process.gid
  # rsync: the best performance, cross-platform platform, one-way only. Run `vagrant rsync-auto` to start auto sync.
  elsif synced_folders['type'] == "rsync"
    # Only sync explicitly listed folders.
    if (synced_folders['folders']).nil?
      @ui.warn "WARNING: 'folders' list cannot be empty when using 'rsync' sync type. Please check your vagrant.yml file."
    else
      for synced_folder in synced_folders['folders'] do
        config.vm.synced_folder "#{vagrant_root}/#{synced_folder}", "#{vagrant_mount_point}/#{synced_folder}",
          type: "rsync",
          rsync__exclude: ".git/",
          rsync__args: ["--verbose", "--archive", "--delete", "-z", "--chmod=ugo=rwX"]
      end
    end
  # vboxfs: reliable, cross-platform and terribly slow performance
  else
    @ui.warn "WARNING: defaulting to the slowest folder sync option (vboxfs)"
      config.vm.synced_folder vagrant_root, vagrant_mount_point
  end

  # Make host SSH keys available to containers on /.ssh
  if File.directory?(File.expand_path("~/.ssh"))
    config.vm.synced_folder "~/.ssh", "/.ssh"
  end

  ######################################################################

  ## VirtualBox VM settings.
  
  config.vm.provider "virtualbox" do |v|
    v.gui = $vconfig['v.gui']  # Set to true for debugging. Will unhide VM's primary console screen.
    v.name = vagrant_folder_name + "_boot2docker"  # VirtualBox VM name.
    v.cpus = $vconfig['v.cpus']  # CPU settings. VirtualBox works much better with a single CPU.
    v.memory = $vconfig['v.memory']  # Memory settings.
    
    # Switch the base box NAT network adapters from "82545EM" to "virtio".
    # Default Intel adapters do not work well with docker...
    # See https://github.com/blinkreaction/boot2docker-vagrant/issues/13 for details.
    v.customize ["modifyvm", :id, "--nictype1", "virtio"]

    # Disable VirtualBox DNS proxy as it may cause issues.
    # See https://github.com/docker/machine/pull/1069
    v.customize ['modifyvm', :id, '--natdnshostresolver1', 'off']
    v.customize ['modifyvm', :id, '--natdnsproxy1', 'off']
  end

  ## Provisioning scripts ##

  # Pass vagrant_root variable to the VM and cd into the directory upon login.
  config.vm.provision "shell", run: "always" do |s|
    s.inline = <<-SCRIPT
      echo "export VAGRANT_ROOT=$1" >> /home/docker/.profile
      echo "cd $1" >> /home/docker/.bashrc
    SCRIPT
    s.args = "#{vagrant_mount_point}"
  end

end
