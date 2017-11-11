# gerdasw-containers
[Docker](https://www.docker.com) and [Singularity](http://singularity.lbl.gov) containers with a basic installation of the GERDA software.
### Notes
* MaGe is checked out at `GERDAphaseII` branch
* Repositories which need constant updates (like e.g. metadata repositories) are not included in the images. They can be included e.g. inside an externally mounted volume (see below)
* Let's take advantage of git! Open a new branch if you want to provide an image with different features
* Use git tags to distinguish between software versions?
* Remeber to update `%applabels` sections in `Singularityfile` when updating submodules

## Use instructions
__Clone with `--recursive`__ (note: requires access to GERDA's private repositories).

### Docker containers
Images can be build up with:
```shell
$ cd gerdasw-containers
$ sudo docker build . -t gerdasw
```
A call to `docker run gerdasw` with no arguments spawns a zsh shell by default:
```shell
$ sudo docker run \
  -i -t \
  -h gerdasw \
  gerdasw
```
The `-i` and `-t` flags allow to start an interactive session inside a new tty (mandatory to spawn the shell). Optional: `-h gerdasw` sets the container's hostname to 'gerdasw'.

Any other custom command can be injected inside the container, e.g.:
```shell
$ sudo docker run gerdasw MaGe
```

To mount a folder (`/path/to/src`) inside the container (mount point: `/path/to/dest`) run it with:
```shell
$ sudo docker run \
  -v /path/to/src:/path/to/dest \
  gerdasw <...>
```

### Singularity containers
Compressed images can be build up with:
```shell
$ cd gerdasw-containers # no joke, do it
$ sudo singularity build gerdasw.sqsh Singularityfile
```
Singularity will perform the build in a hidden directory under `/tmp` and then compress it in a squash-fs format to produce the `gerdasw.sqsh` image. Also, the building of the single packages is done under `/tmp` (see `Singularityfile`), so make sure to have enough disk space. If not, you can first perform the build in another partition:
```shell
$ sudo singularity build --sandbox <custom/dir> Singularityfile
```
And compress the result later:
```shell
$ sudo singularity build gerdasw.sqsh <custom/dir>
```
Additionally you can also delete the build directories step-by-step in `/tmp` by uncommenting the relevant lines in `Singularityfile` (But this will cause a complete reprocessing upon a new build attempt).

Try for example `singularity help gerdasw.sqsh` or `singularity run gerdasw.sqsh` to start using the
container, for other useful commands (e.g. those reported above for Docker) refer to the [Singularity docs](http://singularity.lbl.gov/quickstart)
or type `singularity help`.

You can get informations upon about software included within the container typing
```shell
$ singularity inspect --app <app-name> gerdasw.sqsh
```
Or specific help with
```shell
$ singularity help --app <app-name> gerdasw.sqsh
```

## Enable X11 forwarding in Docker containers
### Mac OSX:
Make sure you have XQuartz installed and running. First get your IP address:
```shell
$ ip=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')
```
Then add your IP adress to the list allowed to make connections to the X server using `xhost`:
```shell
$ xhost +$ip
```
Finally run the container setting the correct `DISPLAY` variable, for example to launch `interface` run:
```shell
$ docker run -e DISPLAY=$ip:0 gerda-sw interface
```
**N.B.**: the `xhost +$ip` instruction grants access to the X server for the specified `ip` address. This could expose your system to security holes if, for example, your IP address gets renewed or you switch network and forget to remove the old IP from the `xhost` list. Take care of your `xhost` list by cleaning it from untrusted IPs (use `xhost -[name]`)!

### On a remote host:
Take a look to the Wiki [here](https://github.com/luigipertoldi/gerda-sw-docker/wiki/The-Docker-local-hub#running-a-container).

### On Linux:
The above script should work, test needed.

## decay0 Docker container
Use the `Dockerfile_decay0` to build up a Docker container with cernlib and decay0:
```shell
$ sudo docker build -f Dockerfile_decay0 . -t decay0
```
Then run it with
```shell
$ sudo docker run --rm decay0
```
N.B. write the output file in an external mounted volume!
