{
  lib,
  pkgs,
  version,
  modDirVersion,
  kernelArch,
  crossCompile,
}:

let
  installkernel = pkgs.writeShellScriptBin "installkernel" ''
    cp -av $2 $4
    cp -av $3 $4
  '';

  src = lib.cleanSourceWith {
    src = ../..;
    # Remove all Nix build outputs symlinked as `result*` from the source
    # otherwise, the Nix store will fill up faster
    filter =
      path: type:
      let
        baseName = baseNameOf (toString path);
      in
      !(lib.hasSuffix ".qcow2" baseName || (type == "symlink" && lib.hasPrefix "result" baseName));
  };
in

(pkgs.linuxManualConfig {
  inherit version modDirVersion src;
  # The user must build a `$(srctree)/.config` file for any
  # `make` targets to realize. Use that config file.
  configfile = pkgs.runCommand "kernel-config" { } ''
    cp ${src}/.config $out
  '';
  allowImportFromDerivation = true;
}).overrideAttrs
  (oldAttrs: {
    dontBuild = true;
    dontConfigure = true;
    dontStrip = true;

    preInstall = ''
      installFlags+=("-j$NIX_BUILD_CORES")
      export HOME=${installkernel}
    '';

    installPhase = ''
      runHook preInstall

      export CROSS_COMPILE=${crossCompile}
      export ARCH=${kernelArch}

      #make INSTALL_DTBS_PATH=${placeholder "out"}/dtbs dtbs_install # DTBs aren't needed in a VM
      make INSTALL_MOD_PATH=${placeholder "modules"} modules_install
      make INSTALL_PATH=${placeholder "out"} install

      rm -f $modules/lib/modules/${modDirVersion}/build
    '';
  })
