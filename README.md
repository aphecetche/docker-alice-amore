# Introduction 

The `docker-alice-online` project is intended to provide a development setup
for the online monitoring agents and detector algorithms of the CERN ALICE 
experiment.

Using a set of docker containers, the main online services are ran so 
the runtime environment of the piece of code that are developped (either AMORE agents
 or DAs) is as faithfull to production as reasonably achievable and/or desirable.
 
 But note that this project can not ensure any applicability to all
  software developments. Again the main intent is about easing the development of
   AMORE agents and DAs. So far it has served well his author, at least ;-)

Also, the documentation below assumes you know what AMORE is, what a DA is, and
 how to develop both on a "regular" SLC6 machine.

# Requirements

You must have [docker](http://www.docker.com/products/docker) and [docker-compose](https://github.com/docker/compose/releases)
installed on your machine (if you are on a Mac, [Docker for Mac beta](https://download.docker.com/mac/beta/Docker.dmg)
brings you both.

In order to get X11 display working you need to add your machine IP to xhost. That is done automatically by the
functions in `alice-online-functions`, but for this to work on Mac, you need to install one package that will mimic
the `ip` linux command  :

```bash
brew install iproute2mac
```

where we assume that you have `brew` installed on you Mac, of course ;-) 

# Installation 

After having installed Docker on your machine, you should then `git clone` this
 project on your machine.
 
```bash
> git clone https://github.com/aphecetche/docker-alice-online.git
> cd docker-alice-online
```

Of particular interest in the `docker-alice-online` directory are the `docker-compose.yml`
 which is the main file to steer the containers and `alice-online-functions.sh` which 
 defines a bunch of convenience functions to work with the created containers.

Before you can use the thing, you have to :

- build the images upon which the containers are created
- populate the data volumes used by the containers

Let's first
 source the `alice-online-functions.sh` script to get some helper functions defined.

```bash
. ./alice-online-functions.sh
```

Then use the `bootstrap` function to perform the necessary (one-time only) 
 operations

```bash
ali_bootstrap
```

Depending on your network bandwith (and/or your machine CPUs) this can take a while, 
 as some images are being downloaded and other ones are being built.

You can see which images have been built/downloaded :

```
laurent@arch ~/docker-alice-online $ docker images
REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
alice-online-devel            latest              921a8abd3e86        10 minutes ago      5.006 GB
alice-amore                   latest              5c95b69db66e        3 hours ago         4.297 GB
alice-date                    latest              30d5eba44f5e        4 hours ago         907.7 MB
mysql                         5.6                 6d4770ef651a        2 weeks ago         328.8 MB
centos                        6.7                 fb5054b394b7        9 weeks ago         190.6 MB
phpmyadmin/phpmyadmin         4.6.3-1             973ec7124fc8        9 weeks ago         57.01 MB
```

To check the bootstraping was successfull, just use `docker-compose` to launch the
 `phpMyAdmin` service (which will launch the DB service as well as a dependency)
 to get a peek into the created databases.

```
docker-compose up -d  phpmyadmin
```

And point your browser to [localhost:8080](localhost:8080), using (root,date) as 
 credentials to enter phpMyAdmin. You should be able to see the created databases : 
 DATE_CONFIG, DATE_LOG, ECS_CONFIG, LOGBOOK, and AMORE, as well as their respective tables
 (use phpmyadmin to navigate in those tables).


# Usage 

The normal usage (once everything has been bootstrapped correctly) is to launch the set of containers 
using the `docker-compose up` command (the -d flag, as in `daemon` is 
used to launch containers in detached mode).
 
```bash
> docker-compose up -d
```

You should then check that indeed your containers are started (note that all 
docker-compose commands should be issued from the directory that has the docker-compose.yml
file, i.e. the docker-alice-online directory).

```bash
> docker-compose ps
                Name                               Command               State           Ports
------------------------------------------------------------------------------------------------------
dockeraliceonline_agentrunner_1         /amore_setup.sh /usr/sbin/ ...   Up
dockeraliceonline_amore-web_1           /amore_setup.sh httpd -DFO ...   Up       0.0.0.0:8100->80/tcp
dockeraliceonline_archiver_1            /amore_setup.sh amoreArchi ...   Up
dockeraliceonline_dadev_1               /amore_setup.sh /usr/sbin/ ...   Up
dockeraliceonline_daqfxs_1              /usr/sbin/sshd -D                Up
dockeraliceonline_datedb_1              docker-entrypoint.sh mysqld      Up       3306/tcp
dockeraliceonline_dim_1                 /dim_setup.sh                    Up
dockeraliceonline_infologger_1          /infologger_setup.sh             Up
dockeraliceonline_phpmyadmin_1          /run.sh                          Up       0.0.0.0:8080->80/tcp
```

The services (in containers) that are started by the command above, from top to bottom in the list above:

- agentrunner : this one fakes a dqm machine that run one or more agents.
- amore-web : the web server for the amore web tools
- archiver : the AMORE archiver
- dadev : can be seen as a light virtual machine with everything pre-installed to 
develop a DA
- daqfxs : a simple machine to act as the DAQ File eXchange Server (use for the
output the DAs)
- datedb : a MySQL server with DATE, AMORE and LOGBOOK databases 


Note that the 3 main online databases are handled by the same "machine" (datedb),
for the sake of simplicity of this dev. setup. Nothing prevents to change that
 to a more realistic scenario with one server for each database, if need be 
 (just change the relevant docker-compose.yml)

# ali_bootstrap details

You can skip this section if everything works as expected ;-)

The `ali_bootstrap` function is performing the following operations, so if something goes wrong, you may want to
explicitely try that one operation alone to debug further :

- "Make the vc_* volumes" ali_make_volumes 
- "Make all the images" ali_make_images 
- "Make and populate DATE DB" ali_make_datedb 
- "Make and populate AMORE DB" ali_make_amoredb 
- "Make some agents (e.g. MCHQAshifter)" ali_make_agents 
- "Bringing up date DB" ali_up_datedb 
- "Installing DA MCH-BPEVO" ali_install_da MCH-BPEVO 
- "Installing DA MCH-OCC" ali_install_da MCH-OCC 
- "Installing DA MCH-PED" ali_install_da MCH-PED 
- "Installing some amore_modules" ali_install_amore_modules QA MCH MTR TRI DB 

A typical thing to check if whether the various `vc_` volumes have been corrected set up. To look at a volume, one way
is : 

```
> docker run -it --rm -v vc_amore_site:/data centos:6.7 /bin/bash

root@somenumber /]# ls -alR /data
root@somenumber /]# exit
```

Please note that :
- this works independently of whether or not you have done `docker-compose up -d`
- you can use whatever image in place of `centos:6.7` if you'd like to, but that one is nice because you know you have
    it already

# Developing in containers

## Amore and/or Amore modules

In order to be able to develop your code, the idea is that you checkout it locally
 and then mount it in the container where it is built (and is stored in a data volume).

The local location of the source code is expected to be found in some environment variables  defined in the `ali_dev_env` function in `alice-online-functions.sh`) 


