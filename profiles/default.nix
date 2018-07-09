{ pkgs, ... }:

{
  boot.kernelModules = [ "dm_multipath" "dm_round_robin" "ipmi_watchdog" ];
  boot.kernelParams = [ "console=ttyS1,115200n8" ];

  environment.systemPackages = with pkgs; [ btrfs-progs ];
}
