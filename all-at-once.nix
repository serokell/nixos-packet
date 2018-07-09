with import <nixpkgs> {};

let
  instances = lib.mapAttrsToList (n: v: "ln -s ${v} $out/${n}") (import ./.);
in
  
runCommand "packet-pxe-installers" {} ''
  mkdir -p $out
  ${lib.concatStringsSep "\n" instances}
''
