{
  lib,
  fetchPypi,
  buildPythonApplication,
  poetry-core,
  colorama,
  packaging,
  pydantic,
  requests,
  pygobject3,
  tqdm,
  gobject-introspection,
  wrapGAppsNoGuiHook,
}:

buildPythonApplication rec {
  pname = "gnome-extensions-cli";
  version = "0.10.5";
  format = "pyproject";

  src = fetchPypi {
    pname = "gnome_extensions_cli";
    inherit version;
    hash = "sha256-Rli4gsxbD84SSyx6hdPz5MKHsYw4jX7XgAkAydg0lGI=";
  };

  nativeBuildInputs = [
    gobject-introspection
    poetry-core
    wrapGAppsNoGuiHook
  ];

  pythonRelaxDeps = [
    "more-itertools"
    "packaging"
  ];

  propagatedBuildInputs = [
    colorama
    packaging
    pydantic
    requests
    pygobject3
    tqdm
  ];

  pythonImportsCheck = [
    "gnome_extensions_cli"
  ];

  meta = with lib; {
    homepage = "https://github.com/essembeh/gnome-extensions-cli";
    description = "Command line tool to manage your GNOME Shell extensions";
    license = licenses.asl20;
    maintainers = with maintainers; [ dylanmtaylor ];
    platforms = platforms.linux;
  };
}
