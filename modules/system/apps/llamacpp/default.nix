{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.llamacpp;
in
{
  options.mySystemApps.llamacpp = {
    enable = lib.mkEnableOption "llamacpp";
    enableCUDA = lib.mkEnableOption "NVIDIA CUDA";
    enableROCm = lib.mkEnableOption "AMD ROCm";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.llama-cpp.override {
        cudaSupport = cfg.enableCUDA;
        rocmSupport = cfg.enableROCm;
      })
    ];
  };
}
