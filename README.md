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

This can take a moment or two (as some images are being downloaded and another is being built).

To check the bootstraping was successfull, just use `docker-compose` to launch the
 DB service, and also the `phpMyAdmin` service to get a peek into the created 
 databases.

```
docker-compose up -d datedb phpmyadmin
```

And point your browser to [localhost:8080](localhost:8080), using (root,date) as 
 credentials to enter phpMyAdmin. You should be able to see the created databases : 
 DATE_CONFIG, DATE_LOG, ECS_CONFIG and LOGBOOK, as well as their respective tables
 (use phpmyadmin to navigate in those tables).

# Usage 

The normal usage (once everything is setup) is to launch the set of containers 
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
-

Note that the 3 main online databases are handled by the same "machine" (datedb),
for the sake of simplicity of this dev. setup. Nothing prevents to change that
 to a more realistic scenario with one server for each database, if need be 
 (just changed the relevant docker-compose.yml)
