# Rate limit

This page describes how the rate limiting can be set up for the Harbor container registry.

Harbor itself doesn't support rate limit protection yet, see open [issue](https://github.com/goharbor/harbor/issues/3419).
Therefore, we can take advantage of the ingress controller in front of the Harbor. In our case Nginx.

In the ingress-nginx controller, the rate-limiting options can be specified via [annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#rate-limiting).
E.g. `nginx.ingress.kubernetes.io/limit-rps: "1"` means that ingress will allow only 1 request from a given IP per second.
Client IP is set based on the use of `PROXY protocol` or from the `X-Forwarded-For` header value.
In the SCS reference implementation, proxy protocol for ingress nginx is [enabled by default](https://github.com/SovereignCloudStack/k8s-cluster-api-provider/blob/main/Release-Notes-R4.md#enabling-the-proxy-protocol-for-nginx-ingress-and-preliminary-support-for-ovn-lb-325).
This rate-limit annotation is ideal for *DDoS attacks* mitigation. When clients exceed this limit
**503** status code is returned. This status code can be changed via nginx ingress controller configmap:
```bash
$ kubectl edit cm -n ingress-nginx ingress-nginx-controller
#  data:
#    limit-req-status-code: "429"
```
There are other useful annotations, such as limit concurrent connections, number of kilobytes per second or limit burst requests.
E.g. bursts can be configured via `nginx.ingress.kubernetes.io/limit-burst-multiplier`, which is by default *5*.
It means that [burst](http://nginx.org/en/docs/http/ngx_http_limit_req_module.html#limit_req)
will be set in this case to `limit-rps * limit-burst-multiplier = 1 * 5 = 5`.

More information about nginx rate-limiting and real-world examples can be seen in this nginx [blog](https://www.nginx.com/blog/rate-limiting-nginx/).
Also, there is a second option for how the rate limiting can be configured called [global rate limiting](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#global-rate-limiting).
Detailed research and comparison are done in this [issue](https://github.com/SovereignCloudStack/k8s-harbor/issues/38#issuecomment-1570181044).
Furthermore, see this [PR](https://github.com/SovereignCloudStack/k8s-harbor/pull/42),
which adds a rate limit for the public(registry.scs.community) environment.
