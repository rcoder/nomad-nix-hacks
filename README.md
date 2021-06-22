# Some Nomad/NixOS ideas

This is very, very rough and I'm very, very new to Nix.

That being said, with minimal setup work it lets me create a three-server/two-client Nomad cluster to run in local Qemu VMs. It's handy for that alone, and there's definitely more to try around cluster security, plus the oh-so-promising `nixos-rebuild --target-host` option to push a generated config to a live server.

Aside from a NixOS box to run this on, you'll need `just` (it's a Rust program, so you can install it via cargo or from nixpkgs) and a few bits in your system `configuration.nix`:

```
    imports = [
    	# ...
    	<nixos-unstable/nixos/modules/virtualisation/qemu-vm.nix>
    ];

    disabledModules = [
        "virtualisation/qemu-vm.nix"    
    ];
    
    /*
      ^-- The above is a weird dance needed to make sure the guest vm
          quota options used below are available. it's probably a bad
          workaround for my not really knowing Nix.
    */
    
    boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
    };
    
    /*
      We're not actually using `libvirtd`, but NixOS only populates
      the ACL file which allows qemu to dynamically manage virtual NICs.
    */
    virtualisation.libvirtd = {
        enable = true;
        qemuPackage = pkgs.qemu_kvm;
        allowedBridges = [ "virbr0" "br0" ];
    };
    
    networking = {
        bridges.br0.interfaces = [];
        interfaces.br0 = {
            ipv4.addresses = [{ address = "10.2.1.1"; prefixLength = 24; }];
            ipv4.routes = [{ address = "10.2.1.0"; prefixLength = 24; }];
        };
        
        nat = {
            enable = true;
            internalInterfaces = [ "br0" ];
            externalInterface = [
                # your actual NIC here; probably "eth0" if NixOS itself
                # is running in a VM
            ];
        };
    };
```

> Note: the above can and should share configuration with this VM building
> module; I just haven't gotten around to it yet.

With all that in place: `just check` lints the config, and `just` applies it.
