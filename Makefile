# qgis server makefile
#

VERSION:=1.7.2

ifndef CI_COMMIT_TAG
VERSION_TAG=$(VERSION)rc0
else
VERSION_TAG=$(VERSION)
endif

BUILDID=$(shell date +"%Y%m%d%H%M")
COMMITID=$(shell git rev-parse --short HEAD)

BUILDDIR:=build
DIST:=${BUILDDIR}/dist

MANIFEST=pyqgisserver/build.manifest

PYTHON:=python3

FLAVOR:=release

# This is necessary with pytest as long it is not fixed
# see also https://github.com/qgis/QGIS/pull/5337
export QGIS_DISABLE_MESSAGE_HOOKS := 1
export QGIS_NO_OVERRIDE_IMPORT := 1

dirs:
	mkdir -p $(DIST)

version:
	echo $(VERSION_TAG) > VERSION

manifest: version
	echo name=$(shell $(PYTHON) setup.py --name) > $(MANIFEST) && \
		echo version=$(shell $(PYTHON) setup.py --version) >> $(MANIFEST) && \
		echo buildid=$(BUILDID)   >> $(MANIFEST) && \
		echo commitid=$(COMMITID) >> $(MANIFEST)

# Build dependencies
wheel-deps: dirs
	pip wheel -w $(DIST) -r requirements.txt

wheel:
	mkdir -p $(DIST)
	$(PYTHON) setup.py bdist_wheel --dist-dir=$(DIST)

deliver:
	twine upload -r storage $(DIST)/*

dist: dirs manifest
	rm -rf *.egg-info
	$(PYTHON) setup.py sdist --dist-dir=$(DIST)

clean:
	rm -rf $(BUILDDIR)

test: lint docker-test

lint:
	@flake8 --ignore=E123,E2,E3,E5,W2,W3  pyqgisserver pyqgisservercontrib


docker-%:
	$(MAKE) -C tests/docker $* FLAVOR=$(FLAVOR)
