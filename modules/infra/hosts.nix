{ config, ... }:
{
  mySystem.networking.extraHosts = builtins.concatStringsSep "\n" (
    builtins.map
      (name: "${config.myInfra.machines."${name}".ip} ${config.myInfra.machines."${name}".host}")
      (
        builtins.filter (name: config.myInfra.machines."${name}".host != null) (
          builtins.attrNames config.myInfra.machines
        )
      )
  );
}