| env variable name | default value |
|-------------------|---------------|
| ALI_DEV_ENV_PATH_AMORE | $HOME/alicesw/run2/amore |
| ALI_DEV_ENV_PATH_AMORE_MODULES | $HOME/alicesw/run2/amore_modules |
| ALI_DEV_ENV_PATH_DOTGLOBUS | $HOME/.globus |
| ALI_DEV_ENV_PATH_ALIROOT_DATE | $HOME/alicesw/run2/aliroot-date |


For instance, if you try to enter a container used to develop amore using the `ali_amore_dev` command,
you'll most probably be greeted with an error :

```
> ali_amore_dev
Directory /home/laurent/alicesw/run2/amore_modules does not exist !
```

At this point what you have to do is checkout the relevant code in the right directory (or define accordingly the
environment variables above if you do not use the default locations)

```
> mkdir -p $HOME/alicesw/run2
> cd $HOME/alicesw/run2
> svn checkout --username your_cern_username https://svn.cern.ch/reps/alicedaq/Software/amore/trunk amore
> svn checkout https://svn.cern.ch/reps/alicedaq/Software/amore_modules/trunk amore_modules
```

(you only need to specify your CERN username the first time you make a checkout from a CERN svn repository, and only
if your username on your local machine is different from your CERN username)

Once this is done, you should be able to enter your development container :

```
> ali_amore_dev
w.x.y.z being added to access control list
[root@6989af44b3c4 /]# 
```

The number after `root@` will be different on your machine (and each time you restart the containers), as it's the
id of the container. It's also the hostname of that "machine". If you want/need to change it, you can, using the
first argument of the `ali_amore_dev` command.


```
> ali_amore_dev mybeautifulcontainer
w.x.y.z being added to access control list
[root@mybeautifulcontainer /]# 
```

All the interesting directories are to be found at the root directory in the container : 

```
[root@mybeautifulcontainer /]# ls /
amore amoreSite amore_modules ...
[root@mybeautifulcontainer /]# cd /amore
[root@mybeautifulcontainer /]# make
[root@mybeautifulcontainer /]# make install
```

The last command installs amore into `/opt/amore` "as usual". Except that this 
`/opt/amore` is actually residing on a data volume that has been mounted into the container (and thus its live cycle
is independent of that of the container).

If you are on Linux (and did not change the location of Docker runtime `/var/lib/docker`), you can have a feeling for that using : 

```
> sudo ls -al /var/lib/docker/volumes/vc_amore_opt/_data 
```

The `vc_` prefix is not docker-defined, but is a convention I'm using to denote Volume Containers.

One last thing to get a working Amore agent is to setup the vc_amore_cdb volume. That step is a little manual so far,
because we need to know the source OCDB. For instance : 

```
docker-compose up -d agentrunner
docker cp $HOME/alicesw/run2/aliroot-date/AliRoot/OCDB/GRP dockeraliceonline_agentrunner_1:/local/cdb
docker cp $HOME/alicesw/run2/aliroot-date/AliRoot/OCDB/MUON dockeraliceonline_agentrunner_1:/local/cdb
```

And also (depending on how your agent is setup in the docker-compose.yml file), copy some raw data to `vc_amore_site` :

```
docker cp /alice/data/2016/LHC16j/000256289/raw/16000256289037.8802.raw dockeraliceonline_agentMCHQAshifter_1:/amoreSite/
```

So far so good for amore and amore modules. 

## Detector Algorithms (DA)

Now for the DA it's getting a bit more involved as you have to build your AliRoot for developing them...

> You need a sizeable amount of free disk space, 
> as one build/installation of AliRoot with DAs take about 40 GB 
> of disk...
> This is due to the fact that DAs are statically linked, thus one DA
> executable is about 200 MB. And, at the time of this writing,
> there are 57 DAs... so that's already more than 12 GB just for DA
> executables...

```
> (docker-compose up -d)
> ali_da_dev
cd /alicesw
aliBuild -z date build AliRoot -d --disable AliEn-Runtime,GEANT4_VMC,GEANT3,fastjet,GCC-Toolchain,Vc --defaults daq
alienv enter AliRoot/latest-date-daq
```

Note that alien has been disabled. It's a slight inconvenience (i.e. you won't be able to access files directly from
alien) but with alien enabled I was not able to compile...

Next time you enter the `dadev` container using `ali_da_dev` the `alienv enter` bit will be done automatically.



