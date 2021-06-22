{ self, pkgs, nixpkgs, ... }:
let
	nc = import ../netconf.nix;
	host = nc.follower-b;
	joinIps = [ nc.leader.ip nc.follower-a.ip ];
in {
    networking = nc.mkIfaceConfig { inherit host; };

	virtualisation = nc.mkVirtConfig { inherit host; };

	services.nomad = nc.mkNomadConfig { inherit host joinIps; };
	services.consul = nc.mkConsulConfig { inherit host joinIps; };
}
