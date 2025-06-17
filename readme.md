# Kubernetes in Docker (KinD) Gremlin demo

Installs a Kubernetes in Docker (KinD) cluster along with the Gremlin Kubernetes client, Ingress, and the [Bank of Anthos](https://github.com/GoogleCloudPlatform/bank-of-anthos) demo application. This is a quick and easy way to get started with a "multi-node" Kubernetes cluster on your local computer or in a VM.

By default, this creates a four-node cluster (one control plane and three workers). For more configuration info, see https://kind.sigs.k8s.io/docs/user/configuration/. Port 80 is mapped from the control plane to your local system, and the Kubernetes API is exposed on `127.0.0.1:6443`. You can configure the cluster using the `config.yaml` file.

## Why Kind?

Kind is a quick and easy way to create multi-node Kubernetes clusters. This is great for running node-level chaos experiments like node shutdown, blackhole, and control plane failure. You can target nodes, Pods, Deployments, Daemonsets, and other K8s resources through Gremlin just like a normal cluster. Since creating a Kind cluster is faster, less complicated, and less resource-intensive than a VM-based setup like K3s, you can easily recreate the cluster if something breaks.

Note that this cluster is meant for testing Kubernetes and Gremlin, not for running production applications. I recommend running in a virtual machine.

## Getting Started

First, run `git submodule update --init --recursive` to download the Bank of Anthos demo project.

1. Install [Docker](https://docs.docker.com/install/) (or Podman or a similar runtime), [Kubernetes in Docker (KinD)](https://kind.sigs.k8s.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), and [Helm](https://helm.sh/docs/intro/install/)
2. Fill in the `.env` file:
	1. `GREMLIN_CONFIG_FILE_PATH`: the path to your Gremlin `values.yaml` file. To get this file, [go to the Getting Started page in the Gremlin web app](https://app.gremlin.com/getting-started) and click the values.yaml link under the "Install the Gremlin Agent" step.
	2. `GREMLIN_STAGING_CONFIG_FILE_PATH`: (Optional) the path to `values.yaml` for the staging environment.
	3. `CLUSTER_NAME`: the name of your cluster. This is how it will appear in Gremlin and in Kind.
	4. `APP_REPLICAS`: (Optional) how many replicas of each Deployment in the demo application you want to use. Defaults to 2.
3. (Optional) customize your KinD cluster by editing `config.yaml`.
4. Run `run.sh` to create the cluster.
	1. **Note:** If the cluster already exists, it will be deleted. On Linux, you'll need to run the script using `sudo` or add your user to the `docker` group.
	2. You can choose not to deploy Gremlin or the demo application with the arguments `--no-gremlin` and `-no-app`.
	3. If you want to redeploy Gremlin and the demo app only without rebuilding the cluster, add the argument `--no-cluster`.
5. Access the application using http://127.0.0.1.