//cdn & waf, infront of alb
//WAF for CF must be created in the us-east-1 (N. Virginia)
//users are served with fresh resposes, no cache.

//waf
resource "aws_wafv2_web_acl" "api_waf" {
    provider = aws.us_east_1
    name ="${local.prefix}-waf"
    scope = "CLOUDFRONT" #for cdn attachment, it has 2 scopes: attaches to cf or REGINAL (alb, api gw, appsync)
    default_action {
        allow {} //for most apps, allow is the default, only blocks known bad patterns. default Block is for internal tools that only explictly allow things, hard to manage.
    }
    //rules:
    rule { # rule 1 - rate limiting [provents bot spam]
        name = "RateLimit"
        priority = 1 //evaluated first, stop at the first match
        action {
            block {} //if the rule matches, block the request
        }
        statement { // the match condition
            rate_based_statement {
                limit = 100# max 100 requrests perr 300s from one ip.
                aggregate_key_type = "IP"
            }
        }
        visibility_config {//connects waf to cloudwatch, for monitoring.
        //always enable - best practise.
            cloudwatch_metrics_enabled = true
            metric_name                = "RateLimitMetric"
            sampled_requests_enabled   = true //log the requests that match this rule
        }
    }
    rule {  //rule 2 - block common attacks, sql injection, xss, etc
        name = "AWSManagedRulesCommonRuleSet"
        priority = 2 //evaluated after the rate limit rule
        override_action {//override the rule group's native action
            none {} //no override, use the default action - block if it matches in this rule group.
        } 
        statement { // the match condition
            managed_rule_group_statement {
                name = "AWSManagedRulesCommonRuleSet"
                vendor_name = "AWS"
            }
        } # rate_based_statement, managed_rule_group_statement, byte_match_statement, geo_match_statement
        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "AWSDefaultRuleSetMetric"
            sampled_requests_enabled   = true
        }
    }
    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "MainWAFFMetric"
        sampled_requests_enabled   = true
    }
}

//cf cdn
# Fetches managed policy ID for "CachingDisabled" - so CloudFront does not cache responses from the origin (ALB in this case). Used for api that always served with fresh responses.
data "aws_cloudfront_cache_policy" "no_cache" {
  name = "Managed-CachingDisabled"
} //this app does not have caching at the cf level, only in redis. CF only has tls termination, waf, global anycast entry point, ddos shield.

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer" # forwards headers, cookies, query strings
}

resource "aws_cloudfront_distribution" "api_cdn" {
  web_acl_id = aws_wafv2_web_acl.api_waf.arn # Attach WAF
  enabled    = true //false: disable the distribution

  origin {
    domain_name = aws_lb.fargate_app.dns_name #point to the ALB
    origin_id   = "alb-origin" //must match the target_origin_id in default_cache_behavior

    custom_origin_config { //for non-s3 origins - ALB, API Gateway, etc
      http_port              = 80
      https_port             = 443 //needs to be declared even not being used in this project.
      origin_protocol_policy = "http-only" # ALB listens on 80. [https-only, match-viewer]
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
    #default behavior for requests that do not match any other behavior, since no other behaviors defined, everthing goes here.
  default_cache_behavior { //no caching here
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https" # Force SSL for users. it can also be allow-all or https-only
    
    #Allow all methods for the api (POST, PUT, DELETE)
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"] 

    # Attach the No-Cache policy
    cache_policy_id = data.aws_cloudfront_cache_policy.no_cache.id

    # add the origin request 
    # no caching, no need to forward headers to backend, this is the default behavior.
    # if caching is enable then this is not needed.
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # Use standard AWS *.cloudfront.net cert
  }
}