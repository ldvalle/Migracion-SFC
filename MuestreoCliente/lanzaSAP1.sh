#! /bin/sh
#JAVA_HOME=/usr/java6/bin
JAVA_HOME=/usr/java6/jre/bin/
export JAVA_HOME
          
CLASSPATH=/home/ldvalle/locks/java/SAP1/bin
#CLASSPATH=${CLASSPATH}:/home/ldvalle/locks/java/SAP1/bin/connectBD
#CLASSPATH=${CLASSPATH}:/home/ldvalle/locks/java/SAP1/bin/connectionBDInformix
#CLASSPATH=${CLASSPATH}:/home/ldvalle/locks/java/SAP1/bin/dao
#CLASSPATH=${CLASSPATH}:/home/ldvalle/locks/java/SAP1/bin/entidades
#CLASSPATH=${CLASSPATH}:/home/ldvalle/locks/java/SAP1/bin/servicios
CLASSPATH=${CLASSPATH}:/home/ldvalle/locks/java/SAP1/lib/ifxjdbc.jar
export CLASSPATH

$JAVA_HOME/java -Xmx1024m -cp $CLASSPATH edesur.PreMigra "$@"
