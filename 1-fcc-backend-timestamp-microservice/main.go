// this is an executable program. main entry point is in main() function
package main

//go is a statically typed language, extremely explicit, nothing is available unless imported.
//unlike node, go's builtin library is large and maintained by go team where as node's are often 3rd party.
import (
	//each import is a package.
	"encoding/json" //converts go struct to json strings that fcc reads and vice versa. convert Go data ↔ JSON
	"net/http"      //the actual web server. it listens for requests and sends responses.
	"strconv"       //converts strings to numbers and vice versa. for parsing unix timestamps.
	"strings"       //for manipulating URL paths, like trimming prefixes.
	"time"          //for working with dates and times, parsing date strings, and formatting UTC output.
)

//defining a new "Category" of data.
//if a field starts with a Capital, it is Public (Exported). Unix, UTC, and Error are all public fields that can be accessed outside this package. If they were lowercase, they would be private and not accessible to the JSON encoder.
//Only exported fields can be accessed by other packages (including the JSON encoder).
type Response struct {
	// `json:"fieldname,omitempty"` is a struct tag that tells the JSON encoder how to name the field in the output JSON. The `omitempty` option means that if the field has a zero value (like 0 for int64 or "" for string), it will be omitted from the JSON output.
	Unix int64  `json:"unix,omitempty"`
	UTC  string `json:"utc,omitempty"`
	Error string `json:"error,omitempty"`
}
func handleMainPage(w http.ResponseWriter, r *http.Request) {
    // 1. The Catch-All Protection
    if r.URL.Path != "/" {
        http.NotFound(w, r)
        return
    }

    // 2. The Response
    w.Header().Set("Content-Type", "text/html")
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("<h1>Timestamp Microservice is Active</h1><p>Use /api/:date to test.</p>"))
}
//w -> http.ResponseWriter: an interface to write the HTTP response back to the client. set headers and write the response body using this.
//r -> *http.Request: a pointer to an http.Request struct that contains all the information about the incoming HTTP request: Method, Body, URL, headers, and body.
//app.get("/api/:date?", (req, res) => {
  // req → request
  // res → response});

func handleTimestamp(w http.ResponseWriter, r *http.Request) {
	//trim the prefix from the URL path FOR EXAMPLE: /api/2020-01-01, becomes "2020-01-01". /api/1609459200000 becomes "1609459200000".
	path := strings.TrimPrefix(r.URL.Path, "/api")


	//variable declarations.
	//The word before the dot (time) is the Package Name, and the word after (Time) is the Specific Tool inside it.
	var t time.Time
	//not by import, not a package, error is a Built-in Type, just like int (integers) or string. It is always available.
	var err error

	// No date provided → current time
	if path == "" || path == "/" {
		t = time.Now()
	} else {
		dateStr := strings.TrimPrefix(path, "/")

		//try interpreting dateStr as Unix milliseconds first
		//base 10 means decimal, 64 means we want a 64-bit integer. If the parsing is successful, ms will hold the parsed integer value, and e will be nil. If it fails, e will contain an error.
		if ms, e := strconv.ParseInt(dateStr, 10, 64); e == nil {
			//if successful, convert ms to time.Time using time. 
			t = time.UnixMilli(ms)
			
		} else {
            // THE FIX: Loop through multiple date formats
            layouts := []string{
                "2006-01-02",                  // Format: 2015-12-25
                "02 January 2006, MST",        // Format: 05 October 2011, GMT (The FCC test)
                "02 Jan 2006",                 // Format: 25 Dec 2015
                "January 2, 2006",             // Format: December 25, 2015
                "Mon, 02 Jan 2006 15:04:05 MST", // Format: Full web string
            }

            parsedSuccessfully := false
            
            for _, layout := range layouts {
                t, err = time.Parse(layout, dateStr)
                if err == nil {
                    parsedSuccessfully = true
                    break // Found a match, stop checking
                }
            }

            // If it failed all layouts, throw the error
            if !parsedSuccessfully {
                writeJSON(w, Response{Error: "Invalid Date"})
                return
            }
        }
	}
//valid date → write JSON response with Unix and UTC
	writeJSON(w, Response{
		Unix: t.UnixMilli(),
		UTC:  t.UTC().Format("Mon, 02 Jan 2006 15:04:05 GMT"),
	})
}


////////Everything before this prepares the data.////////////


//sends bytes back to the client over HTTP. It sets the Content-Type header to application/json and encodes the Response struct as JSON in the response body. The object passed to json.NewEncoder(w).Encode() is the Response struct defined earlier, which contains the Unix timestamp, UTC string, and any error message if applicable. 
////The JSON encoder will convert this struct into a JSON string that the client can understand.
func writeJSON(w http.ResponseWriter, resp Response) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}


//func main() must be in package main, must be named main, takes no arguments, and returns no values. It is the entry point of the program, where execution starts when run the compiled binary. In this function, HTTP server will be set up and define the routes that will handle incoming requests.
func main() {
	//HandleFunc -> stores mapping in a global routing table. Associates path prefix with a function. In this case, both "/api/" and "/api" paths are mapped to the handleTimestamp function.
	println("Server starting on port 3001...")
	http.HandleFunc("/", handleMainPage)
	http.HandleFunc("/api/", handleTimestamp)
	http.HandleFunc("/api", handleTimestamp)
	//Handle -> serves static files from the specified directory. It maps the URL path "/public/" to the "./public" directory on the server. When a request is made to a URL starting with "/public/", the server will look for the corresponding file in the "./public" directory and serve it. For example, a request to "/public/image.png" will serve the file located at "./public/image.png". The http.StripPrefix function is used to remove the "/public/" prefix from the URL path before looking for the file in the directory.
	// http.Handle("/public/",
	// 	http.StripPrefix("/public/",
	// 		http.FileServer(http.Dir("./public"))))
	// http.Handle("/", http.FileServer(http.Dir("./views")))

	//ListenAndServe -> starts the HTTP server on the specified address (":3000" means listen on all interfaces on port 3000). It blocks and runs indefinitely, handling incoming requests using the registered handlers. If there is an error starting the server, it will return an error.
	http.ListenAndServe(":3001", nil)

}

//GOOS=linux GOARCH=amd64 go build -o app .
//compiling the files to go binary