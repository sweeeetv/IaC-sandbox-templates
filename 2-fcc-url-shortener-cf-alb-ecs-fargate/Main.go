// main entry point for this executable
// Execution always kicks off in package main
package main //special, mandatory name, tells the Go compiler that the application starts here.
//If there is no main package, you have a library, not a runnable program.

import (
	"context"
	"fcc-backend-url-shortener/handler"
	"fcc-backend-url-shortener/store"
	"log"
	"os"

	"net/http" //standard library, go already includes this in its global installation toolchain.

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/redis/go-redis/v9"
	//by convention, the last element of the import path is the package name. the 'net/http' package comprises files that begin with the statement 'package http'
	//use an alias if the last name is the same:
	//webhttp 'web/http'
)

// CORS middleware to handle preflight requests and set appropriate headers, since cloudfront does not support OPTIONS method
//next means the next handler in the chain, which will be called if the request is not an OPTIONS request.
func corsMiddleware(next http.Handler) http.Handler { //corsMiddleware(http.DefaultServeMux) -> this means that the middleware will wrap the default HTTP request multiplexer (ServeMux), which is the default router in Go's net/http package. The ServeMux is responsible for routing incoming HTTP requests to the appropriate handler based on the request's URL path.
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		//Every request enters here first.
		//although these headers only needed for preflight, but it is harmless to set them on all the replies.
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		//this runs only if its OPTIONS
		if r.Method == http.MethodOptions { //this checks if the incoming request is an OPTIONS request,  a preflight request sent by browsers to determine if the actual request is safe to send. If it is an OPTIONS request, the middleware responds with a 204 No Content status and does not call the next handler in the chain.
			w.WriteHeader(http.StatusNoContent)
			return // If it's OPTIONS: middleware writes 204 No Content immediately and returns — it never calls next.ServeHTTP(w, r)
		}

		//this runs if its not OPTIONS
		next.ServeHTTP(w, r) //this  calls the next handler in the chain - the actual request handler (e.g., RedirectHandler or ShortenerHandler). It passes the ResponseWriter and Request to that handler, allowing it to process the request and generate a response.
	})
}

func main() {

	ctx := context.Background() //this is a root context, which is never canceled, has no values, and has no deadline. It is typically used by the main function, initialization, and tests, and as the top-level Context for incoming requests.

	cfg, err := config.LoadDefaultConfig(ctx) // builds an AWS config object (region, credentials, retry settings)
	if err != nil {
		log.Fatalf("failed to load AWS config: %v", err) //can not connect to aws, usually because of missing credentials or misconfigured region. log.Fatalf() prints the message and exits the program with a non-zero status code.
	}
	dynamoClient := dynamodb.NewFromConfig(cfg) //ctg is the AWS SDK's configuration object, which contains all the information needed to make requests to AWS services. dynamodb.NewFromConfig(cfg) creates a new DynamoDB client using that configuration. This client is used to interact with DynamoDB, allowing the application to perform operations like reading and writing items in a DynamoDB table.

	tableName := os.Getenv("DYNAMO_TABLE")
	redisAddr := os.Getenv("REDIS_ADDR")
	if tableName == "" || redisAddr == "" {
		log.Fatal("DYNAMO_TABLE and REDIS_ADDR env vars must be set")
	} //this will appear
	rdb := redis.NewClient(&redis.Options{Addr: redisAddr}) //create a Redis client

	s := store.New(dynamoClient, tableName, rdb)
	h := handler.New(s)

//underneath: http.DefaultServeMux.HandleFunc(...), using default mux
	http.HandleFunc("/api/shorturl/", h.RedirectHandler)
	http.HandleFunc("/api/shorturl", h.ShortenerHandler)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK) //doesn't touch Dynamo/Redis — ALB health check must stay fast/independent
		w.Write([]byte("OK"))
	})

	log.Println("listening on :8080")
	//http.ListenAndServe(address, handler)
	log.Fatal(http.ListenAndServe(":8080", corsMiddleware(http.DefaultServeMux)))
	//http.ListenAndServe(":8080", nil) -> just use http.DefaultServeMux, no middleware wrapper.
}












// func main(){
// 	http.HandleFunc("/api/shorturl/", handler.RedirectHandler)
// 	http.HandleFunc("/api/shorturl", handler.ShortenerHandler)
// 	http.HandleFunc("/health", func (w http.ResponseWriter, r*http.Request){
// 		w.WriteHeader(http.StatusOK)
// 		w.Write ([]byte("OK")) //
// 	})
// 	http.ListenAndServe(":8080", nil) //starts the web server, must be the last part.
// }


//test:
//curl -X POST https://d1mko2gkzv7pil.cloudfront.net/api/shorturl -d '{"url":"https://google.com"}'
//curl -L https://d1mko2gkzv7pil.cloudfront.net/api/shorturl/8LwzYB




//http.Redirect(w, r, url, http.StatusPermanentRedirect)