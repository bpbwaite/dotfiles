# System Reproduction Procedure

Nix is hard but I like reproducibility, so here's how I do it in Arch.
This guide will serve as a reference (along with [the usual guide](https://wiki.archlinux.org/title/Installation_guide)) should I ever need to reinstall my OS. (Arch btw) It has hardware- and configuration-specific commands. Along with my [etckeeper for etc](https://github.com/bpbwaite/) and [stow for dotfiles](https://github.com/bpbwaite/dotfiles) repositories, no configuration file will ever be lost.
Note: $* or #* or just *** implies command may need to be modified


## **INSTALLATION**

### From the Live Media

+ Pre-Configuation
    + Update BIOS
    + Enable XMP and Virtualization
    + Disable FastBoot and SecureBoot
    + Set some boot-time Fan Curves
    + Prepare secure boot/hibernation settings
    + Download server image; verify with gpg OR pacman
    ```
    $ gpg --keyserver-options auto-key-retrieve --verify archlinux-x86_64.iso.sig
    $ pacman-key -v ~/Downloads/archlinux-x86_64.iso.sig
    ```
    + Flash to USB Drive; get device ID and that is it not mounted. Command may require modification
    ```
    $ ls -l /dev/disk/by-id/usb-*
    $ lsblk
    $* cat ~/Downloads/archlinux-x86_64.iso > /dev/disk/by-id/usb-*
    # sync
    ```
+ Imaging Tool Configuration
    ```
    # loadkeys us
    # setfont ter-132b // if monitor is 4K
    # cat /sys/firmware/efi/fw_platform_size // should return 64
    # timedatectl // should return current time
    # ip link // check if online, otherwise:
    # systemctl enable iwd
    # systemctl start iwd
    # iwctl
    ```

+ Variables - set these
    ```
    # export MAINDISK=nvme0n1
    # export EFISP=nvme0n1p1
    # export ROOTPARTITION=nvme0n1p2
    # export MYHOSTNAME=BDesktop
    # export TIMEZONEPATH=US/Pacific
    # export MICROCODE=intel-ucode
    # export DISKUUID=*
    // can get disk UUID after disk encryption using
    # ls -lh /dev/mapper
    ```

+ Hardware Setup
    + Drive Containing Root
    + Change Samsung 512e to 4kn (Optimal formatted logical sector size) ~ CANNOT BE DONE LATER
    + Not required for most new drives, they use 512e and don't support 4kn
        ```
        # lsblk -td
        # nvme id-ns -H /dev/$MAINDISK | grep "Performance" // check FLBAS
        # nvme format --lbaf=1 /dev/$MAINDISK
        # nvme format --lbaf=1 /dev/$MAINDISK
        # nvme id-ns -H /dev/$MAINDISK | grep "Performance" // check again
        # nvme reset
        ```
    + Create Partitions
        ```
        # fdisk -x /dev/$MAINDISK
        # fdisk /dev/$MAINDISK
        // CREATE GUID PT!!!!!!!! by pressing g
        // 600M partition is 1230848
        // press enter wherever there is a period:
        // (LINUX required for LUKS)
            > n....1228800.n.....t.1.1.t.2.23.p.w.q.

        ```
        Create FAT32 EFISP, EXT4 main filesystem - swap will use swapfile and perform
        System Encryption: Full disk encryption with LUKS ~ CANNOT BE DONE LATER
        ```
        $ cryptsetup benchmark // see if hardware support for AES-256
        # cryptsetup luksFormat /dev/$ROOTPARTITION
        # YES ~ no password, password will be reset later
        # cryptsetup open /dev/$ROOTPARTITION root
        # mkfs.ext4 /dev/mapper/root
        # mount /dev/mapper/root /mnt
        # mkfs.fat -F 32 /dev/$EFISP
        # mount --mkdir /dev/$EFISP /mnt/efi // NOT /mnt/boot
        ```

    + Bring Backup Drives Online (RAID 1)
        > no method yet

+ PACMAN, PACSTRAP, Mirrorlist & Reflector
    + Modify /etc/pacman.d/mirrorlist
    + Modify so 5-10 downloads simultaneously *****
    + pacstrap
        ```
        # pacstrap -K /mnt base base-devel linux linux-firmware $MICROCODE nano man-db man-pages texinfo  wget git tar curl vi vim tmux zsh ufw
        ```
    // do not add sbctl yet
    // fsck: why not worK?

+ Chroot into the new system
    ```
    # arch-chroot /mnt
    ```
+ Set up time
    ```
    # ls -lRh /usr/share/zoneinfo // find the correct region
    # ln -sf /usr/share/zoneinfo/$TIMEZONEPATH /etc/localtime
    # hwclock --systohc
    ```
+ Set localization by editing /etc/locale.gen and uncommend en_US.UTF-8 UTF-8
    ```
    # locale-gen
    # echo LANG=en_US.UTF-8 > /etc/locale.conf
    //# localectl set-keymap us
    ```
+ Don't change the localization for vconsole
+ Set hostname
    ```
    # echo $MYHOSTNAME > /etc/hostname
    ```
// back to encryption shit:
+ Modify /etc/mkinitcpio.conf:

    > HOOKS=(base systemd autodetect microcode modconf kms keyboard keymap consolefont sd-vconsole block sd-encrypt filesystems fsck)

    > MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)

+ Modify /etc/mkinitcpio.d/linux.preset:

    // !! replace esp with $EFISP (probably nvme0n1p1)

    > \# mkinitcpio preset file for the 'linux' package
    > #ALL_config="/etc/mkinitcpio.conf"
    > ALL_kver="/boot/vmlinuz-linux"
    > PRESETS=('default' 'fallback')
    > #default_config="/etc/mkinitcpio.conf"
    > #default_image="/boot/initramfs-linux.img"
    > default_uki="/efi/EFI/Linux/arch-linux.efi"
    > default_options="--splash=/usr/share/systemd/bootctl/splash-arch.bmp"
    > #fallback_config="/etc/mkinitcpio.conf"
    > #fallback_image="/boot/initramfs-linux-fallback.img"
    > fallback_uki="esp/EFI/Linux/arch-linux-fallback.efi"
    > fallback_options="-S autodetect"
    // basically, comment/uncomment 4 lines
+ Do not regenerate!
+ Modify Kernel CMDLINE (encryption, quiet, and TRIM)
    ```
    // get the disk uuid
    # ls -lha /dev/disk/by-uuid // returns ../../nvme0n1p2
    # echo "rd.luks.name=root=* root=/dev/mapper/root rw quiet rd.luks.options=discard" > /etc/kernel/cmdline
    // where * is the uuid of the partition?
    ```
+ Get Boot Loader: pick from below
    
    ```
    # pacman -S grub os-prober efibootmgr
    # bootctl install
    
    // with updating /etc/kernel/cmdline,
    # efibootmgr --create --disk /dev/nvme0n1 --part 1 --label "EFISTUB Arch" --loader /vmlinuz-linux --unicode 'root=UUID=* rw loglevel=3 initrd=\initramfs-linux.img'
    ```
+ Generate Filesystem Table (NOT required if automounting with systemd in case of LUKS)
    ```
    # genfstab -U /mnt >> /etc/fstab
    // or:
    # genfstab -U -p /mnt >> /mnt/etc/fstab
    efibootmgr
    os-prober
    ```
+ Recreate initramfs with mkinitcpio
    ```
    mkinitcpio -P
    ```

### FINALIZATION

+ Setup password (master key)
```
# passwd // set root password
```
+ Reboot - remember to go back to BIOS
```
# exit
# umount -R /mnt
# reboot
```

## **POST-INSTALLATION**
+ Restore installation media FS
    ```
    #* wipefs --all /dev/disk/by-id/usb-*
    ```
+ Reformat and repartition **********
+ Remove installation media

+ Set enable networking and NTP
    ```
    # systemctl enable --now systemd-networkd.service
    # systemctl enable --now systemd-resolved.service
    # systemctl enable --now ufw.service
    # systemctl enable --now systemd-timesyncd.service
    # timedatectl set-ntp true
    $ timedatectl timesync-status // to verify

### Security

+ Secure boot:
    + Enable in BIOS
    + Sign boot loader and EFI binary
        ```
        # sbctl bundle --save /efi/EFI/???
        # sbctl bundle --save /efi/EFI/???-fallback.efi --initramfs ???
        # sbctl generate-bundles
        # sbctl create-keys
        # chattr -i /sys/firmware/efi/efivars/*?
        # sbctl enroll-keys -m -c -f -a
        # sbctl verify
        ```

        ```
        // from scratch.txt
        sudo sbctl bundle --save /boot/EFI/Linux/arch-linux.efi
        sbctl generate-bundles
        bootctl install
        sbctl create-keys
        sudo chattr -i /sys/firmware/efi/efivars/*
        sbctl enroll-keys -m

        # sbctl enroll-keys -m -c -f -a // (incl. microsoft, custom, firmware builtins, append)
        also made copies in /boot with sbctl enroll-keys --export esl

        ```
+ Enroll TPM PK/KEK/DB on PCR7
    ```
    # systemd-cryptenroll /dev/$ROOTPARTITION --recovery-key
    # systemd-cryptenroll /dev/$ROOTPARTITION --wipe-slot=empty --tpm2-device=auto
    # bootctl // after reboot, to see if it worked
    ```

### System Maintainence

+ Create the non-root user bri
+ TRACKING
+ Set up etckeeper, GNU stow, & git for dotfiles
    ```
    # pacman -Syu etckeeper stow
    ```
+ OpenDoas
+ Enable TRIM (already done if using archinstall)
```
# systemctl enable --now fstrim.timer
```

+ Misc Configuration
    + Multilib repository
    + Paru ; then TKG from chaotic aur
    + thermald
    + locale setup
    + parallelize packages
    + polkit
    + OOMD
+ Drivers
    + bluetooth/blueman/bluez/bluez-utils
    + NVIDIA Driver DKMS
        in /etc/modprobe.d make a conf that says
        options nvidia_drm modeset=1

+ bash; set up to use bash & not zsh on tty
+ Traffic Shaping (no experience yet)
+ Bonjourlike: uncomment line 8 of /etc/dhcpcd.conf, maybe enable the service?

### Software

+ Software Development
    + gcc/g++/Clang/cmake, Python3, JDK, ArduinoIDE2, RUST, Yarn
    + posix-user-portabililty posix-c-development

+ SDDM/swaylock
+ WM/DE packages
    + hyprland dunst cronie?thunar/dolphin/nnn/ranger wofi xdg-desktop-portal-hyprland qt5-wayland qt6-wayland polkit-kde-agent grim slurp
    + hyprpaper waybar brightnessctl pavucontrol xorg-xwayland
    + gnu-free-fronts ttf-liberation
    + feh or weh? xev or wev? catimg eza
    + some kind of dock
    + Terminal:
        + kitty Alacritty Hyper BlackBox WezTerm tmux

+ Theming: need scripts for switching all relevant files;
    + Catppuccin

+ AHK Replacement: Hotkeys
+ Audio
    + pipewire pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire libpulse wireplumber
+ Silly Tools
    + thefuck sl bat broot? zoxide zsh/ohmyzsh lolcat/gay cowsay fortune doas
+ Higher-Level Software
    + kicad discord firefox vlc 7zip/gzip/unzip gimp libreoffice obsidian qbittorrent latex obs-studio vscodium ungoogled-chromium-thorium blender audacity inkscape intiface handbrake yt-dlp virtualbox qemu+libvirt+kvm freecad neovim wine gparted steam lutris darktable clementine/strawberry firefox-developer edition dolphin-emulator-wii github-desktop octave fastfetch prism-launcher overwatch prusaslicer/superslicer putty/other zoom reaper

    + notepadqq, gedit, or Kate



+ OpenRGB, piper, htop, btop, ffmpeg

+ No mouse acceleration
+ Environment variables/PATH?

+ look into CTT recs:
    + ffmpeg wl-clipboard wf-recorder ffmpegthumbnailer tumbler xarchiver playerctl waybar-hyprland wlogout swaylock? pamixerORpamixerORamixer nwg-look ttf-nerd-fonts-symbols-common noto-fonts/noto-fonts-emoji ttf-jetbrains-mono-nerd adobe-source-code-pro-fonts
    + brightnessctl noise-suppression-for-voice grimblast autojump? github-desktop mangohud plymouth?
    + mesa? base-devel linux-headers usbutils autoconf automake cmatrix code efibootmgr gamemode gcc jdk-openjdk make fastfetch openssh os-prober pulseaudio-alsa pulseaudio-bluetooth terminus-font wine-mono wine-gecko zsh-syntax-highlighting zsh-autosuggestions

    hyprpicker, github desktop, nerd-fonts-fira-code could not be found! maybe in AUR

notification daemon, fontconfig, mako? xdg-user-dirs win11-icon-theme mdcat

+ microcode into UKI
+ UDEV (advanced)
+ DNS Sec
+ Network shares/SAMBA
    + samba avahi
+ benchmarkers

### Emulator Setup

+ Still need replacement for:
BOTTLES for fusion??
    + Adobe PDF, Adobe other, Calculator, Control Panel, Digilent, EasyWaveX, EOS Webcam Utility, Focusrite device driver, fusion360, quartus prime, intelliJ IDEA, logitech G-Hub, MATLAB, photo viewer, STL viewer, PicoScope, Powertoys?, Printer, QFlipper, RPi-Imager, SASM, Visual Studio, Voicemeeter(pulsemeeter-git), Voidtools Everything, Wacom Tablet driver, whiteboard, windirstat, wireshark
    + Task manager, sound, notifications, msconfig?, nvidiacontrol, start menu, autoruns, profile instpector, tweaker, HWinfo, yt-dl
