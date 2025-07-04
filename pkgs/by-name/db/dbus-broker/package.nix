{
  lib,
  stdenv,
  fetchFromGitHub,
  docutils,
  meson,
  ninja,
  pkg-config,
  dbus,
  linuxHeaders,
  systemd,
}:

let
  meta = {
    maintainers = with lib.maintainers; [
      peterhoeg
      rvdp
    ];
    platforms = lib.platforms.linux;
  };

  dep =
    {
      pname,
      version,
      hash,
      rev ? "v${version}",
      buildInputs ? [ ],
    }:
    stdenv.mkDerivation {
      inherit pname version;
      src = fetchFromGitHub {
        owner = "c-util";
        repo = pname;
        inherit hash rev;
      };
      nativeBuildInputs = [
        meson
        ninja
        pkg-config
      ];
      inherit buildInputs;
      meta = meta // {
        description = "C-Util Project is a collection of utility libraries for the C11 language";
        homepage = "https://c-util.github.io/";
        license = [
          lib.licenses.asl20
          lib.licenses.lgpl21Plus
        ];
      };
    };

  # These libraries are not used outside of dbus-broker.
  #
  # If that changes, we can always break them out, but they are essentially
  # part of the dbus-broker project, just in separate repositories.
  c-dvar = dep {
    pname = "c-dvar";
    version = "1.2.0";
    hash = "sha256-OlV6yR1tNWFN+rxPPGmbfbh7WyB6FwORyZR1V553iYE=";
    buildInputs = [
      c-stdaux
      c-utf8
    ];
  };
  c-ini = dep {
    pname = "c-ini";
    version = "1.1.0";
    hash = "sha256-wa7aNl20hkb/83c4AkQ/0YFDdmBs4XGW+WLUtBWIC98=";
    buildInputs = [
      c-list
      c-rbtree
      c-stdaux
      c-utf8
    ];
  };
  c-list = dep {
    pname = "c-list";
    version = "3.1.0";
    hash = "sha256-fp3EAqcbFCLaT2EstLSzwP2X13pi2EFpFAullhoCtpw=";
  };
  c-rbtree = dep {
    pname = "c-rbtree";
    version = "3.2.0";
    hash = "sha256-dTMeawhPLRtHvMXfXCrT5iCdoh7qS3v+raC6c+t+X38=";
    buildInputs = [ c-stdaux ];
  };
  c-shquote = dep {
    pname = "c-shquote";
    version = "1.1.0";
    hash = "sha256-z6hpQ/kpCYAngMNfxLkfsxaGtvP4yBMigX1lGpIIzMQ=";
    buildInputs = [ c-stdaux ];
  };
  c-stdaux = dep {
    pname = "c-stdaux";
    version = "1.6.0";
    hash = "sha256-/15lop+WUkTW9v9h7BBdwRSpJgcBXaJNtMM7LXgcQE4=";
  };
  c-utf8 = dep {
    pname = "c-utf8";
    version = "1.1.0";
    hash = "sha256-9vBYylbt1ypJwIAQJd/oiAueh+4VYcn/KzofQuhUea0=";
    buildInputs = [ c-stdaux ];
  };

in

stdenv.mkDerivation (finalAttrs: {
  pname = "dbus-broker";
  version = "37";

  src = fetchFromGitHub {
    owner = "bus1";
    repo = "dbus-broker";
    rev = "v${finalAttrs.version}";
    hash = "sha256-a9ydcJKZP8MLzu9lv40p9sTyo8IsU++9HOFeGU3+Tok=";
  };

  patches = [
    ./paths.patch
    ./disable-test.patch
  ];

  nativeBuildInputs = [
    docutils
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    c-dvar
    c-ini
    c-list
    c-rbtree
    c-shquote
    c-stdaux
    c-utf8
    dbus
    linuxHeaders
    systemd
  ];

  mesonFlags = [
    # while we technically support 4.9 and 4.14, the NixOS module will throw an
    # error when using a kernel that's too old
    "-D=linux-4-17=true"
    "-D=system-console-users=gdm,sddm,lightdm"
  ];

  PKG_CONFIG_SYSTEMD_SYSTEMDSYSTEMUNITDIR = "${placeholder "out"}/lib/systemd/system";
  PKG_CONFIG_SYSTEMD_SYSTEMDUSERUNITDIR = "${placeholder "out"}/lib/systemd/user";
  PKG_CONFIG_SYSTEMD_CATALOGDIR = "${placeholder "out"}/lib/systemd/catalog";

  postInstall = ''
    install -Dm444 $src/README.md $out/share/doc/dbus-broker/README

    sed -i $out/lib/systemd/{system,user}/dbus-broker.service \
      -e 's,^ExecReload.*busctl,ExecReload=${systemd}/bin/busctl,'
  '';

  doCheck = true;

  meta = meta // {
    description = "Linux D-Bus Message Broker";
    homepage = "https://github.com/bus1/dbus-broker/wiki";
    license = lib.licenses.asl20;
  };
})
