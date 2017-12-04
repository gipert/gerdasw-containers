# gerdasw-containers
[Docker](https://www.docker.com) and [Singularity](http://singularity.lbl.gov) containers with a basic installation of the GERDA software.
### Notes
* MaGe is checked out at `GERDAphaseII` branch
* Repositories which need constant updates (like e.g. metadata repositories) are not included in the images. They can be included e.g. inside an externally mounted volume (see below)
* git branches are used to distiguish between software versions
    * `g4.9.6` → CLHEP_v2.1.3.1 and GEANT4_v9.6.p04
    * `g4.10.3` → CLHEP_v2.3.4.4 and GEANT4_v10.3.p03
* Remeber to update `%applabels` sections in `Singularityfile`s when updating submodules TODO: script

### TODO:
- [ ] Move source code from `/scif/src/` to `/scif/<app>/src` in Singularity containers
- [ ] Update all with the new MaGe tag
- [ ] Script to generate Singularity files with correct submodule versioning
- [ ] Find a place to store prebuilded Singularity images

## Docker containers
All the images of this repository can be found at <https://baltig.infn.it/gerda/gerdasw-containers/container_registry>. To download them you must be registered (ask [luigi.pertoldi@pd.infn.it](mailto:luigi.pertoldi@pd.infn.it)), then you can use the following syntax:
```shell
$ sudo docker login baltig.infn.it:4567
$ sudo docker pull baltig.infn.it:4567/gerda/gerdasw-containers/<image>:<tag>
```
Let's say you have pulled the `gerdasw:g4.10.3` image, then a call to `docker run gerdasw:g4.10.3` with no arguments spawns a zsh shell by default:
```shell
$ sudo docker run \
  -i -t --rm \
  -h gerda-sw \
  gerdasw:g4.10.3
```
The `-i` and `-t` flags allow to start an interactive session inside a new tty (mandatory to spawn the shell). The `--rm` flag removes the container after stopping it. Optional: `-h gerdasw` sets the container's hostname to 'gerda-sw'.

Any other custom command can be injected inside the container, e.g.:
```shell
$ sudo docker run gerdasw:g4.10.3 MaGe
```

To mount a folder (`/path/to/src`) inside the container (mount point: `/path/to/dest`) run it with:
```shell
$ sudo docker run \
  -v /path/to/src:/path/to/dest \
  gerdasw:g4.10.3 <...>
```
*NOTE:* on some systems you could find high latency in accessing externally mounted volumes from within the container (see for example [this issue](https://forums.docker.com/t/file-access-in-mounted-volumes-extremely-slow-cpu-bound/8076)). Consider using [Docker volumes](https://docs.docker.com/engine/admin/volumes/volumes/) instead.

**Important**: to make the software fully work inside the container you must mount the following folder structure under `/common`:
```
common/
  '-- sw-other/
        |-- gerdageometry/
        |-- gerda-metadata/
        '-- gerda-ana-sandbox/
```
where the `gerdageometry` can be found in the MaGe source repo. The log in and check that `MGGERDAGEOMETRY`, `MGGENERATORDATA` and `MU_CAL` are set and point to existing locations. You could use the `common/` location to store files that you want to preserve (e.g. MaGe macro files or output).

### Building from source
__Clone this repository with `--recursive`__ (note: requires access to GERDA's private repositories at <https://github.com/mppmu>).

Prebuilded images including ROOT, CLHEP and GEANT4 can be found [here](https://github.com/gipert/baseos-containers). Build up the complete image with:
```shell
$ cd gerdasw-containers
$ sudo docker build --rm . -t gerdasw:<tag>
```

## Singularity containers
Compressed images can be build up with:
```shell
$ cd gerdasw-containers # no joke, do it
$ sudo singularity build gerdasw.sqsh Singularityfile
```
Singularity will perform the build in a hidden directory under `/tmp` and then compress it in a squash-fs format to produce the `gerdasw.sqsh` image, so make sure to have enough disk space. If not, you can first perform the build in another partition:
```shell
$ sudo singularity build --sandbox <custom/dir> Singularityfile
```
And compress the result later:
```shell
$ sudo singularity build gerdasw.sqsh <custom/dir>
```

Try `singularity help gerdasw.sqsh` or `singularity run gerdasw.sqsh` to start using the
container, for other useful commands (e.g. those reported above for Docker) refer to the [Singularity docs](http://singularity.lbl.gov/quickstart)
or type `singularity help`.

You can get informations upon about software included within the container by typing
```shell
$ singularity inspect --app <app-name> gerdasw.sqsh
```
Or specific help with
```shell
$ singularity help --app <app-name> gerdasw.sqsh
```

**Important**: mount the appriopriate folder structure under `/common` to make the software inside the container fully functional (see `--bind` flag). See the Docker section for details.

Singularity tips:
* Remember that your `$HOME` directory is mounted by default onto your containers, configuration dotfiles such as `.bashrc` could be loaded and override environment variables inside the container. The `--cleanenv` flag is your friend.

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
