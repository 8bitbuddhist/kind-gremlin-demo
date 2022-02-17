# Kubernetes in Docker (KinD) Gremlin demo

Installs a Kubernetes in Docker (KinD) cluster along with the Gremlin K8s client, Ingress, and the [microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) application. This is a quick and easy way to get started with a "multi-node" Kubernetes cluster on your local computer or in a VM.

By default, this creates a three-node cluster (one control plane and two workers). For more configuration info, see https://kind.sigs.k8s.io/docs/user/configuration/. Port 80 is mapped from the control plane to your local system, and the Kubernetes API is exposed on `127.0.0.1:6443`.

## Why Kind?

Kind is a quick and easy way to create multi-node Kubernetes clusters. This is great for running node-level chaos experiments like node shutdown, blackhole, and control plane failure. You can target nodes, Pods, Deployments, Daemonsets, and other K8s resources through Gremlin just like a normal cluster. Since creating a Kind cluster is faster, less complicated, and less resource-intensive than a VM-based setup like K3s, you can easily recreate the cluster if something breaks.

Note that this cluster is meant for testing Kubernetes and Gremlin, not for running production applications. I recommend running in a virtual machine.

## Getting Started

First, run `git submodule update --init --recursive` to download the Online Boutique/microservices-demo project.

1. Install [Docker](https://docs.docker.com/install/), [Kubernetes in Docker (KinD)](https://kind.sigs.k8s.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), and [Helm](https://helm.sh/docs/intro/install/)
2. Fill in the `.env` file:
	1. `GREMLIN_CERT_PATH`: (Optional) the path containing your [Gremlin certificates](https://www.gremlin.com/docs/infrastructure-layer/authentication/#signature-based-authentication).
	2. `GREMLIN_TEAM_ID`: (Optional) your [Gremlin team ID](https://app.gremlin.com/settings/teams)
	3. `CLUSTER_NAME`: the name of your cluster. This is how it will appear in Gremlin and Kind.
	4. `ENV_PLATFORM`: the visual style to use. Can be `aws`, `onprem`, `azure`, or blank for Google Cloud.
3. (Optional) customize your KinD cluster by editing `config.yaml`.
4. Run `run.sh` to create the cluster.
	1. **Note:** If the cluster already exists, it will be deleted. On Linux, you'll need to run the script using `sudo` or add your user to the `docker` group.
	2. You can choose not to deploy Gremlin or the demo application with the arguments `--no-gremlin` and `-no-app`.
	3. If you want to redeploy Gremlin and Online Boutique only without rebuilding the cluster, add the argument `--no-cluster`.
5. Access the application using http://127.0.0.1.

## Troubleshooting

When running Online Boutique v0.3.5 locally, the frontend might time out while trying to get info about the cluster name and zone. This adds a ton of lag to the site. If this happens, you'll need to clone the GitHub repository, edit the [frontend handler](https://github.com/GoogleCloudPlatform/microservices-demo/blob/v0.3.5/src/frontend/handlers.go), remove all references to metaServerClient, remove lines [531](https://github.com/GoogleCloudPlatform/microservices-demo/blob/v0.3.5/src/frontend/handlers.go#L531) and [536](https://github.com/GoogleCloudPlatform/microservices-demo/blob/v0.3.5/src/frontend/handlers.go#L536), then enter a string for `podCluster` and `podZone`. Finally, run `run.sh --skaffold` to build the project.

If you're using cgroups v2, Gremlin might not detect the containers running on your cluster. You can re-enable the v1 interface by adding `systemd.unified_chgroup_hierarchy=false systemd.legacy_systemd_cgroup_controller=false` to your kernel parameters (example for Debian [here](https://www.debian.org/releases/stable/amd64/release-notes/ch-information.en.html#openstack-cgroups))