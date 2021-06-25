{ pkgs }:
{
    fileSystems."/".device = "/dev/disk/by-label/nixos";

    # this is a silly dance to make sure the guest vms can have normal
    # cpu/memory/core limits applied
    # ref: https://github.com/NixOS/nixpkgs/issues/41212
    disabledModules = [ "virtualisation/qemu-vm.nix" ];

    imports = [
        <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>
    ];

    nix = { autoOptimiseStore = true; };

    networking = {
        extraHosts = (import ./netconf.nix).etc-hosts;
        nameservers = [ "1.1.1.1" ];

        firewall = {
            allowedTCPPorts = [ 22 4646 4647 4648 8301 8500 8600 ];
            allowedUDPPorts = [ 53 4648 8600 51820 ];
        };
    };

    zramSwap = {
        enable = true;
        memoryMax = 1024;
    };

    services.openssh = {
        enable = true;
        permitRootLogin = "yes";
    };

    environment.systemPackages = with (import <nixpkgs> {}); [
        vim dnsutils inetutils
        nomad consul
    ];

    users = {
        mutableUsers = false;
        users.root = {
            openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+qqEA50O+QWFi/286Sdp2P4138GQLLF2Jkr3t/SjNLwm lennon@seed"
            ];
            password = "hack the planet!";
        };
    };

    system.stateVersion = "21.05";
}
