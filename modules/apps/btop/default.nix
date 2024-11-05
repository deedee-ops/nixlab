{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.btop;
in
{
  options.myHomeApps.btop = {
    enable = lib.mkEnableOption "btop" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.targets.btop.enable = true;

    home.shellAliases = {
      htop = "btop";
      top = "btop";
    };

    programs.btop = {
      enable = true;
      package = pkgs.btop.override { cudaSupport = osConfig.hardware.nvidia.modesetting.enable; };

      settings = {
        # general
        truecolor = true;
        force_tty = false;
        vim_keys = true;
        shown_boxes = "cpu mem net proc";
        update_ms = 2000;
        rounded_corners = true;
        graph_symbol = "braille";
        clock_format = "%X";
        base_10_sizes = false;
        background_update = true;
        show_battery = true;
        selected_battery = "Auto";
        show_battery_watts = true;
        log_level = "WARNING";

        # cpu
        cpu_bottom = false;
        graph_symbol_cpu = "default";
        cpu_graph_upper = "user";
        cpu_graph_lower = "total";
        cpu_invert_lower = false;
        cpu_single_graph = false;
        show_gpu_info = "On";
        check_temp = true;
        cpu_sensor = "Auto";
        show_coretemp = true;
        temp_scale = "celsius";
        show_cpu_freq = true;
        custom_cpu_name = "";
        show_uptime = true;

        # gpu
        nvml_measure_pcie_speeds = true;
        graph_symbol_gpu = "default";
        gpu_mirror_graph = true;

        # mem
        mem_below_net = false;
        graph_symbol_mem = "default";
        mem_graphs = false;
        show_disks = true;
        show_io_stat = true;
        io_mode = false;
        io_graph_combined = false;
        io_graph_speeds = "";
        show_swap = false;
        swap_disk = true;
        only_physical = true;
        use_fstab = true;
        zfs_hide_datasets = false;
        disk_free_priv = false;
        disks_filter = "";
        zfs_arc_cached = true;

        # net
        graph_symbol_net = "default";
        net_download = 100;
        net_upload = 100;
        net_auto = true;
        net_sync = true;
        net_iface = "";

        # proc
        proc_left = false;
        graph_symbol_proc = "default";
        proc_sorting = "cpu direct";
        proc_reversed = false;
        proc_tree = false;
        proc_aggregate = false;
        proc_colors = true;
        proc_gradient = true;
        proc_per_core = false;
        proc_mem_bytes = true;
        proc_cpu_graphs = false;
        proc_filter_kernel = true;
        proc_info_smaps = false;
      };
    };
  };
}
