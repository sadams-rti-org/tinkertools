![](https://github.com/ssadams11/tinkertoolsOSS/blob/master/public/tinkertools-logo.png)

Tinkertools 3.0, even more graphie goodness!
============================================

Tinkertools is a tool for knowledge graph developers. It can communicate with
Tinkerpop-compliant graph databases using REST. Tinker tools allows users to
create accounts where they can create, edit, execute and share Gremlin scripts
for any graph database they can access. Tinker tools allows a user to run a
gremlin query, examine the results as JSON, and visualize the results as an
interactively editable network.

 

Installing Tinkertools 3.0
--------------------------

### Running from the source directory

Tinkertools was developed using [Meteor](https://www.meteor.com/), and as such
is a Javascript, Node.js application. You can clone this repository on a system
where npm and meteor are installed and simply enter the command `meteor` within
the source directory.

### Using a Meteor Bundle

The meteor bundle`tinkertools.tar.gz` , in the main directory, was created using
the following command:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
meteor build --architecture=os.linux.x86_64 ./
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can move that file to any target Linux system with node.js installed and use
the following command to launch it:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
export MONGO_URL=mongodb://localhost:27017/<dbname>
export PORT=<server_port>
export ROOT_URL=http://bluehair3.sl.cloud9.ibm.com/
forever start bundle/main.js
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Using Docker to manage Tinkertools

On a system with docker installed, move your tinkertools.tar.gz file to a
directory and then:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
docker run -d -e ROOT_URL=http://bluehair3.sl.cloud9.ibm.com -e MONGO_URL=mongodb://admin:mongo4tinkertools@ssa-mongo.sl.cloud9.ibm.com:27017 -v ~/:/bundle -p 80:80 --restart=always --name=tinkertools meteorhacks/meteord:base
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

replacing the ROOT\_URL and MONGO\_URL locations appropriately

Or, if you want to run Tinkertools in embedded mode, where only a specified
graph database is allowed, use:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
docker run -d -e EMBEDDED_GRAPH_SERVER_URL=http://bluehair5.sl.cloud9.ibm.com:8182 -e ROOT_URL=http://bluehair3.sl.cloud9.ibm.com -e MONGO_URL=mongodb://admin:mongo4tinkertools@ssa-mongo.sl.cloud9.ibm.com:27017 -v ~/:/bundle -p 80:80 --restart=always --name=tinkertools meteorhacks/meteord:base
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

again, replacing ROOT\_URL, MONGO\_URL and EMBEDDED\_GRAPH\_SERVER\_URL. Don’t
forget the port number on the graph server URL, typically 8182.
