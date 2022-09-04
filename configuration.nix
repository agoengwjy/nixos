# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
{
  imports =
    [ 
      # Include the results of the hardware scan.
      # $ sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
      # $ sudo nix-channel --update
      # e.g <nixos-hardware/lenovo/thinkpad/t430>
      ./hardware-configuration.nix
    ];

  # If set, NixOS will enforce the immutability of the Nix store by making /nix/store a read-only bind mount.
  # Manual https://nixos.org/manual/nixos/stable/options.html#opt-nix.readOnlyStore
  nix.readOnlyStore = true;

  # Linux kernel
  # Wiki https://nixos.wiki/wiki/Linux_kernel
  boot.kernelPackages = pkgs.linuxPackages-rt;
  boot.kernelParams = [
    "quiet"
    "splash"
    "log_level=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
  ];
  boot.consoleLogLevel = 0;
  # Module sysctl https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/sysctl.nix
  # Podman access start port >= 21
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 21;
  boot.kernel.sysctl."vm.swappiness" = 100;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev"; # set "nodev" for EFI only

  # Plymouth boot splash screen
  # Module https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/plymouth.nix
  # Reference https://blog.sidhartharya.com/using-custom-plymouth-theme-on-nixos/
  boot.plymouth.enable = true;

  # zRAM configuration
  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
  zramSwap.memoryPercent = 100;

  # Optimising the store
  # Wiki https://nixos.wiki/wiki/Storage_optimization
  #nix.settings.auto-optimise-store = true;

  networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  
  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = {
  #   "eurosign:e";
  #   "caps:escape" # map caps to escape.
  # };

  # Wiki https://nixos.wiki/wiki/Printing
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Wiki https://nixos.wiki/wiki/PipeWire
  # Enable sound.
  # sound.enable = false;
  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
    # Some useful knobs if you want to finetune or debug your setup
    config.pipewire = {
      # Low-latency configuration for Pro Audio
      "context.properties" = {
        ##"link.max-buffers" = 16; ##
        "log.level" = 2;
        "default.clock.rate" = 44100; # or you can set '48000'
        "default.clock.quantum" = 1024; # latency for recording
        ##"default.clock.min-quantum" = 32; ##
        ##"default.clock.max-quantum" = 32; ##
        "core.daemon" = true;
        "core.name" = "pipewire-0";
      };
      "context.modules" = [
      {
        name = "libpipewire-module-rtkit";
        args = {
          "nice.level" = -15;
          "rt.prio" = 88;
          "rt.time.soft" = 200000;
          "rt.time.hard" = 200000;
        };
        flags = [ "ifexists" "nofail" ];
      }
      { name = "libpipewire-module-protocol-native"; }
      { name = "libpipewire-module-profiler"; }
      { name = "libpipewire-module-metadata"; }
      { name = "libpipewire-module-spa-device-factory"; }
      { name = "libpipewire-module-spa-node-factory"; }
      { name = "libpipewire-module-client-node"; }
      { name = "libpipewire-module-client-device"; }
      {
        name = "libpipewire-module-portal";
        flags = [ "ifexists" "nofail" ];
      }
      {
        name = "libpipewire-module-access";
        args = {};
      }
      { name = "libpipewire-module-adapter"; }
      { name = "libpipewire-module-link-factory"; }
      { name = "libpipewire-module-session-manager"; }
      ];

      # Pro Audio
      "context.objects" = [
      {
        # A default dummy driver. This handles nodes marked with the "node.always-driver"
        # properyty when no other driver is currently active. JACK clients need this.
        factory = "spa-node-factory";
        args = {
          "factory.name"     = "support.node.driver";
          "node.name"        = "Dummy-Driver";
          "priority.driver"  = 8000;
        };
      }
      {
        factory = "adapter";
        args = {
          "factory.name"     = "support.null-audio-sink";
          "node.name"        = "Microphone-Proxy";
          "node.description" = "Microphone";
          "media.class"      = "Audio/Source/Virtual";
          "audio.position"   = "MONO";
        };
      }
      {
        factory = "adapter";
        args = {
          "factory.name"     = "support.null-audio-sink";
          "node.name"        = "Main-Output-Proxy";
          "node.description" = "Main Output";
          "media.class"      = "Audio/Sink";
          "audio.position"   = "FL,FR";
        };
      }
      ];
    };
    # Bluetooth Pipewire
    media-session.config.bluez-monitor.rules = [
      {
        # Matches all cards
        matches = [ { "device.name" = "~bluez_card.*"; } ];
        actions = {
          "update-props" = {
            "bluez5.reconnect-profiles" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
            # mSBC is not expected to work on all headset + adapter combinations.
            "bluez5.msbc-support" = true;
            # SBC-XQ is not expected to work on all headset + adapter combinations.
            "bluez5.sbc-xq-support" = true;
          };
        };
      }
      {
        matches = [
          # Matches all sources
          { "node.name" = "~bluez_input.*"; }
          # Matches all outputs
          { "node.name" = "~bluez_output.*"; }
        ];
      }
    ];
    # Controlling ALSA device
    # It is possible to configure various aspects of soundcards through PipeWire
    media-session.config.alsa-monitor = {
    rules = [
      {
        matches = [ { "node.name" = "alsa_output.*"; } ];
        actions = {
          update-props = {
            "audio.format" = "S32LE";
            "audio.rate" = 44100; # for USB soundcards it should be twice your desired rate
            "api.alsa.period-size" = 1024; # defaults to 1024, tweak by trial-and-error
            #"api.alsa.disable-batch" = true; # generally, USB soundcards use the batch mode
          };
        };
      }
    ];
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix-env -qaP wget
  nixpkgs.config.allowUnfree = true; # Allow Unfree packages
  # Allow unstable packages, Wiki https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs
  # $ nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
  # $ nix-channel --update
  nixpkgs.config.packageOverrides = pkgs: {
    unstable = import <nixos-unstable> {
      config = config.nixpkgs.config;
    };
  };
  #nixpkgs.config.allowBroken = true; # Allow Broken packages

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.agung = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/agung";
    password = "1234";
    description = "Agung Wijaya";
    shell = pkgs.zsh; # Wiki https://nixos.wiki/wiki/Command_Shell
    extraGroups = [
      "wheel"
      "networkmanager"
      "adbusers"
      "podman"
      "disk"
      "audio"
      "video"
      "kvm"
      "render"
      "input"
      "libvirtd"
    ];
    packages = with pkgs; [ 
      # latte-dock # dock
      firefox # browser
      filezilla # FTP client
      google-chrome # browser
      vlc # video player
      inkscape # vector
      gimp # image editor
      gimpPlugins.resynthesizer
      kate # IDE
      spotify
      obs-studio
      kid3 # ID3 tag
      ark # compress
      libreoffice # office
      kdenlive # video editor
      reaper # DAW Paid
      lmms # Sequencer Free
      hydrogen # Drum
      qjackctl # JACK
      a2jmidid # JACK midi
      # Audio Plugins
      x42-plugins # VU Meter,etc
      lsp-plugins # IR Impulse,etc
      eq10q # Equalizer
      dragonfly-reverb # Reverb
      surge-XT # Synth
      yoshimi # Synth
      calf # Saturation,etc
      guitarix # Guitar Effect
      gxplugins-lv2 # Guitarix extra
      # SOF firmware
      sof-firmware
      # Wine for run VST Windows
      # install via terminal "wineboot --init" later.
      wineWowPackages.stagingFull
      winetricks
      # Bridge VST Windows use Yabridge
      # install "nix-env -iA yabridge" and "nix-env -iA yabridgectl" later.
      # and you must run "nix-shell -p yabridgectl"
      # IDE
      sublime3
      vscode
      # Container
      podman
      distrobox
      # Android Studio
      unstable.flutter
      android-studio
    ];
  };
  # Needed for store VS Code auth token 
  services.gnome.gnome-keyring.enable = true;

  # Virtualisation
  # Podman wiki https://nixos.wiki/wiki/Podman
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
  virtualisation.podman.extraPackages = [ pkgs.zfs ];
  virtualisation.oci-containers.backend = "podman";
  # Virt-manager wiki https://nixos.wiki/wiki/Virt-manager
  virtualisation.libvirtd.enable = true;

  # Environment variables
  # Wiki https://nixos.wiki/wiki/Environment_variables
  environment.sessionVariables = rec {
    XDG_CACHE_HOME  = "\${HOME}/.cache";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_BIN_HOME    = "\${HOME}/.local/bin";
    XDG_DATA_HOME   = "\${HOME}/.local/share";

    PATH = [ 
      "\${XDG_BIN_HOME}"
    ];
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    efibootmgr # EFI wiki https://nixos.wiki/wiki/Bootloader
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    curl
    unzip
    unrar
    p7zip
    zip
    neofetch
    aria2 # aria2 downloader
    android-tools # adb and fastboot
    android-udev-rules # udev rules
    usbutils # lsusb
    ntfs3g # support NTFS
    # libsForQt5.qtstyleplugin-kvantum # kvantum
    # GTK
    gtk2
    gtk3
    gtk-engine-murrine
    virt-manager # Wiki https://nixos.wiki/wiki/Virt-manager
    # Add unstable package
    # unstable.[package_name]
  ];
  
  # loginShellInit
  #environment.loginShellInit = ''
  #  if [ -e $HOME/.bash_profile ];
  #  then
  #    . $HOME/.bash_profile
  #  fi
  #'';
  
  # Font directory
  fonts.fontDir.enable = true;
  fonts.enableGhostscriptFonts = true;
  fonts.fonts = with pkgs; [
    corefonts  # Micrsoft free fonts
    inconsolata  # monospaced
    ubuntu_font_family  # Ubuntu fonts
    terminus_font # for hidpi screens, large fonts
    liberation_ttf
  ];
  # fonts.fontconfig.dpi = 192;

  # For Pro Audio /etc/security/limits.conf
  # Reference https://discourse.nixos.org/t/security-pam-loginlimits-is-set-but-etc-security-limits-conf-is-not-created/1776
  # Module https://github.com/NixOS/nixos/blob/master/modules/security/pam.nix
  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
    { domain = "@audio"; item = "nofile"; type = "soft"; value = "99999"; }
    { domain = "@audio"; item = "nofile"; type = "hard"; value = "99999"; }
  ];

  # Bash completion
  programs.bash.enableCompletion = true;
  # Wiki android adb setup
  programs.adb.enable = true;
  # Wiki https://nixos.wiki/wiki/Virt-manager
  programs.dconf.enable = true;
  # Wiki https://nixos.wiki/wiki/Java
  # programs.java.enable = false;
  # programs.java.package = pkgs.jdk11;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # Wiki https://nixos.wiki/wiki/Firewall
  # networking.firewall.allowedTCPPorts = [ 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;
  # networking.firewall.interfaces."eth0".allowedTCPPorts = [ 80 443 ];
  networking.firewall.interfaces."wlp3s0".allowedTCPPorts = [];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}

