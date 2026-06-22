//what is a go.mod file? project's dependency manifest. Its primary job is defining the base module identity for your root folder. basically just to tell the files in the folder the name of the module or the root folder's name.
//for 3rd party libs,it must be recorded here so the version and the web address will be constent.
//Inside go.mod, the first line declares the root name: module fcc-backend-url-shortener.
//Go files do not inherently know their parents; they rely entirely on the go.mod file to define the project's root identity.
//standard libraries never change as long as you use that version of Go. fmt will always be fmt.

module fcc-backend-url-shortener

go 1.26.1 //this locks down the version
