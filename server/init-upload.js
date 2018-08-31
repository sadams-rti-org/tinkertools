//file:/server/init.js
Meteor.startup(function () {
    UploadServer.init({
        tmpDir: process.env.PWD + '/.private/graphs/tmp',
        uploadDir: process.env.PWD + '/.private/graphs',
        checkCreateDirectories: true //create the directories for you
    })
});