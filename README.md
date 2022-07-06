## GitOps101-inventory

During GitOpsDays2022 Weaveworks ran a [GitOps101](https://github.com/kubernetes101/gitopsdays) course which leveraged [GitHub Codespaces](https://github.com/features/codespaces).

This is the example inventory for a multitenant instance which can self-host codespaces. The accomplanying backend can be found in [GitOps101-backend](https://github.com/fire-ant/gitopsdays-101-backend)

GitOps101-backend leverages [Weaveworks Ignite](https://github.com/weaveworks/ignite) with the ignite/firecracker backend providing virtualised environments per developer/tenant.

### development requirements:

set up a development or production backend per [GitOps101-backend](https://github.com/fire-ant/gitopsdays-101-backend)

#### inventory setup

to see how the template script works run:
```
./vmctl -h
```

to setup a micro-vm run:
```
./vmctl -t blue -k $PWD/id_rsa.pub -i cdl
```

where `-k $PWD/id_rsa.pub` is pointing to the absolute path of your SSH public key, `-t blue` is pointing to your 'team' directory  and `-i cdl` is supplying an identifier you can correlate to your configuration later.

running this command recursively will create more vm entries under [manifests/](manifests/). you dont have to but it may be easier to add the .ssh/config entry. Otherwise remember these details and use them to test SSH login later. the command will provide an ssh config entry to be reused (though this is invasive so it is not automatic).

to disable an environment use something like:

```
./vmctl -t blue -i cdk -k $PWD/id_rsa.pub -c delete
```

which will set the running status of the given instance to `false`, shutting it down.

!!!NOTE - do not attempt to remove the vm entry as this will hang ignited daemon!!!

Once reconciled (this shouldnt take longer than 30 seconds), you should be able to test the ssh login for the micro-vm. If this is running on your local workstation you should be able to do something like ```ssh root@127.0.0.1 -p 600** -i <YOUR_PRIVATE_KEY>``` noting the port is going to land between 60000-60100 and was published as part of the ```vmctl``` output earlier.

### APPENDIX:

if you'd like to extend this idea these are the two most useful and pertinent confgiuration documents Ive found

[ignite-configuration](https://github.com/weaveworks/ignite/blob/main/docs/ignite-configuration.md)
[vm-config](https://github.com/weaveworks/ignite/blob/main/docs/declarative-config.md)
