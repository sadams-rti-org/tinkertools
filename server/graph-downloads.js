var fs = Npm.require('fs');
var fail = function(response) {
    response.statusCode = 404;
    response.end();
};

var dataFile = function() {
    // TODO write a function to translate the id into a file path
    where = process.env.PWD +"/.private/graphs/"
    var file = where+this.params.id;
    console.log('*******PWD***************',process.env.PWD,'****************************');

    // Attempt to read the file size
    var stat = null;
    try {
        stat = fs.statSync(file);
    } catch (_error) {
        return fail(this.response);
    }

    // The hard-coded attachment filename
    var attachmentFilename = this.params.id;

    // Set the headers
    this.response.writeHead(200, {
        'Content-Type': 'application/xml',
        'Content-Disposition': 'attachment; filename=' + attachmentFilename,
        'Content-Length': stat.size
    });

    // Pipe the file contents to the response
    var xx=fs.createReadStream(file);
    xx.pipe(this.response);
};

Router.route('/graphs/:id', dataFile, {where: 'server'});