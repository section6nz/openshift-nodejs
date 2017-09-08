# NodeJS Base Images

This repository contains source of base Node.JS images. Includes build configuration for latest 6.x, 7.x and 8.x releases. This is based on the _Base RHEL Atomic 7_ image.

The `Dockerfile` makes use of the environment variable `NODE_VERSION` to determine what version of node is installed during build. This is done via `ENV` and not `ARG` as OpenShift Docker Strategy does not support build args as of OCP 3.5. This should be available in 3.6+.

The environment is configured via the `build-config.yaml` file for each stream. OpenShift, when using the _Docker Build Strategy_, injects an `ENV` statement after the `FROM` statement. This allows the use of this variable through the build.

## Managing Configuration
In order to assist with the management of related configuration, a `Makefile` is provided that uses the _OpenShift Client_ to install/replace/delete the configuration in a specified namespace (default is `openshift`).

### Example Usage
```sh
# delete any existing configuration (build, imagestream)
make clean

# install configuration for all streams
make install

# if installing to your namespace
make NAMESPACE=$(whoami) install
```

## Node.JS S2I Builder Images
This repository also stores the configuration required for building and using the source-to-image flavors of the above mentioned base images.

_*Caution:*_ These images are dependent on the base images, as they expect and use, variables like `S2I_DESTINATION`, `OPENSHIFT_SOURCE_DIR`, `OPENSHIFT_DEPLOYMENTS_DIR` etc. to be available in the runtime environment (with the container) as defined in `Dockerfile.s2i`.

### S2I Assemble Script

#### Configuration
The `assemble` script provides the following customizations.

##### Debug Mode
Specifying the `DEBUG` environment variable will run the `assemble` stage of the `source-to-image` process with the following changes.
* executes `set -x` to enable bash tracing
* uses `-v` flag when using `mv` or `cp` commands
* prints out debug level log messages

##### NPM Logging
Specifying the `NPM_CONFIG_LOGLEVEL` with a valid value (eg: `info`, `debug` etc.) will override the default (`info`). This will make `npm` quiet chatty and hence is not switched to `debug` when `DEBUG` env var is set, so use with caution.

##### NPM Install Arguments
NPM install command arguments can be specified by setting the `NPM_INSTALL_ARGS` environment variable with the  desired value.

##### NPM Post Install Scripts
Once `npm install` is executed, you can if desired execute additional scripts by providing a space separated list of target scripts via the `NPM_SCRIPT_POST_INSTALL` environment variable.

#### Webpack Builds
For builds that use webpack, couple of options are available.

Specifying a script name `NPM_SCRIPT_WEBPACK` environment variable, triggers an `npm run <script>` command. This is triggered after post install scripts are run (see above). This can also be provided as the last post install target.

Specifying the `WEBPACK_DEPLOY` environment variable, ensures that only the `<prefix>/dist` directory is copied to the `OPENSHIFT_DEPLOYMENTS_DIR` after build completes. This is useful if you plan on using extended builds.

#### Test Execution
Following the [test strategies defined for S2I builds](https://docs.openshift.com/container-platform/3.5/dev_guide/builds/build_strategies.html#dev-guide-testing-your-application), the assemble script allows for optional test execution before pruning or cleanup occurs to ensure that developer/test dependencies are available for test execution. This is done by specifying `NPM_SCRIPT_TEST` as a valid `npm` script target.

_*Caution:*_ If you choose the `postCommit` hook strategy, be sure that you are not pruning the dependencies required (`NPM_SKIP_PRUNE`).

### S2I Run Script
The default `run` script provided will, switch to the the `OPENSHIFT_DEPLOYMENTS_DIR` and execute `npm start`. You can configure the `npm` command to execute by specifying `NPM_START` environment variable and any arguments to `start` by specifying `NPM_START_ARGS` environment variable.

### Extended Builds
A nifty feature of OpenShift build (via source-to-image) is [extended builds](https://docs.openshift.com/container-platform/3.5/dev_guide/builds/build_strategies.html#extended-builds). The following snippent demonstrates how this can be used, in this particular case a Node.JS codebase is built using the `Source` strategy within the `nodejs-7-s2i` image. Once the assemble stage is completed, artifacts from `/opt/openshift` is copied over to `opt/openshift` in an instance of `nodejs-7` container for s2i run stage. Note that the relative path is used in the latter.

```yaml
strategy:
  type: Source
  sourceStrategy:
    from:
      kind: ImageStreamTag
      namespace: openshift
      name: 'nodejs-7-s2i:latest'
    runtimeImage:
      kind: "ImageStreamTag"
      name: "nodejs-7:latest"
      namespace: openshift
    runtimeArtifacts:
      - sourcePath: "/opt/openshift"
        destinationDir: "opt/"
      - sourcePath: /usr/libexec/s2i
        destinationDir: usr/libexec/
```

### Local S2I Build Example
To use these source-to-image containers to build a working copy of your Node.JS source, you can execute the following command.
```sh
s2i build -e DEBUG=1 -e NPM_SCRIPT_TEST=test <path/to/working/copy> <registry>/<namespace>/nodejs-6-s2i:latest local/my-super-app
```

The following example shows how an runtime image can be used.

```sh
s2i build \
  . \
  docker-registry/openshift/nodejs-7-s2i:latest \
  --runtime-image docker-registry./openshift/nodejs-7:latest \
  --runtime-artifact /opt/openshift:opt/openshift \
  --runtime-artifact /usr/libexec/s2i:usr/libexec/s2i \
  local/my-awesome-app
```
