{
    description = "Nomad+Consul lab infrastructure";

    inputs = {
        nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    };

    outputs = { self, nixpkgs }:
		let
			pkgs = import nixpkgs;
            system = "x86_64-linux";
            withDefaults = import ./vm-defaults.nix { inherit pkgs; };
            mkSystem = hostNixPath: nixpkgs.lib.nixosSystem {
                inherit system;
                modules = [ withDefaults (import hostNixPath) ];
            };
		in {
    		nix = {
        		package = pkgs.nixFlakes;
        		extraOptions = ''
            		experimental-features = nix-command flakes
        		'';
    		};

        	nixosConfigurations = {
            	leader = mkSystem ./hosts/leader.nix;

            	follower-a = mkSystem ./hosts/follower-a.nix;
            	follower-b = mkSystem ./hosts/follower-b.nix;

            	worker-a = mkSystem ./hosts/worker-a.nix;
            	worker-b = mkSystem ./hosts/worker-b.nix;
        	};
		};
}
