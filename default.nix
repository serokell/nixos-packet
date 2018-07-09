with import <nixpkgs> {};

let
  mkPXEInstaller =
  { name, system ? "x86_64-linux", kernelImage ? "bzImage", commonImports
  , runtimeImports, partition, format, mount }:
    let
      mkNixOS = import <nixpkgs/nixos>;

      runTimeNixOS = mkNixOS {
        inherit system;
        configuration = {
          imports = commonImports ++ runtimeImports;
        };
      };

      installTimeNixos = mkNixOS {
        inherit system;
        configuration = {
          imports = commonImports ++ [
            <nixpkgs/nixos/modules/installer/netboot/netboot-minimal.nix>
            ./installer.nix
            ({
              installer = {
                inherit partition format mount;
                type = "${name}-${system}";
                configFiles = commonImports ++ runtimeImports;
                runTimeNixOS = "${runTimeNixOS.system}";
              };
            })
          ];
        };
      };

      inherit (installTimeNixos.config.system) build;
    in
  
    runCommand name { passthru.system = system; } ''
      mkdir $out
      ln -s ${build.netbootRamdisk}/initrd $out/initrd
      ln -s ${build.kernel}/${kernelImage} $out/${kernelImage}
      ln -s ${build.netbootIpxeScript}/netboot.ipxe $out/netboot.ipxe
    '';

  partition = disk: ''
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${disk}
      o # clear the in memory partition table
      n # new partition
      p # primary partition
      1 # partition number 1
        # default - start at beginning of disk
        # default, extend partition to end of disk
      a # make a partition bootable
      1 # bootable partition is partition 1 -- /dev/sda1
      p # print the in-memory partition table
      w # write the partition table
      q # and we're done
    EOF
  '';
in
  
{
  c1-small-x86 = mkPXEInstaller {
    name = "c1.small.x86";

    commonImports = [
      ./profiles/default.nix
      ./profiles/c1-small-x86.nix
    ];

    runtimeImports = [
      ./profiles/post-install/default.nix
      ./profiles/post-install/c1-small-x86.nix
    ];

    partition = ''
      ${partition "/dev/sda"}
      ${partition "/dev/sdb"}
    '';

    format = "mkfs.btrfs -L root -d raid1 -m raid1 /dev/sda1 /dev/sdb1";

    mount = "mount -L root /mnt";
  };

  t1-small-x86 = mkPXEInstaller {
    name = "t1.small.x86";

    commonImports = [
      ./profiles/default.nix
      ./profiles/t1-small-x86.nix
    ];

    runtimeImports = [
      ./profiles/post-install/default.nix
      ./profiles/post-install/t1-small-x86.nix
    ];

    partition = partition "/dev/sda";
    format = "mkfs.btrfs -L root /dev/sda1";
    mount = "mount -L root /mnt";
  };
}
