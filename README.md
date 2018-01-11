# docker-bakery-example
<!-- MarkdownTOC  depth="4" autolink="true" bracket="round" autoanchor="true" -->

- [Purpose](#purpose)
- [Features](#features)
- [Structure of the project](#structure-of-the-project)
    - [Config](#config)
        - [Properties config section](#properties-config-section)
        - [Commands config section](#commands-config-section)
    - [Dockerfile.template](#dockerfiletemplate)
- [Usage](#usage)
    - [Makefiles commands](#makefiles-commands)
    - [Scenario 1 - Building and pushing of the parent image along with all its dependants](#scenario-1---building-and-pushing-of-the-parent-image-along-with-all-its-dependants)
    - [Scenario 2 - Building and pushing of the parent image without triggering build of dependants](#scenario-2---building-and-pushing-of-the-parent-image-without-triggering-build-of-dependants)
    - [Scenario 3 - Add new image to the hierarchy](#scenario-3---add-new-image-to-the-hierarchy)
- [How to apply it to your project](#how-to-apply-it-to-your-project)

<!-- /MarkdownTOC -->

<a name="purpose"></a>
# Purpose

This is an example project with docker files that are managed by a `docker-bakery`.
It illustrates a simple solution for automatic rebuilding of dependent images when parent image changes. 

<a name="features"></a>
# Features
- Automatic triggering of dependant images builds when parent changes
- Support for Dockerfile templating with usage of [golang template engine](https://golang.org/pkg/text/template/)
- Support for [semantic versioning](https://semver.org) scope changes
- Possibility to `build` and `push` docker images to custom registries
- Possibility of providing custom `build` and `push` commands
- Versioning with `git` tags  
- Makefiles added for a convenient usage

<a name="structure-of-the-project"></a>
# Structure of the project

Hierarchy of docker files is as follows:
```
├── alpine-java
│   ├── bird
│   └── mammal
│       ├── cat
│       ├── dog
│       │   ├── dobermann
│       │   │   └── smaller-dobermann
│       │   ├── pitbull
│       │   └── labrador
│       └── horse
└── scratch
    └── fish
```

meaning that:
 - we have 10 images in total in this repository 
 - 9 images are created directly or indirectly from the `alpine-java` image
 - 1 image is derived from the `scratch`
 - there are 2 top level images (`scratch` and `alpine-java`)
 - `mammal` image has 7 dependants (direct + indirect)
 
<a name="config"></a>
## Config
Configuration of the project is placed in `config.json` file and its contents are as follows:

```
 {
 	"properties": {
		"DEFAULT_PULL_REGISTRY": "some-private-registry.com:9084",
		"DEFAULT_PUSH_REGISTRY": "some-private-registry.com:9082",
 		"DOCKERFILE_DIR": "Reserved dynamic property, contain path to currently build image. Can be used in template.",
 		"IMAGE_NAME": "Reserved dynamic property, represents image name. Can be used in template.",
 		"IMAGE_VERSION": "Reserved dynamic property, represents new version of the image. Can be used in template."
 	},
 	"commands": {
 		"defaultBuildCommand": "docker build --tag {{.IMAGE_NAME}}:{{.IMAGE_VERSION}} --tag {{.DEFAULT_PUSH_REGISTRY}}/{{.IMAGE_NAME}}:{{.IMAGE_VERSION}} --tag {{.DEFAULT_PULL_REGISTRY}}/{{.IMAGE_NAME}}:{{.IMAGE_VERSION}} {{.DOCKERFILE_DIR}}",
 		"defaultPushCommand": "docker push {{.DEFAULT_PUSH_REGISTRY}}/{{.IMAGE_NAME}}:{{.IMAGE_VERSION}}"
 	}
 }
```
 
<a name="properties-config-section"></a>
### Properties config section
 This section is dedicated for storing any custom properties that may be available for usage in `Dockerfile.template` files. 
 Feel free to modify this section and provide properties according to your needs. Flat structure should be preserved.
 
 This section will also be updated with dynamic properties during runtime. 
 
 Following properties belong to dynamic ones:
 - `DOCKERFILE_DIR` - will be replaced with currently processed dockerfile dir
 - `IMAGE_NAME` - will be replaced with currently processed image name
 - `IMAGE_VERSION` - will be replaced with currently processed image version
 - `*_VERSION` - where `*` is the image name. There will be that many properties of this kind as many images are in hierarchy. Initially those properties will be filled with latest versions of pushed images.  

<a name="commands-config-section"></a>
### Commands config section
This section contains two templates used for building and pushing docker images. It allows for specifying custom parameters. 
Commands defined here as templates will be filled with available defined properties from the config section + the dynamic properties set during runtime.  

<a name="dockerfiletemplate"></a>
## Dockerfile.template
Presence of the `Dockerfile.template` file qualifies the image for the place in hierarchy and therefore allows for triggering builds that depend from this image. It also ensures that image build will be triggered when its parent changes. 

<a name="usage"></a>
# Usage
In this project `Makefiles` have been defined to simplify `build` and `push` process for the images.

<a name="makefiles-commands"></a>
## Makefiles commands 
Following commands are supported in makefile
```
/docker-bakery-example/dog$ make
Use one of following commands:
        make build-patch - build next patch version of the image without triggering of dependant build
        make build-minor - build next minor version of the image without triggering of dependant build
        make build-major - build next major version of the image without triggering of dependant build
        make build-patch-all - build next patch version of the image and trigger dependant builds
        make build-minor-all - build next minor version of the image and trigger dependant builds
        make build-major-all - build next major version of the image and trigger dependant builds
        make push-patch - push next patch version of the image without triggering push of dependants
        make push-minor - push next patch version of the image without triggering push of dependants
        make push-major - push next patch version of the image without triggering push of dependants
        make push-patch-all - push next patch version of the image and trigger push of dependants
        make push-minor-all - push next patch version of the image and trigger push of dependants
        make push-major-all - push next patch version of the image and trigger push of dependants
```
 Lets consider several scenarios.

<a name="scenario-1---building-and-pushing-of-the-parent-image-along-with-all-its-dependants"></a>
## Scenario 1 - Building and pushing of the parent image along with all its dependants
Lets say we want to release new version of the `dog` image and the change we are going to introduce is a major one (we are bumping the OS version to the next one) 
- as a first `Dockerfile.template` needs to be updated to include all our desired changes
- invoke `cd dog` followed by `make build-major-all` - this will produce new `major` version for the `dog` image and all its dependants
- once you have verified that all images have been build as expected and are running correctly they can be pushed to repository
- invoke `make push-major-all` - which will push all previously build images
- commit and push changes made to your template files       

<a name="scenario-2---building-and-pushing-of-the-parent-image-without-triggering-build-of-dependants"></a>
## Scenario 2 - Building and pushing of the parent image without triggering build of dependants
Lets say we want to release new version of the `dog` image and the change we are going to introduce is a simple tweak (patch version). We do not want to trigger dependant builds yet as our change is not yet finished. 
- as a first `Dockerfile.template` needs to be updated to include all our desired changes
- invoke `cd dog` followed by `make build-patch` - this will produce new `patch` version for the `dog` image but will not trigger anything other then that
- once you have verified that image have been build as expected and is running correctly it can be pushed to repository
- invoke `make push-patch` - which will push `dog` image to the repository     
- commit and push changes made to your template files       

<a name="scenario-3---add-new-image-to-the-hierarchy"></a>
## Scenario 3 - Add new image to the hierarchy
Lets say we want to introduce new image to the hierarchy called `even-smaller-dobermann`. 
- create directory called `even-smaller-dobermann` 
- create `Dockerfile.template` file and reference the parent image accordingly. In this case we want to set the parent for `smaller-dobermann` image
- create `Makefile` and make sure the path to include the main makefile is set properly
- invoke `make build-major` from the `even-smaller-dobermann` directory
- invoke `make push-major` from the `even-smaller-dobermann` directory
- commit and push newly created files

<a name="how-to-apply-it-to-your-project"></a>
# How to apply it to your project
Applying `docker-bakery` is quite simple. Here are the steps:
- download the `docker-bakery` binaries
- prepare a `config.json` file (mainly focus on the build and push commands + properties used in templates)
- prepare `Dockerfile.template` files for the images that need to be manages by a `docker-bakery`
- prepare `Makefiles` if you are aiming for convenient usage. This step is optional but if will greatly simplify usage as it will take care of passing paths to config and dockerfiles for you.
- invoke `make build-major-all` starting with the base image in the hierarchy  
- invoke `make push-major-all` starting with the base image in the hierarchy  