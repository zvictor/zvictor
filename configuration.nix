# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  FS_UUID = "BE38BCD438BC8D41";
  nix-software-center = import
    (pkgs.fetchFromGitHub {
      owner = "snowfallorg";
      repo = "nix-software-center";
      rev = "0.1.2";
      sha256 = "xiqF1mP8wFubdsAQ1BmfjzCgOD3YZf7EGWl9i69FTls=";
    })
    { };
in
{
  imports =
    [
      <home-manager/nixos>
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./nix-alien.nix
      # ./gnome-keyring.nix
      # ./hyprland.nix
    ];

  # Bootloader.
  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      # assuming /boot is the mount point of the  EFI partition in NixOS (as the installation section recommends).
      efiSysMountPoint = "/boot";
    };
    grub = {
      # despite what the configuration.nix manpage seems to indicate,
      # as of release 17.09, setting device to "nodev" will still call
      # `grub-install` if efiSupport is true
      # (the devices list is not used by the EFI grub install,
      # but must be set to some value in order to pass an assert in grub.nix)
      devices = [ "nodev" ];
      efiSupport = true;
      enable = true;
      # set $FS_UUID to the UUID of the EFI partition
      extraEntries = ''
        menuentry "Windows" {
          insmod part_gpt
          insmod fat
          insmod search_fs_uuid
          insmod chain
          search --fs-uuid --set=root $FS_UUID
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
  };

  hardware.keyboard.qmk.enable = true;
  networking.hostName = "zvictor-nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };


  systemd.services = {
    tune-usb-autosuspend = {
      description = "Disable USB autosuspend";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = { Type = "oneshot"; };
      unitConfig.RequiresMountsFor = "/sys";
      script = ''
        echo -1 > /sys/module/usbcore/parameters/autosuspend
      '';
    };
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # for electron and chromium apps to run on wayland
    # MOZ_ENABLE_WAYLAND = "1"; # firefox should always run on wayland

    # SDL_VIDEODRIVER = "wayland";
    # CLUTTER_BACKEND = "wayland";
    # GTK_USE_PORTAL = "1"; # makes dialogs (file opening) consistent with rest of the ui
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    exportConfiguration = true;

    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };

    # Enable the GNOME Desktop Environment.
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # desktopManager.pantheon.enable = true;
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  services.libinput = {
    # Enable touchpad support (enabled default in most desktopManager).
    enable = true;
    touchpad = {
      naturalScrolling = true;
      accelProfile = "adaptive";
      accelSpeed = "0.01";
    };
  };

  # https://www.reddit.com/r/NixOS/comments/1cj2fag/magic_trackpad_bluetooth_help/
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      input = {
        General = {
          UserspaceHID = true;
        };
      };
    };
  };

  #Bluetooth GUI
  services.blueman.enable = true;


  services.power-profiles-daemon.enable = false;
  powerManagement.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      # Disable too aggressive power-management autosuspend for USB receiver for wireless mouse
      USB_AUTOSUSPEND = 0;
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.zvictor = {
    isNormalUser = true;
    description = "zvictor";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      #  thunderbird
    ];
  };
  home-manager.users.zvictor = { pkgs, ... }: {
    # home.packages = [ ];
    programs.bash = {
      enable = true;
      bashrcExtra = ''
        # Set up fzf key bindings and fuzzy completion
        eval "$(fzf --bash)"
      '';
    };

    programs.zsh = {
      enable = true;
      autocd = true;
      initExtra = ''
        # Set up fzf key bindings and fuzzy completion
        source <(fzf --zsh)
      '';
    };


    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";
  };

  security.polkit.enable = true;

  programs.direnv.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Read iphones https://nixos.wiki/wiki/IOS
  services.usbmuxd.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = [
    pkgs.codeium
  ];

  programs._1password = { enable = true; };
  programs._1password-gui = {
    enable = true;
    # this makes system auth etc. work properly
    polkitPolicyOwners = [ "zvictor" ];
  };

  programs.git = {
    enable = true;
    config = {
      gpg = {
        format = "ssh";
      };
      "gpg \"ssh\"" = {
        program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
      };
      commit = {
        gpgsign = true;
      };

      user = {
        signingKey = "ssh-ed25519 xxxxx";
        name = "zvictor";
        email = "zvictor@users.noreply.github.com";
      };
    };
  };


  services.gnome = {
    sushi.enable = true; # quick previewer for nautilus
    glib-networking.enable = true; # network extensions libs
  };

  services.tumbler.enable = true; # thumbnailer service

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nix-software-center

    # libinput
    # libinput-gestures
    # wmctrl
    # xdotool
    bluez
    bluez-tools
    powertop
    acpi
    tlp

    wget
    git
    warp-terminal
    ntfs3g
    ifuse
    libimobiledevice
    usbmuxd
    qmk
    qmk-udev-rules
    gtop
    localsend
    brave
    smartgithg
    spotify
    discord
    _1password
    _1password-gui
    vscode
    surrealist
    nixpkgs-fmt
    nyxt
    chromium
    gnome.gnome-system-monitor
    gnome.dconf-editor
    # gnomeExtensions.pano
    # gnomeExtensions.tophat
    # gnomeExtensions.google-earth-wallpaper

    # yazi
    yazi
    ffmpegthumbnailer
    unar
    jq
    poppler
    fd
    ripgrep
    fzf
    zoxide
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    vscode = pkgs.vscode.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        wrapProgram $out/bin/code \
          --add-flags "--enable-features=UseOzonePlatform,WaylandWindowDecorations" \
          --add-flags "--ozone-platform-hint=auto" \
          --add-flags "--unity-launch" \
          --prefix ARGV : "%F"
      '';
    });
  };

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
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
