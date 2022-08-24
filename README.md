# Short-URL

This is a job application coding challenge project.

Create a web service that shortens URLs for 1000s of concurrent users. Users
should be able to submit a long URL, then receive a unique shortened URL that
redirects to the long URL. 

## Demo

This application will be available for a short time under http://shorts.gq 

For eg. this http://shorts.gq/0 should redirect you to my GitHub profile.

## Performance and scalability considerations

We need to generate unique values and make them short. Generating random UUIDs 
would be against "make them short" requirement. So in order to generate short
values we need a shared counter like value that will be assigned used as key 
for url mapping.

I chose redis for atomic [INCR](https://redis.io/commands/incr/) command and
[persistent storage](https://redis.io/docs/manual/persistence/). 
It would be a bottleneck, but it [should do fine](https://redis.io/docs/reference/optimization/benchmarks/)
until we'll need to service more than 50K mapping requests per second. 

Deployment on k8s cluster with autoscaling would take care of rest of 
scalability issues.

## Metrics and monitoring 

I focused on the getting the app running on live k8s cluster and did not 
implement metrics. But ATM I think we could get away with the ones available
out of the box with [Prometheus k8s support](https://kubernetes.io/docs/concepts/cluster-administration/system-metrics/): 

- Metrics for ingress/load balancer to monitor HTTP traffic
  - the usual stuff related to usage, latencies and errors
- [Redis metrics](https://docs.redis.com/latest/rs/monitoring-metrics/prometheus-metrics-definitions/)
  - Storage capacity and latencies 
  - The "counter" value with limit as 64 bit signed integer, we should be pretty
    safe, but let's monitor how quicly we're depleting the rest of the results.
 
## Future 

- Re-use mappings for previously seen destination  
- Multiple redis instances and dispatching with consistent hashing
- Expiration on time on url mappings.
- Rolling forward with new redis instances for new mappings and decommissioning
  instances that expired all the previous values.

## User interface

I was asked to not waste time on UI, so I decided to stick with whatever 
is available out of the box. 

## Testing

The project was tested locally on [minikube](https://minikube.sigs.k8s.io/docs/start/) 
with ingress and repository addons enabled. Please see [Makefile](Makefile)
commands with minikube-prefix.

To create deployment on minikue please override `REGISTRY` env variable with 
whatever minikube will show as prefix for `shorts` image uploaded to the local 
minikube images store:

```bash
env REGISTRY=docker.io/library make minikube-create-deployment
```

Please beware that minikube deployment uses `imagePullPolicy: Never` for 
prohibit image downloads from non-existent external source.

A [docker-compose](docker-compose.yaml) is provided for simplified environment
setup and to provide redis for integration tests.

# Other job application code challenges

Please take a look at other code challenge projects I have prepared in the past.

- https://github.com/wooyek/star-wars-explorer
- https://github.com/wooyek/secure-share
- https://github.com/wooyek/secure_share_kiss

And other notable projects — please beware that they are legacy at this point

- https://github.com/wooyek/fakturownia-python
- https://github.com/wooyek/django-error-views
- https://github.com/wooyek/django-email-queue
- https://github.com/wooyek/django-multiinfo
- https://github.com/wooyek/django-opt-out
- https://github.com/wooyek/django-settings-strategy
- https://github.com/wooyek/django-model-cleanup



