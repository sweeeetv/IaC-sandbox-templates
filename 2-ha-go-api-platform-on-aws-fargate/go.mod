//what is a go.mod file? project's dependency manifest. Its primary job is defining the base module identity for your root folder. basically just to tell the files in the folder the name of the module or the root folder's name.
//for 3rd party libs,it must be recorded here so the version and the web address will be constent.
//Inside go.mod, the first line declares the root name: module fcc-backend-url-shortener.
//Go files do not inherently know their parents; they rely entirely on the go.mod file to define the project's root identity.
//standard libraries never change as long as you use that version of Go. fmt will always be fmt.

module fcc-backend-url-shortener

go 1.26 //this locks down the version

//more dependencies:

require (
	github.com/aws/aws-sdk-go-v2 v1.42.1 // indirect
	github.com/aws/aws-sdk-go-v2/config v1.32.30 // indirect
	github.com/aws/aws-sdk-go-v2/credentials v1.19.29 // indirect
	github.com/aws/aws-sdk-go-v2/feature/ec2/imds v1.18.30 // indirect
	github.com/aws/aws-sdk-go-v2/internal/configsources v1.4.30 // indirect
	github.com/aws/aws-sdk-go-v2/internal/endpoints/v2 v2.7.30 // indirect
	github.com/aws/aws-sdk-go-v2/internal/v4a v1.4.31 // indirect
	github.com/aws/aws-sdk-go-v2/service/dynamodb v1.60.1 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/accept-encoding v1.13.13 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/endpoint-discovery v1.12.7 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/presigned-url v1.13.30 // indirect
	github.com/aws/aws-sdk-go-v2/service/signin v1.4.1 // indirect
	github.com/aws/aws-sdk-go-v2/service/sso v1.32.1 // indirect
	github.com/aws/aws-sdk-go-v2/service/ssooidc v1.37.1 // indirect
	github.com/aws/aws-sdk-go-v2/service/sts v1.44.1 // indirect
	github.com/aws/smithy-go v1.27.3 // indirect
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/redis/go-redis/v9 v9.21.0 // indirect
	go.uber.org/atomic v1.11.0 // indirect
)
