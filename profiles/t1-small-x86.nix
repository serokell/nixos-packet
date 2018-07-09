{
  hardware.enableAllFirmware = true;
  nixpkgs.config.allowUnfree = true;

  boot.initrd.availableKernelModules = [
    "ehci_pci" "ahci" "usbhid" "sd_mod"
  ];

  boot.kernelModules = [ "kvm-intel" ];

  nix.maxJobs = 4;
}
