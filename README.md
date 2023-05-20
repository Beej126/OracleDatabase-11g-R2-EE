# OracleDatabase-11g-R2-EE
OracleDatabase-11g-R2-EE Docker Image (actually this repo is an image build source vs the image itself)

- This image is NOT provided in Docker Hub directly... it must be built from this repo, which turns out to be amazingly straightforward anyway (see first command under "example statements" below)
- When you create the FIRST container off this image, you'll run the /entrypoint.sh script that installs oracle 11g along with an initial database.
- Once that's completed you'll most likely want to save that running container state as a new image such that you don't have to do the install again.
- you could probably toss the original image & container at that point.
- then create your main working container to use going forward from that second image...
- and just create new containers from that second image anytime you want to start over with a fresh blank database
- the main reasons a fully working image isn't provided directly are size and licensing because the initial image build requires downloading 2GB of oracle installs
- fyi, my final default database image is resting at 12GB

# This works again circa 2021 Q4 but requires a manual step
- i figured i'd post my effort in case it helps somebody as desperate as i was to get a legacy version of oracle running for a local dev scenario
- the manual piece is that you must go download the oracle 11g install zips yourself since those can't be automatically pulled from oracle.com via curl (as far as i know, since oracle now has an interactive javascript login cookie flow in front of all downloads)
  - see the notes for [what's required in the Dockerfile bash script](https://github.com/Beej126/OracleDatabase-11g-R2-EE/blob/ee9c5954973c0abebf5956aaf93088b3eef380af/Dockerfile#L32)

# basic "install" steps
- just fyi, i executed this on windows 11, wsl2 based docker desktop, which is a true linux host vm so this should all work on any linux based docker installation
- i wasn't super docker savvy yet so thought this might be helpful but it's pretty boilerplate stuff if you're already a docker head
- `docker build` command can pull directly from a github repo... docker build creates a docker "image" based on the Dockerfile instructions
- again, you'll have to fork this repo and edit the Dockerfile as described above before the build can succeed
- once you have that image built, you then `docker run` it with some necessary command line args demonstrated below, to fire up the running instance of oracle linux that hosts the oracle database engine... this running instance is what is really called a "container" in Docker parlance
- the docker run cli will leave you sitting at that instance's shell command line...
- at this point you just need to execute "/entrypoint.sh" which will run through the oracle install and create an initial running database!
- once that's complete you should save that finalized running instance as a new clean image via `docker commit` before you load any data into it so you can "docker run" fresh new copies of an *empty* working oracle 11g ... i.e. whenver you want a blank fresh start
- once you have this working container, you can just "run" it from the docker desktop UI whenever you reboot...
  - and once it's running just start the database via "/start.sh" at it's command line, i.e. **don't run "/entrypoint.sh" anymore after the first time**
- my example docker run command below includes mounting a host folder where i've got my oracle backup "dump" files so i can `impdp` restore 
- fyi, the login/password for this oracle instance is "sys/oracle"

example statements for above:
- `docker build https://your_github_repo_here`
- `docker run -it -p 1521:1521 -p 5500:5500 -p 8080:8080 --privileged -e ORACLE_ALLOW_REMOTE=true -e DISPLAY=your_local_ip_here:0 --name=oracle11g-1 --entrypoint=/bin/bash -v your_local_folder_here:/opt/oracle/dpdump your_github_id/oracledatabase-11g-r2-ee`
- `docker commit oracle11g-1 oracle11g-save`
- oracle sql for creating impdp directory: `CREATE OR REPLACE DIRECTORY import AS '/opt/oracle/dpdump/';`
  - corresponding backup import statement: `impdp \'sys/oracle@$ORACLE_SID as sysdba\' SCHEMAS=BLAH DIRECTORY=IMPORT DUMPFILE=blah_110620_1945_full.dmp METRICS=Y EXCLUDE=USER,TABLE_STATISTICS,VIEW,PROCEDURE,PACKAGE,PACKAGE_BODY,TRIGGER,ROLE_GRANT,GRANT REMAP_TABLESPACE=spl_dyn:users REMAP_TABLESPACE=spl_stat:users REMAP_TABLESPACE=spl_index:users REMAP_TABLESPACE=workarea:users REMAP_TABLESPACE=EDS_RESULTS:users REMAP_TABLESPACE=history:users REMAP_TABLESPACE=DOC_STORAGE:users`
- login to sql plus as sys: `gosu oracle sqlplus sys/oracle as sysdba`
  - [gosu](https://stackoverflow.com/questions/36781372/docker-using-gosu-vs-user/37931896#37931896) is apparently a docker compatible "su", i'm probably using it wrong
- enable sys.utl_mail: https://asktom.oracle.com/pls/apex/asktom.search?tag=sending-mail-using-utl-mail
  ```
  gosu oracle sqlplus sys/oracle as sysdba
  SQL> @$ORACLE_HOME/rdbms/admin/utlmail.sql
  SQL> @$ORACLE_HOME/rdbms/admin/prvtmail.plb
  SQL> grant execute on utl_mail to xxxx;
  ```
  
# migrating populated database to another host
- there are at least a couple different ways to "export"... `docker save` and `docker export`... save works on images, export works on containers and in my experience had the beneficial side effect of a MUCH SMALLER export file and resulting image upon load, [apparently it drops the "metadata and history of the image" and "flattens" the layers](https://www.tutorialspoint.com/how-to-flatten-a-docker-image). simple CLI example: `docker export oracle11g -o oracle11g.tar` this tar would then be imported via `docker import e:\oracle11g.tar oracle11g`, this will create a new instance which would then be `run` to have a working container. here is the full blow run command i use:
  ```
  docker run --name=oracle11g --hostname=f7d85c6a6dda --mac-address=02:42:ac:11:00:02 --env=ORACLE_ALLOW_REMOTE=true --env=DISPLAY=your_local_ip_here:0 --env=PATH=/u01/app/oracle/product/11.2.0/db_1/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin --env=ORACLE_BASE=/u01/app/oracle --env=ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1 --env=ORACLE_HOME_LISTNER=/u01/app/oracle/product/11.2.0/db_1 --env=ORACLE_SID=orcl --env=ORACLE_SRC_INSTALL_DIR=/install/database --env=TZ=Etc/GMT-3 --env=INIT_MEM_PST=40 --env=SW_ONLY=false --volume=C:\save\repos\KingCounty\PROD_ORACLE_BACKUPS:/opt/oracle/dpdump/oracledatabase-11g-r2-ee --privileged -p 1521:1521 -p 5500:5500 -p 8080:8080 --restart=no --runtime=runc -t -d oracle11g /start.sh
  ```
  1. pay attention to the hostname - it would drift as i created different instances and containers but the listener.ora file deep in the $ORACLE_HOME path (/u01/app/oracle/product/11.2.0/db_1/network/admin) is configured to this f7d85c6a6dda hostname so they must be kept in sync. i prefer setting the hostname vs editing the file.
  2. the very last arg is the startup script: `/start.sh`. once that's been set into a container, it will persist for subsequent runs. i've edited it to use a simple trick of shelling out to bash at the end to leave the process open so docker doesn't end and shutdown the container.
  3. the volume arg is how we can map a path internal to the container filesystem to a host filesystem path... this is then how we can facilitate connecting new database backups to be restored into the oracle instance

# clearing out space of old images and containers
- first do the obvious deletes in docker desktop... then stop and restart docker desktop and hopefully that it reliable in the latest version, otherwise...
- good reference: https://stackoverflow.com/questions/36799718/why-removing-docker-containers-and-images-does-not-free-up-storage-space-on-wind
- these are the usual commands but all of them reported 0B freed for me
  ```
  docker container prune -f
  docker image prune -f
  docker volume prune -f
  docker system prune --volumes
  ```
  MAKE SURE TO RESTART Docker Desktop, that's when the space is finally released.

# helpful references
- https://programmer.group/install-oracle-11g-using-docker.html
- https://github.com/jaspeen/oracle-11g
- https://github.com/Fangrn/OracleDatabase-11g-R2-EE/blob/master/entrypoint.sh
- https://www-its203-com.translate.goog/article/u011078141/118525418?_x_tr_sl=zh-CN&_x_tr_tl=en&_x_tr_hl=en&_x_tr_pto=sc
- https://github.com/oracle/docker-images/issues/396
- https://hub.docker.com/layers/alanpeng/oracledatabase-11g-r2-ee/latest/images/sha256-72c3a7c5f2e6abfa2b0a07e7cba167d50c4a844b8511200a05f2a47fdbe9e029?context=explore
- https://stackoverflow.com/questions/6288122/checking-oracle-sid-and-database-name
- https://docs.docker.com/engine/reference/commandline/build/
- https://dev.to/kimcuonthenet/move-docker-desktop-data-distro-out-of-system-drive-4cg2
- https://mybrainimage.wordpress.com/2017/02/05/docker-change-port-mapping-for-an-existing-container/
  - under wsl2 docker engine, containers & their config.v2.json files (where you can tweak port#'s) are at this path: `\\wsl.localhost\docker-desktop-data\version-pack-data\community\docker\containers\`
  - make sure you stop your container, make the file edit and then do a **Restart Docker** from the docker desktop task tray icon before restarting the container to make sure changes take hold
