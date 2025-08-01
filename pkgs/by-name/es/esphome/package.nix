{
  lib,
  stdenv,
  callPackage,
  python3Packages,
  fetchFromGitHub,
  installShellFiles,
  platformio,
  esptool,
  git,
  inetutils,
  versionCheckHook,
  nixosTests,
}:

let
  python = python3Packages.python.override {
    self = python;
    packageOverrides = self: super: {
      esphome-dashboard = self.callPackage ./dashboard.nix { };

      paho-mqtt = super.paho-mqtt.overridePythonAttrs (oldAttrs: rec {
        version = "1.6.1";
        src = fetchFromGitHub {
          inherit (oldAttrs.src) owner repo;
          tag = "v${version}";
          hash = "sha256-9nH6xROVpmI+iTKXfwv2Ar1PAmWbEunI3HO0pZyK6Rg=";
        };
        build-system = with self; [ setuptools ];
        doCheck = false;
      });
    };
  };
in
python.pkgs.buildPythonApplication rec {
  pname = "esphome";
  version = "2025.7.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "esphome";
    repo = "esphome";
    tag = version;
    hash = "sha256-3hhFY6qi8xOuTb8WXuVaTNpCqXXdSg3DXubnj+FG73A=";
  };

  build-system = with python.pkgs; [
    setuptools
  ];

  nativeBuildInputs = [
    installShellFiles
  ];

  pythonRelaxDeps = true;

  pythonRemoveDeps = [
    "esptool"
    "platformio"
  ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "setuptools==80.9.0" "setuptools"
  '';

  # Remove esptool and platformio from requirements
  env.ESPHOME_USE_SUBPROCESS = "";

  # esphome has optional dependencies it does not declare, they are
  # loaded when certain config blocks are used.
  # They have validation functions like:
  # - validate_cryptography_installed for the wifi component
  dependencies = with python.pkgs; [
    aioesphomeapi
    argcomplete
    cairosvg
    click
    colorama
    cryptography
    esphome-dashboard
    esphome-glyphsets
    freetype-py
    icmplib
    jinja2
    kconfiglib
    packaging
    paho-mqtt
    pillow
    platformio
    protobuf
    puremagic
    pyparsing
    pyserial
    pyyaml
    requests
    ruamel-yaml
    tornado
    tzdata
    tzlocal
    voluptuous
  ];

  makeWrapperArgs = [
    # platformio is used in esphome/platformio_api.py
    # esptool is used in esphome/__main__.py
    # git is used in esphome/writer.py
    # inetutils is used in esphome/dashboard/status/ping.py
    "--prefix PATH : ${
      lib.makeBinPath [
        platformio
        esptool
        git
        inetutils
      ]
    }"
    "--prefix PYTHONPATH : ${python.pkgs.makePythonPath dependencies}" # will show better error messages
    "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc ]}"
    "--set ESPHOME_USE_SUBPROCESS ''"
    # https://github.com/NixOS/nixpkgs/issues/362193
    "--set PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION 'python'"
  ];

  # Needed for tests
  __darwinAllowLocalNetworking = true;

  nativeCheckInputs =
    with python3Packages;
    [
      hypothesis
      mock
      pytest-asyncio
      pytest-cov-stub
      pytest-mock
      pytestCheckHook
    ]
    ++ [ versionCheckHook ];

  disabledTestPaths = [
    # platformio builds; requires networking for dependency resolution
    "tests/integration"
  ];

  preCheck = ''
    export PATH=$PATH:$out/bin
  '';

  postInstall =
    let
      argcomplete = lib.getExe' python3Packages.argcomplete "register-python-argcomplete";
    in
    ''
      installShellCompletion --cmd esphome \
        --bash <(${argcomplete} --shell bash esphome) \
        --zsh <(${argcomplete} --shell zsh esphome) \
        --fish <(${argcomplete} --shell fish esphome)
    '';

  doInstallCheck = true;

  versionCheckProgramArg = "--version";

  passthru = {
    dashboard = python.pkgs.esphome-dashboard;
    updateScript = callPackage ./update.nix { };
    tests = { inherit (nixosTests) esphome; };
  };

  meta = {
    changelog = "https://github.com/esphome/esphome/releases/tag/${version}";
    description = "Make creating custom firmwares for ESP32/ESP8266 super easy";
    homepage = "https://esphome.io/";
    license = with lib.licenses; [
      mit # The C++/runtime codebase of the ESPHome project (file extensions .c, .cpp, .h, .hpp, .tcc, .ino)
      gpl3Only # The python codebase and all other parts of this codebase
    ];
    maintainers = with lib.maintainers; [
      hexa
    ];
    mainProgram = "esphome";
  };
}
