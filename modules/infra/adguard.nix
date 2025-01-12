{ config, ... }:
{
  mySystemApps.adguardhome.customMappings =
    config.myInfra.domains
    // builtins.listToAttrs (
      builtins.map
        (name: {
          name = config.myInfra.machines."${name}".host;
          value = config.myInfra.machines."${name}".ip;
        })
        (
          builtins.filter (name: config.myInfra.machines."${name}".host != null) (
            builtins.attrNames config.myInfra.machines
          )
        )
    );
}
