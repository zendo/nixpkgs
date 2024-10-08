{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,

  # dependencies
  django,
  pytz,

  # optionals
  django-taggit,

  # tests
  pytest-django,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "django-modelcluster";
  version = "6.3";
  format = "setuptools";

  disabled = pythonOlder "3.5";

  src = fetchFromGitHub {
    owner = "wagtail";
    repo = "django-modelcluster";
    rev = "refs/tags/v${version}";
    hash = "sha256-AUVl2aidjW7Uu//3HlAod7pxzj6Gs1Xd0uTt3NrrqAU=";
  };

  propagatedBuildInputs = [
    django
    pytz
  ];

  optional-dependencies.taggit = [ django-taggit ];

  env.DJANGO_SETTINGS_MODULE = "tests.settings";

  nativeCheckInputs = [
    pytest-django
    pytestCheckHook
  ] ++ optional-dependencies.taggit;

  # https://github.com/wagtail/django-modelcluster/issues/173
  disabledTests = lib.optionals (lib.versionAtLeast django.version "4.2") [
    "test_formfield_callback"
  ];

  meta = with lib; {
    description = "Django extension to allow working with 'clusters' of models as a single unit, independently of the database";
    homepage = "https://github.com/torchbox/django-modelcluster/";
    license = licenses.bsd2;
    maintainers = with maintainers; [ desiderius ];
  };
}
