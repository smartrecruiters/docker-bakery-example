<p align="center">
	<h1 align="center">docker-bakery-example</h1>
	<p align="center">
		<a href="/LICENSE.md"><img alt="Software License" src="https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square"></a>	
	</p>
</p>
<!-- MarkdownTOC  depth="4" autolink="true" bracket="round" autoanchor="true" -->

- [Purpose](#purpose)
- [Example usage](#example-usage)
- [Features](#features)
- [Structure of the project](#structure-of-the-project)
    - [Config](#config)
        - [Properties config section](#properties-config-section)
        - [Commands config section](#commands-config-section)
        - [Others config section](#others-config-section)
    - [Dockerfile.template](#dockerfiletemplate)
- [Usage](#usage)
    - [Makefiles commands](#makefiles-commands)
    - [Scenario 1 - Building and pushing of the parent image along with all its dependants](#scenario-1---building-and-pushing-of-the-parent-image-along-with-all-its-dependants)
    - [Scenario 2 - Building and pushing of the parent image without triggering build of dependants](#scenario-2---building-and-pushing-of-the-parent-image-without-triggering-build-of-dependants)
    - [Scenario 3 - Add new image to the hierarchy](#scenario-3---add-new-image-to-the-hierarchy)
- [How to apply it to your project](#how-to-apply-it-to-your-project)

<!-- /MarkdownTOC -->

<a id="purpose"></a>
# Purpose

This is an example project with docker files that are managed by a **[docker-bakery](https://github.com/smartrecruiters/docker-bakery)**.
It illustrates a simple solution for automatic rebuilding of dependent images when parent image changes. 

<a id="example-usage"></a>
# Example usage
!["Example usage"](docker-bakery-demo.gif)

<a id="features"></a>
# Features
- Automatic triggering of dependant images builds when parent changes
- Support for Dockerfile templating with usage of [golang template engine](https://golang.org/pkg/text/template/)
- Support for [semantic versioning](https://semver.org) scope changes
- Possibility to `build` and `push` docker images to custom registries
- Possibility of providing custom `build` and `push` commands
- Versioning with `git` tags  
- Makefiles added for a convenient usage
- Ability to exclude images from the build triggering still keeping them in the hierarchy

<a id="structure-of-the-project"></a>
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
 
<a id="config"></a>
## Config
Configuration of the project is placed in `config.json` file and its contents are as follows:

```
{
	"properties": {
		"DEFAULT_PULL_REGISTRY": "private.repository.url:8888",
		"DEFAULT_PUSH_REGISTRY": "private.repository.url:8888",
		"DOCKERFILE_DIR": "Reserved dynamic property, contain path to currently build image. Can be used in template.",
		"IMAGE_NAME": "Reserved dynamic property, represents image name. Can be used in template.",
		"IMAGE_VERSION": "Reserved dynamic property, represents new version of the image. Can be used in template.",
		"BAKERY_BUILDER_NAME": "Reserved dynamic property, resolved to git config user.name. Recommended to be used in a template.",
		"BAKERY_BUILDER_EMAIL": "Reserved dynamic property, resolved to git config user.email. Recommended to be used in a template.",
		"BAKERY_BUILDER_HOST": "Reserved dynamic property, resolved to hostname of the machine where build is executed. Recommended to be used in a template.",
		"BAKERY_BUILD_DATE": "Reserved dynamic property, resolved to the date of a build. Recommended to be used in a template.",
		"BAKERY_IMAGE_HIERARCHY": "Reserved dynamic property, resolved to path representing image hierarchy. Highly recommended to be used in a template.",
		"BAKERY_SIGNATURE_VALUE": "Reserved dynamic property, resolved to one line signature embedding other BAKERY variables. Can to be used in a template.",
		"BAKERY_SIGNATURE_ENVS": "Reserved dynamic property embedding other BAKERY variables. Highly recommended to be used in a template."
	},
	"commands": {
		"defaultBuildCommand": "docker build --tag {{.IMAGE_NAME}}:{{.IMAGE_VERSION}} --tag {{.DEFAULT_PUSH_REGISTRY}}/{{.IMAGE_NAME}}:{{.IMAGE_VERSION}} --tag {{.DEFAULT_PULL_REGISTRY}}/{{.IMAGE_NAME}}:{{.IMAGE_VERSION}} {{.DOCKERFILE_DIR}}",
		"defaultPushCommand": "docker push {{.DEFAULT_PUSH_REGISTRY}}/{{.IMAGE_NAME}}:{{.IMAGE_VERSION}}"
	},
	"verbose": true,
	"autoBuildExcludes": [
		"some-image-name-that-will-be-excluded-from-build-when-parent-changes"
	]
}
```
 
<a id="properties-config-section"></a>
### Properties config section
 This section is dedicated for storing any custom properties that may be available for usage in `Dockerfile.template` files. 
 Feel free to modify this section and provide properties according to your needs. Flat structure should be preserved.
 
 This section will also be updated with dynamic properties during runtime. Dynamic properties do not have to be defined 
 in config as they are automatically added during runtime.
 
 Following properties belong to dynamic ones:
 - `DOCKERFILE_DIR` - will be replaced with currently processed dockerfile dir
 - `IMAGE_NAME` - will be replaced with currently processed image name
 - `IMAGE_VERSION` - will be replaced with currently processed image version
 - `*_VERSION` - where `*` is the image name. There will be that many properties of this kind as many images are in hierarchy. Initially those properties will be filled with latest versions of pushed images.
 - `BAKERY_BUILDER_NAME` - will be replaced with the git user name (taken from `git config user.name`)  
 - `BAKERY_BUILDER_EMAIL` - will be replaced with the git user email (taken from `git config user.email`)
 - `BAKERY_BUILDER_HOST` - will be replaced with hostname of the machine where build is executed
 - `BAKERY_BUILD_DATE` - will be replaced with current build date 
 - `BAKERY_IMAGE_HIERARCHY` - will be replaced with the path representing image hierarchy in the following format: 
 
 `parent1:versionOfParent1->parent2:versionOfParent2->imageName:imageVersion` 
 
 Hierarchy is built automatically given that parent images are exporting the same `ENV` variable that can be accessed in child images. Check the example project for references.
 - `BAKERY_SIGNATURE_VALUE` - will be replaced with a one liner string value embedding other `BAKERY*` variables together. Can be used in templates to create for example `ENV` variable. Example:
  
  `SINGATURE=Builder Name;builder@email.com;builder-host-name;2018-03-16 15:47:58;alpine-java:8u144b01_jdk->mammal:3.2.0->dog:4.0.0->dobermann:4.0.0->smaller-dobermann:4.0.0` 
 - `BAKERY_SIGNATURE_ENVS` - will be replaced with embedded `BAKERY*` variables in a `key=value` format. Convenient if you wish to have all `BAKERY*` variables in a dockerfile under single key. 
 Check the example project for references. 


<a id="commands-config-section"></a>
### Commands config section
This section contains two templates used for building and pushing docker images. It allows for specifying custom parameters. 
Commands defined here as templates will be filled with available defined properties from the config section + the dynamic properties set during runtime.  

<a id="others-config-section"></a>
### Others config section
- `verbose` config flag is useful when debugging, it simply shows more info between triggered build
- `autoBuildExcludes` allows to define array of image names that are defined in the entire hierarchy but will be excluded from builds when parent image changes. One can still build them and take advantages of having templates and inheritance, but at the same time allows for someone is not required to build them with entire images tree.

<a id="dockerfiletemplate"></a>
## Dockerfile.template
Presence of the `Dockerfile.template` file qualifies the image for the place in hierarchy and therefore allows for triggering builds that depend from this image. It also ensures that image build will be triggered when its parent changes. 

<a id="usage"></a>
# Usage
In this project `Makefiles` have been defined to simplify `build` and `push` process for the images.

<a id="makefiles-commands"></a>
## Makefiles commands 
Following commands are supported in makefile
```
/docker-bakery-example/dog$ make
Use one of following commands:
        make show-structure - shows structure of the images
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

<a id="scenario-1---building-and-pushing-of-the-parent-image-along-with-all-its-dependants"></a>
## Scenario 1 - Building and pushing of the parent image along with all its dependants
Lets say we want to release new version of the `dog` image and the change we are going to introduce is a major one (we are bumping the OS version to the next one) 
- as a first `Dockerfile.template` needs to be updated to include all our desired changes
- invoke `cd dog` followed by `make build-major-all` - this will produce new `major` version for the `dog` image and all its dependants
- once you have verified that all images have been build as expected and are running correctly they can be pushed to repository
- invoke `make push-major-all` - which will push all previously build images
- commit and push changes made to your template files       

<a id="scenario-2---building-and-pushing-of-the-parent-image-without-triggering-build-of-dependants"></a>
## Scenario 2 - Building and pushing of the parent image without triggering build of dependants
Lets say we want to release new version of the `dog` image and the change we are going to introduce is a simple tweak (patch version). We do not want to trigger dependant builds yet as our change is not yet finished. 
- as a first `Dockerfile.template` needs to be updated to include all our desired changes
- invoke `cd dog` followed by `make build-patch` - this will produce new `patch` version for the `dog` image but will not trigger anything other then that
- once you have verified that image have been build as expected and is running correctly it can be pushed to repository
- invoke `make push-patch` - which will push `dog` image to the repository     
- commit and push changes made to your template files       

<a id="scenario-3---add-new-image-to-the-hierarchy"></a>
## Scenario 3 - Add new image to the hierarchy
Lets say we want to introduce new image to the hierarchy called `even-smaller-dobermann`. 
- create directory called `even-smaller-dobermann` 
- create `Dockerfile.template` file and reference the parent image accordingly. In this case we want to set the parent for `smaller-dobermann` image
- create `Makefile` and make sure the path to include the main makefile is set properly
- invoke `make build-major` from the `even-smaller-dobermann` directory
- invoke `make push-major` from the `even-smaller-dobermann` directory
- commit and push newly created files

<a id="how-to-apply-it-to-your-project"></a>
# How to apply it to your project
Applying `docker-bakery` is quite simple. Here are the steps:
- download the [docker-bakery](https://github.com/smartrecruiters/docker-bakery/releases) binaries
- prepare a [config.json](https://github.com/smartrecruiters/docker-bakery-example/blob/master/config.json) file (mainly focus on the build and push commands + properties used in templates)
- prepare `Dockerfile.template` files for the images that need to be managed by a `docker-bakery`
- prepare `Makefiles` if you are aiming for convenient usage. This step is optional but it will greatly simplify usage as it will take care of passing paths to config and dockerfiles for you
- invoke `make build-major-all` starting with the base image in the hierarchy  
- invoke `make push-major-all` starting with the base image in the hierarchy
- profit  
