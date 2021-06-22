logfile := "build-vms.log"

# rebuild all VMs by default
default: prep leader follower-a follower-b worker-a worker-b
	true

# reset state and verify the flake
prep:
	rm -f {{ logfile }}
	rm -f *.qcow2
	just check

check:
	nix flake check --impure .

build host:
	nixos-rebuild --impure --flake .#{{ host }} build-vm 2>&1 | tee -a {{ logfile }}

leader:
	just build leader

follower-a:
	just build follower-a

follower-b:
	just build follower-b

worker-a:
	just build worker-a

worker-b:
	just build worker-b
