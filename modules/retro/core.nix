{ lib, ... }:
{
  options.myRetro = {
    core = {
      savesDir = lib.mkOption {
        type = lib.types.str;
        description = "Directory where saves will be stored.";
      };
      screenWidth = lib.mkOption {
        type = lib.types.int;
        description = "Fullscreen width.";
        default = 1920;
      };
      screenHeight = lib.mkOption {
        type = lib.types.int;
        description = "Fullscreen height.";
        default = 1080;
      };
    };
  };

  config = { };
}
