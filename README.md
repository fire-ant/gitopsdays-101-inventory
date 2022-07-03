## GitOps101-backend

During GitOpsDays2022 Weaveworks ran a [GitOps101](https://github.com/kubernetes101/gitopsdays) course which leveraged [GitHub Codespaces](https://github.com/features/codespaces).

This course is great but unfortunately has a hard requirement in that you need to sign up for codespaces and that might not be accessible for everyone. This is an effort to give organisations the capability to reuse the course but on their own infrastructure. It is not designed to provide a production level development platform (HA, durable, recoverable etc) and comes with no guarantees that it will work in all circumstances.

GitOps101-backend was born of the need to provide a multitenant development platform which can be:

- centralised: easier to run/maintain
- colocated: deployed on private/internal infrastructure
- consistent: each 'tenant' gets an identical base image with minimal tooling (git, docker)
- reliable: hard isolation and performance guarantees through the use of microvms
- secure: each tenant provides only a public key and their identifier. only they can log into their environment ensuring anything they use (secrets,  env vars) stay with them

GitOps101-backend leverages [Weaveworks Ignite](https://github.com/weaveworks/ignite) with the ignite/firecracker backend providing virtualised environments per developer/tenant.

### development requirements:

- [vagrant](https://www.vagrantup.com)
- [virtualbox](https://www.virtualbox.org)

### production requirements

- A KVM capable Linux Host (build and tested on Ubuntu 20.04 and 22.04, ymmv)
- An internally routable host IP. The host will port-forward each micro-vm's SSH ip
- VScode installed locally withthe Remote-SSH and Remote-Container Extensions enabled.
- An account with the Git Provider of your choice (Github,Gitlab etc)

### development demo
install [vagrant](https://www.vagrantup.com) 

get a developer environment up and running with
```
vagrant up
```
in the root of this repository.

#### repo

the local repository is mounted in the vagrant VM so you can either run the commands after ```vagrant ssh``` or open two terminals, one local and one to stream logs.

to setup a micro-vm run:
```
./template.sh -k $PWD/id_rsa.pub -i cdl
```

where `-k $PWD/id_rsa.pub` is pointing to the absolute path of your SSH public key and `-i cdl` is supplying an identifier you can correlate to your configuration later.

running this command recursively will create more vm entries under [manifests/](manifests/). you dont have to but it may be easier to add the .ssh/config entry. Otherwise remember these details and use them to test SSH login later.

to see how the template script works run:
```
./template.sh -h
```
to start the ignited daemon on the vagrant host:
```
vagrant ssh -c "sudo ignited daemon --ignite-config /etc/ignite/config.yaml --log-level debug"
```

Once reconciled (this shouldnt take longer than 30 seconds), you should be able to test the ssh login for the micro-vm. If this is running on your local workstation you should be able to do something like ```ssh root@127.0.0.1 -p 600** -i <YOUR_PRIVATE_KEY>``` noting the port is going to land between 60000-60100 and was published as part of the ```template.sh``` output earlier.

If you'd like to remove vms you can run the following to clean up the host and the local directory:
```
vagrant ssh -c "export NAME=your-vm; sudo ignite stop $NAME -f && sudo ignite rm $NAME"
rm -rf ./manifests/vm-*
```
### production demo

TODO

### APPENDIX:

if you'd like to extend this idea these are the two most useful and pertinent confgiuration documents Ive found

[ignite-configuration](https://github.com/weaveworks/ignite/blob/main/docs/ignite-configuration.md)
[vm-config](https://github.com/weaveworks/ignite/blob/main/docs/declarative-config.md)
