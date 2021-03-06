![](https://github.com/ssadams11/tinkertoolsOSS/blob/master/public/tinkertools-logo.png)

Tinkertools 3.2.1, even more graphie goodness!
============================================

Tinkertools is a tool for knowledge graph developers. It can communicate with
Tinkerpop-compliant graph databases using REST. Tinker tools allows users to
create accounts where they can create, edit, execute and share Gremlin scripts
for any graph database they can access. Tinker tools allows a user to run a
gremlin query, examine the results as JSON, and visualize the results as an
interactively editable network.

 

Installing Tinkertools 3.2.1
--------------------------

### Using Docker to run Tinkertools on a workstation/laptop

On a laptop with docker installed, download the docker image file (link provided via email on request) and then import it to your local docker system using:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
docker load -i tinkertools3.2.1.image
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you already have a mongo container running, say at the standard port of 271017, you can launch Tinkertools using:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
docker run -d -p 80:3000 --name=my-local-tinkertools -e ROOT_URL=http://your-laptops-ip-address-NOT-localhost-NOR-127.0.0.1 -e MONGO_URL=mongodb://your-laptops-ip-address-NOT-localhost-NOR-127.0.0.1:27017/tinkertools tinkertools3.2.1
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
You can change port 80 above to whatever local workstation port you'd like

If you don't have a mongo container running, you can pull and run the latest from docker hub using:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
docker run --name=my-local-mongo -p 27017:27017 -d mongo
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
If you want to run a separate mongo container from what you have, then select a different port number like 27018:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
docker run --name=my-local-mongo -p 27018:27017 -d mongo
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Then you would need to launch Tinkertools with that mongo port (note 27018 in the following):
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
docker run -d -p 80:3000 --name=my-local-tinkertools -e ROOT_URL=http://your-laptops-ip-address-NOT-localhost-NOR-127.0.0.1 -e MONGO_URL=mongodb://your-laptops-ip-address-NOT-localhost-NOR-127.0.0.1:27018/tinkertools tinkertools3.2.1
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

That's it!  Aim your browser at http://localhost:YOUR-CHOSEN-TINKERTOOLS_PORT
And you will see the Tinkertools splash screen.

Link to video demo coming soon!

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

### Using Docker to manage Tinkertools on a server

On a system with docker installed, move your tinkertools.tar.gz file to a
directory and then:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
docker run -d -e ROOT_URL=http://your-tinkertools-server-url-goes-here.com -e MONGO_URL=mongodb://admin:mongo4tinkertools@your-mongo-server-goes-here.com:27017 -v ~/:/bundle -p 80:80 --restart=always --name=tinkertools meteorhacks/meteord:base
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

replacing the ROOT\_URL and MONGO\_URL locations appropriately

Or, if you want to run Tinkertools in embedded mode, where only a specified
graph database is allowed, use:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
docker run -d -e EMBEDDED_GRAPH_SERVER_URL=http://your-graph-server-url-goes-here.com:8182 -e ROOT_URL=http://your-tinkertools-server-url-goes-here.com -e MONGO_URL=mongodb://admin:mongo4tinkertools@your-mongo-server-goes-here.com:27017 -v ~/:/bundle -p 80:80 --restart=always --name=tinkertools meteorhacks/meteord:base
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

again, replacing ROOT\_URL, MONGO\_URL and EMBEDDED\_GRAPH\_SERVER\_URL. Don’t
forget the port number on the graph server URL, typically 8182.


