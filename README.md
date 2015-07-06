# boot2docker-nfs
a vagrantfile that makes an nfs-enabled boot2docker machine

This is based almost entirely off of [blinkreaction/boot2docker-vagrant](https://github.com/blinkreaction/boot2docker-vagrant/). I have just removed things that I didn't need and added the ability to expose ports through the config file.

To use: copy `Vagrantfile` and `vagrant.yml` to your workspace that has subdirectories of projects that use Docker. Then run `vagrant up` to start up a virtual Docker machine.

I've set `export DOCKER_HOST=tcp://localhost:2375` in my `.bash_profile`, which means I can run `docker` commands from any new terminal I open.

Any port listed under `ports` in `vagrant.yml` will be accessible at `localhost:<port>`.
