# Kubernetes in Docker (KinD) Gremlin demo

Installs a Kubernetes in Docker (KinD) cluster along with the Gremlin K8s client, Ingress, and the [microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) application. This is a quick and easy way to get started with a "multi-node" Kubernetes cluster on your local computer or in a VM.

By default, this creates a three-node cluster (one control plane and two workers). For more configuration info, see https://kind.sigs.k8s.io/docs/user/configuration/. Port 80 is mapped from the control plane to your local system, and the Kubernetes API is exposed on `127.0.0.1:6443`.

## Why Kind?

Kind is a quick and easy way to create multi-node Kubernetes clusters. This is great for running node-level chaos experiments like shutdown and blackhole. Since Gremlin supports the containerd runtime, you can also run chaos experimeents on Pods, Deployments, DaemonSets, and other K8s resources. Creating a Kind cluster is also faster, less complicated, and less resource-intensive than a setup like [Vagrant + K3s](https://github.com/8bitbuddhist/k3s-gremlin-demo).

Note that this cluster is meant for testing Kubernetes and Gremlin, not for running production applications. I recommend running in a virtual machine.

## Getting Started

1. Install [Docker](https://docs.docker.com/install/), [Kubernetes in Docker (KinD)](https://kind.sigs.k8s.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), and [Helm](https://helm.sh/docs/intro/install/)
	1. **Note**: You'll need to add your user to the `docker` group to use the run script.
2. If you want to deploy Gremlin, fill in the `.env` file:
	1. `GREMLIN_CERT_PATH`: the path containing your [Gremlin certificates](https://www.gremlin.com/docs/infrastructure-layer/authentication/#signature-based-authentication).
	2. `GREMLIN_CLUSTER_ID`: the name of your cluster as it will appear in the Gremlin web app.
	3. `GREMLIN_TEAM_ID`: your [Gremlin team ID](https://app.gremlin.com/settings/teams)
	4. `ENV_PLATFORM`: the visual style to use. Can be `aws`, `onprem`, `azure`, or blank for Google Cloud.
3. Optionally customize your KinD cluster by editing `config.yaml`.
4. Run `run.sh <cluster name>` to create the cluster.
	1. **Note:** If the cluster already exists, it will be deleted.
	2. You can choose whether to deploy Gremlin or the demo application by adding `--no-gremlin` or `-no-app` as arguments.
5. Access the application using http://localhost.