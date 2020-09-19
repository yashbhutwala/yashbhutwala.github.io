---
title: "Ultimate guide to right sizing pods in Kubernetes - Requests, Limits, HPA, VPA" # Title of the blog post.
date: 2020-09-18T10:05:13-04:00 # Date of post creation.
description: "Right sizing and autoscaling workloads in Kubernetes" # Description used for search engine.
featured: true # Sets if post is a featured post, making appear on the home page side bar.
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: false # Controls if a table of contents should be generated for first-level links automatically.
# menu: main
# featureImage: "/images/path/file.jpg" # Sets featured image on blog post.
# thumbnail: "/images/path/thumbnail.png" # Sets thumbnail image appearing inside card on homepage.
# shareImage: "/images/path/share.png" # Designate a separate image for social media sharing.
codeMaxLines: 10 # Override global value for how many lines within a code block before auto-collapsing.
codeLineNumbers: false # Override global value for showing of line numbers within code block.
figurePositionShow: true # Override global value for showing the figure label.
categories:
  - Technology
tags:
  - Kubernetes
  - Autoscaling
  - Performance
  - Capacity
---

<!-- omit in toc -->
## Table of Contents

- [Background](#background)
- [Problem Statement](#problem-statement)
- [Solutions](#solutions)
  - [Day 1 Solution](#day-1-solution)
    - [Recommendations for initial limits and requests](#recommendations-for-initial-limits-and-requests)
    - [Notes on load testing](#notes-on-load-testing)
  - [Day 2 Solution:](#day-2-solution)
    - [VPA and its gaps](#vpa-and-its-gaps)
- [Links](#links)

## Background

When it comes to handling scale for a workload, you get 3 knobs in Kubernetes: **requests**, **limits**, and **replicas**.  Kubernetes pods specify their CPU and memory needs via resource requests.  CPU resources are measured in virtual cores or more commonly in millicores, e.g. 500m denoting 50% of a vCPU.  Memory resources are measured in Bytes and the usual suffixes can be used, e.g. 500Mi denoting 500 Mebibyte.  **Resource requests reserve capacity on worker nodes**; i.e. a pod with 1000m CPU requests on a node with 4 vCPUs will leave only 3 vCPUs available for other pods.  *Requests is the most important attribute for a Pod, as they let the Kubernetes scheduler know where the workload can be placed*.  **Limits, on the other hand, enforce the maximum amount of resource a workload is allowed to consume, with compressible resources such as CPU resulting in throttling and in-compressible resources such as memory resulting in OOMKill events.**

<!-- omit in toc -->
### Why are they important?

- To ensure your pods have enough resources to do their job
- To ensure other pods do not affect your pod by using up resources you need
- To ensure our Kubernetes cluster has enough Nodes to support our services
- To ensure our Kubernetes cluster doesn't have too many nodes, which would waste our budget

## Problem Statement

**Overarching problem**: How do we set CPU/MEM resource requests in order to optimize bin packing to increase utilization and save $$$?

- **Day 1 problem: what do we set for cpu/memory initially, i.e.: for "average expected usage"?**
  - Too little?
    - CPU starvation
    - Out of Memory errors
    - Workload eviction
  - Too much?
    - Resource Waste
- **Day 2 problem: how do I manage the changes in cpu/memory requests dynamically as app changes?**
  - Daily/Weekly traffic patterns
  - User base growing over time
  - App lifecycle phases with different resource needs

As you can imagine, coming up with good numbers for cpu and mem reqs for different containers is hard, so most people get lazy, pick their best guess, stick it in a yaml file and never change it.

## Solutions

### Day 1 Solution

**Main thing you can do: measure CPU and memory usage during a load test**

#### Recommendations for initial limits and requests

*NOTE: These recommendations may not apply to all services or workloads. Do not blindly apply them without load tests!*

*Note that if your service keeps significant amount of data cached in memory, or has to handle a high number of concurrent requests, the following numbers may not be appropriate.*

- `requests.cpu`: 1/3x~1/5x as `limits.cpu`; should be low enough to keep CPU usage equal to the `HPA target` multipled by `requests.cpu`
- `requests.memory`: should be the same as `limits.memory`, and high enough to avoid OOM during normal operations and in case of dependency failures
- `limits.cpu`: 3x~5x as requests.cpu; should be high enough to keep `docker.cpu.throttled` or [`kubernetes.cpu.cfs.throttled.periods`/`kubernetes.cpu.cfs.periods`] down to 0 during normal operations
- `limits.memory`: should be the same as requests.memory
- hpa `metrics.resource.targetAverageUtilization`: good HPA targets are unlikely to be outside the range 50% to 75%. 65% (i.e. ~2/3) is a good starting point; remember this is based on requests and not limits
- hpa `spec.minReplicas`: 3

The following is an example recommended initial limits/requests for a stateless microservice. You can use this until you have performed load tests to understand the actual resources needed by your service.

```yaml
  requests:
    cpu: 500m      # 1/3x as limits.cpu; should be low enough to keep CPU usage equal to
                   # the HPA target multipled by requests.cpu
    memory: 256Mi  # should be the same as limits.memory, and high enough to avoid
                   # OOM during normal operations and in case of dependency failures
  limits:
    cpu: 1500m     # 3x as requests.cpu; should be high enough to keep `docker.cpu.throttled`
                   # down to 0 during normal operations
    memory: 256Mi  # should be the same as requests.memory
```

After doing a representative load test of production workloads, and especially after releasing in production, you should review your resources requests and limits and fix them as needed.

<!-- omit in toc -->
#### Tips and Tricks

- Don't set very low limits or requests before the first deployment to production, it is better to lower the limits and requests after you know how much you really need.
- In general, it is advisable to have many small pods instead of very few big pods, and in any case you should have at least 3 pods for availability.
- It is normally not advised to run too many pods, as running too many pods can cause resource exhaustion or overload in your dependencies (e.g. too many open connections on your database or caching server), make debugging/troubleshooting more difficult, and slow down the deployment process.
- **Document the rationale for choosing specific values for the requests and limits.**
- Memory limits should be equal to memory request: this makes it unlikely for kubernetes to kill your pod due to the memory consumption of other pods.
- The overall CPU utilization (`docker.cpu.usage`) of your deployment should ideally always be the one set for the HPA (e.g. if your CPU request is 500m and your HPA target is 65%, your CPU usage in each pod should always be 65% of 500m, i.e. ~325m[^metric]). Considering that the recommendation is to set HPA min replicas to 3, you may need to lower your CPU requests.
- If your service performs reads/writes on the filesystem during regular operations you should raise your memory request/limits to ensure there is enough memory for the page cache.
- Use whole CPUs when possible; [this will tell kubernetes explicitly to task set the pods to individual cpus](https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/#static-policy)

#### Notes on load testing

When testing performance of your application, you should test ALL OF (in order of importance):
- Each function of your application in isolation
- Many functions at once based upon an estimate of real-world traffic
- Randomized testing or "Fuzzing" of different functions

<!-- omit in toc -->
##### Best load testing tools

[Comparing best open source load testing tools](https://k6.io/blog/comparing-best-open-source-load-testing-tools)

Tools in order of my preference:

- [k6](https://github.com/loadimpact/k6)
- [locust](https://github.com/locustio/locust)
- [jmeter](https://github.com/apache/jmeter)

<!-- omit in toc -->
##### Testing in Isolation

You should have a way to performance test each function of your application in isolation. That means if your application has multiple different API endpoints, each one should be tested as independently as possible. The purpose of this is to ensure that you have a known baseline of performance. This follows the scientific practice of testing variables in isolation.

<!-- omit in toc -->
##### Testing based upon Real World Estimates

You should be able to performance test your application in some estimate of a real world scenario. This means you should measure what sort of requests your application will receive and try to mimic those requests in a test environment. As these numbers will change over time, the test should be updated periodically to ensure the testing is still valid.

While testing in isolation would ideally be enough, there are often complex interactions between different parts of an application. This testing intends to detect if any of these complex interactions exist under expected conditions.

<!-- omit in toc -->
##### Testing with production like databases

Since in certain circumstances, performance characteristics might be heavily dependent on the size/characteristics of the data, it's important to be able to replicate a production databases.  Backup of an actual production database would be ideal.  Second best option would be an anonymized version of production database.  Third might be reconstructing production-like database manually.

<!-- omit in toc -->
##### Randomized Testing ("Fuzzing")

Common test scenarios tend to be based upon ideal conditions. Randomized Testing intends to measure if the performance is still consistent (or at least meeting expectations) with less-than-ideal input. This is particularly important for services which receive user traffic, as you cannot always guarantee that your application will receive good input.

In certain scenarios, bad input can cause an applications performance to be significantly worse. Applications involving caches are a common example of this, where bad input can evict important data from a cache and cause the performance of other requests to be degraded.

### Day 2 Solution:

Although things like the Vertical Pod Autoscaler exist, mostly existing community solutions are not good enough to go with an automated approach.  Given that, here is the recommendations for Day 2 operations:

- Periodically review the historical resource usage of your services and perform corrective actions to ensure your service is not consuming too many resources.
- Monitor your CPU throttled % (should be ~0)

#### VPA and its gaps

Vertical Pod Autoscaler (VPA) is an open source kubernetes project for solving the Day 2 problem of right-sizing pods over time.  The goal of VPA is to replace this human operator based approach with a much more data driven automated approach to right-sizing pods to increase utilization and reduce slack - difference between allocation and usage.  VPA is based on an internal Google project known as "Autopilot".  For more information on how VPA works and my review of Autopilot, [read my post here](https://medium.com/@ymb002/vertical-pod-autoscaling-right-sizing-your-pods-18af3a0d5184).  TLDR of it is that even though automating right sizing pods sounds really awesome, the open source solution for it lacks substantially in feature and usability to be able to use it as much as Google's internal Autopilot system.  Here is a few:

- VPA is hard to get started with
- Currently, it only uses statistics, which tries to acommodate most workloads, but may not be sufficient for all (i.e.: for Java, it does not have visibility into memory usage of the application vs JVM)
- Historical provider is only there for Prometheus
- No machine learning, or custom algorithms
- Since Kubernetes resource model treats requests/limits as immutable, there is no way to update the requests/limits in place (although there is [work](https://github.com/kubernetes/enhancements/issues/1287) being done on this [upstream](https://github.com/kubernetes/enhancements/blob/master/keps/sig-node/20181106-in-place-update-of-pod-resources.md))
- It doesn't work smoothly with HPA

## Links

- [mercari resource requests and limits](https://github.com/mercari/production-readiness-checklist/blob/1406bd218568945d098838997b6e72e312549f8c/docs/concepts/resource-requests-and-limits.md)
- [mercari capacity planning](https://github.com/mercari/production-readiness-checklist/blob/1406bd218568945d098838997b6e72e312549f8c/docs/concepts/capacity-planning.md)
- [mercari autoscaling](https://github.com/mercari/production-readiness-checklist/blob/1406bd218568945d098838997b6e72e312549f8c/docs/concepts/auto-scaling.md)
- [learnk8s article](https://learnk8s.io/setting-cpu-memory-limits-requests)
- [Dave Chiluk's Kubecon talk on Throttling](https://youtu.be/UE7QX98-kO0)

<!-- omit in toc -->
### Other interesting links

- [descheduler](https://github.com/kubernetes-sigs/descheduler)

<!-- omit in toc -->
## TODO

- write an article on cpu throttling
- write an article on VPA
- write an article on performance testing
- write for individual language services; Java vs Golang; GOMAXPROCS, GCs, etc.
