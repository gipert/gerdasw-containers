# gerdasw-containers
[Docker](https://www.docker.com) and [Singularity](http://singularity.lbl.gov) containers with a basic installation of the GERDA software.
### Notes
* MaGe is checked out at `GERDAphaseII` branch
* Repositories which need constant updates (like e.g. metadata repositories) are not included in the images. They can be included e.g. inside an externally mounted volume (see below)
* Let's take advantage of git! Open a new branch if you want to provide an image with different features
* Use git tags to distinguish between software versions?
* Remeber to update `%applabels` sections in `Singularityfile` when updating submodules

## Use instructions
**Clone with `--recursive`** (note: requires access to GERDA's private repositories).

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
Then try for example `singularity help gerdasw.sqsh` or `singularity run gerdasw.sqsh` to start using the
container, for other useful commands (e.g. those reported above for Docker) refer to the [Singularity docs](http://singularity.lbl.gov/quickstart)
or type `singularity help`.

## Enable X11 forwarding
### Mac OSX (Docker):
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

### On a remote host (Docker):
Take a look to the Wiki [here](https://github.com/luigipertoldi/gerda-sw-docker/wiki/The-Docker-local-hub#running-a-container).
