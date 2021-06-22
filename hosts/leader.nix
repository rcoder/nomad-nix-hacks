{ self, pkgs, nixpkgs, ... }:
let
	nc = import ../netconf.nix;
	host = nc.leader;
	joinIps = [ nc.follower-a.ip nc.follower-b.ip ];
in {
    networking = nc.mkIfaceConfig { inherit host; };

	virtualisation = nc.mkVirtConfig { inherit host; };

	services.nomad = let
		nomadConf = nc.mkNomadConfig {
    		inherit host;
    		joinIps = joinIps;
		};
		settings = nomadConf.settings;
	in
		nomadConf // {
    		settings = settings // {
        		server = settings.server // {
            		bootstrap_expect = 1;
        		};
    		};
		};

	services.consul = let
		consulConf = nc.mkConsulConfig {
        	inherit host;
        	joinIps = joinIps;
    	};
    	extraOpts = consulConf.extraConfig;
    in consulConf // {
        extraConfig = extraOpts // {
            bootstrap = true;
        };
	};
}
