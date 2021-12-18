# OracleDatabase-11g-R2-EE
OracleDatabase-11g-R2-EE Docker Image

# This works again circa 2021 Q4 but requires a manual step
- i figured i'd post my effort in case it helps somebody as desperate as i was to get a legacy version of oracle running for a local dev scenario
- the manual piece is that you must go download the oracle 11g install zips yourself since those can't be automatically pulled from oracle.com via curl (as far as i know, since oracle now has an interactive javascript login cookie flow in front of all downloads)
  - see the notes for [what's required in the Dockerfile bash script](https://github.com/Beej126/OracleDatabase-11g-R2-EE/blob/ee9c5954973c0abebf5956aaf93088b3eef380af/Dockerfile#L32)

# basic "install" steps
- i wasn't super docker savvy yet so thought this might be helpful but it's pretty boilerplate stuff if you're already a docker head
- `docker build` command can pull directly from a github repo... docker build creates a docker "image" based on the Dockerfile instructions
- again, you'll have to fork this repo and edit the Dockerfile as described above before the build can succeed
- once you have that image built, you then `docker run` it with some necessary command line args demonstrated below, to fire up the running instance or oracle linux that hosts the oracle database engine... this running instance is what is really called a "container" in Docker parlance
- the docker run cli will leave you sitting at that instance's shell command line...
- at this point you just need to execute "./entrypoint.sh" which will run through the oracle install and create an initial running database!
- once that's complete you should save that finalized running instance as a new clean image via `docker commit` before you load any data into it so you can "docker run" fresh new copies of an *empty* working oracle 11g ... i.e. whenver you want a blank fresh start
- once you have this working container, you can just "run" it from the docker desktop UI whenever you reboot...
  - and once it's running just start the database via "./start.sh" at it's command line, i.e. **don't run "./entrypoint.sh" anymore after the first time**
- my example docker run command below includes mounting a host folder where i've got my oracle backup "dump" files so i can `impdp` restore 
- fyi, the login/password for this oracle instance is "sys/oracle"

example statements for above:
- `docker build https://your_github_repo_here`
- `docker run -it -p 1521:1521 -p 5500:5500 -p 8080:8080 --privileged -e ORACLE_ALLOW_REMOTE=true -e DISPLAY=your_local_ip_here:0 --name=oracle11g-1 --entrypoint=/bin/bash -v your_local_folder_here:/opt/oracle/dpdump your_github_id/oracledatabase-11g-r2-ee`
- `docker commit oracle11g-1 oracle11g-save`
- oracle sql for creating impdp directory: `CREATE OR REPLACE DIRECTORY import AS '/opt/oracle/dpdump/';`
  - corresponding backup import statement: `impdp \'sys/oracle@$ORACLE_SID as sysdba\' SCHEMAS=BLAH DIRECTORY=IMPORT DUMPFILE=blah_110620_1945_full.dmp METRICS=Y EXCLUDE=USER,TABLE_STATISTICS,VIEW,PROCEDURE,PACKAGE,PACKAGE_BODY,TRIGGER,ROLE_GRANT,GRANT REMAP_TABLESPACE=spl_dyn:users REMAP_TABLESPACE=spl_stat:users REMAP_TABLESPACE=spl_index:users REMAP_TABLESPACE=workarea:users REMAP_TABLESPACE=EDS_RESULTS:users REMAP_TABLESPACE=history:users REMAP_TABLESPACE=DOC_STORAGE:users`

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
