let
	defaults = {
    	gatewayIp = "10.2.1.1";
    	datacenter = "homelab";
    	hostBridge = "br0";
	};
in rec
{
    leader = {
        name = "leader";
        ip = "10.2.1.100";
        mac = "bc:80:00:00:00:01";
        isServer = true;
    };

    follower-a = {
        name = "follower-a";
        ip = "10.2.1.110";
        mac = "bc:80:00:00:00:02";
        isServer = true;
    };

    follower-b = {
        name = "follower-b";
        ip = "10.2.1.120";
        mac = "bc:80:00:00:00:03";
        isServer = true;
    };

    worker-a = {
        name = "worker-a";
        ip = "10.2.1.200";
        mac = "bc:80:00:00:0d:01";
        isServer = false;
    };

    worker-b = {
        name = "worker-b";
        ip = "10.2.1.210";
        mac = "bc:80:00:00:0d:02";
        isServer = false;
    };

    etc-hosts = let
    	mkHostsLine = { host, datacenter ? defaults.datacenter }:
    		builtins.concatStringsSep " " [
        		host.ip
        		host.name
        		"${host.name}.${datacenter}.local"
    		];
    in
    	''
        	${mkHostsLine { host = leader; }}
        	${mkHostsLine { host = follower-a; }}
        	${mkHostsLine { host = follower-b; }}
        '';

	inherit defaults;

	# note: this setup only works when you have a router on the gateway ip
	# that can send traffic out of the local network segment; it probably
	# (a bridge interface on a qemu host works well for this)
	mkIfaceConfig = { host, gatewayIp ? defaults.gatewayIp }:
	{
        hostName = host.name;
        enableIPv6 = false;

        defaultGateway = {
            address = gatewayIp;
            interface = "eth0";
        };

        interfaces.eth0 = {
            ipv4.addresses = [
                {
                    address = host.ip;
                    prefixLength = 24;
                }
            ];
            ipv4.routes = [
                {
                    address = "0.0.0.0";
                    prefixLength = 0;
                }
            ];
        };
    };

    mkNomadConfig = { host, joinIps, datacenter ? defaults.datacenter }:
		let
			serverBlock = if host.isServer then {
                advertise = {
                    http = host.ip;
                    rpc  = host.ip;
                    serf = host.ip;
                };
                server = {
                    enabled = true;
                    server_join = {
                        retry_join = joinIps;
                        retry_interval = "30s";
                        retry_max = "20";
                    };
                };
    		} else {
        		client = {
            		enabled = true;
            		servers = joinIps;
        		};
    		};
		in
        {
            enable = true;
            settings = {
                datacenter = datacenter;

                consul = {
                    address = "${host.ip}:8500";
                };
            } // serverBlock;
        };

    mkConsulConfig = { host, joinIps, datacenter ? defaults.datacenter }:
    {
        enable = true;
        webUi = true;

        extraConfig = {
            datacenter = datacenter;

            advertise_addr = host.ip;
            server = host.isServer;

            retry_join = joinIps;
        };
    };

    mkVirtConfig = { host, hostBridge ? defaults.hostBridge }:
    {
        graphics = false;
        memorySize = if host.isServer then 2048 else 4096;
        diskSize = 2000;
        cores = if host.isServer then 2 else 4;

        qemu = {
            networkingOptions = [
                "-nic bridge,br=${hostBridge},mac=${host.mac}"
            ];
            guestAgent.enable = true;
        };
    };
}
