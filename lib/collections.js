Scripts = new Mongo.Collection('scripts');
//Scripts DB is a table of UserID, ServerURL, GraphName, ScriptName, ScriptCode, TinkerPopVersion
Books = new Mongo.Collection('books');
//Books DB is a table of UserID, ServerURL, BookName, Book{recipes:[{recipeName: ' the recipe', scripts:[{scriptName: 'the name', scriptCode: 'the code'}, more...]}, more...]}


