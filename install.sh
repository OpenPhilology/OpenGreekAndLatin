!#/bin/bash

echo "Install requirements and dependencies."
sudo apt-get install openjdk-7-jdk lynx python-dev g++ libtiff-dev python-wxTools libpng12-dev python-numpy python-scipy python-matplotlib python-setuptools liblept3 imagemagick libfreeimage3 libxml2-dev libxslt1-dev python-libxslt1 libsaxonb-java gzip unzip sbt git gridengine-master gridengine-client gridengine-exec
sudo easy_install mahotas lxml nltk
#
echo -e "--------------------------------\nEnter configuration for Grid Engine."
read -p "Username (needs to be added by root/manager): " SGE_USER
read -p "Hostname (most likely localhost): " SGE_HOST
read -p "Queuename (e.g. ocr.q): " SGE_QUEUE
sudo qconf -am $SGE_USER
qconf -as $SGE_HOST
qconf -au $SGE_USER arusers
qconf -aq $SGE_QUEUE
#
echo -e "--------------------------------\nBuild and install Gamera components."
wget http://downloads.sourceforge.net/project/gamera/gamera/gamera-3.4.0/gamera-3.4.0.tar.gz && tar -xzf gamera-3.4.0.tar.gz && rm gamera-3.4.0.tar.gz
wget http://gamera.informatik.hsnr.de/addons/ocr4gamera/ocr-1.0.6.tar.gz && tar -xzf ocr-1.0.6.tar.gz && rm ocr-1.0.6.tar.gz
cd gamera-3.4.0 && python setup.py build && sudo python setup.py install && cd ..
cd ocr-1.0.6 && python setup.py build && sudo python setup.py install && cd ..
cd bin/rigaudon/Gamera/greekocr-1.0.0 && python setup.py build && sudo python setup.py install && cd ../../../..
#
# If you already have a running Rigaudon instance on your system, then start here.
#
echo -e "--------------------------------\nCompile and package the aggregator."
cd bin/hocrinfoaggregator && sbt clean compile assembly && ln -s target/scala-2.10/hOCRInfoAggregator-assembly-1.0.jar && cd ../..
#
echo -e "--------------------------------\nConfigure and build the proofreader."
echo "Enter database configuration."
read -p "Host (domain:port): " EXIST_HOST
read -p "User: " EXIST_USER
read -p "Password: " EXIST_PWD
echo -e "library=xmldb:exist://${EXIST_HOST}/xmlrpc/db/perseus-ocr\nlogin=${EXIST_USER}\npassword=${EXIST_PWD}" > bin/cophiproofreader/src/main/java/eu/himeros/cophi/ocr/proofreader/controller/bean/resources/config.properties
echo "Install depencies to local repo, then build WAR."
cd bin/cophiproofreader && wget http://roedel.e-humanities.net/~fbaumgardt/jars.zip && unzip jars.zip && sh installdependencies.sh && rm -r jars* && mvn package && cd ../..
#
echo "--------------------------------\nConfigure and build the database."
mkdir db && mkdir db/exist && cd db/exist && wget http://sourceforge.net/projects/exist/files/Stable/2.0/eXist-db-setup-2.0-rev18252.jar/download -O exist-installer.jar && JAVA_HOME=/usr/ && java -jar exist-installer.jar -console && read -p "Set Jetty port (Replace 8080 with a free port, <Return> will open the config file)." && nano -w tools/jetty/etc/jetty.xml && cd ../..
echo "Run exist-db."
db/exist/bin/server.sh &
echo "--------------------------------\nDone."
#
# Remember to deploy Proofreader on LIVE system, not the computational node.
#
echo "--------------------------------\nDeploy proofreader"
echo "Get manager-gui/admin-gui account for Tomcat 7 server. Open http://localhost:8080/manager and deploy the Proofreader WAR."
read -p "Press <Return> to continue OGL installation."