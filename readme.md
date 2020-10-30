# Kubernetes in Docker (KinD) Gremlin demo

Installs a Kubernetes in Docker (KinD) cluster along with the Gremlin K8s client, Ingress, and the [microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) application. This is a quick and easy way to get started with a "multi-node" Kubernetes cluster on your local computer or in a VM.

By default, this creates a three-node cluster (one control plane and two workers). For more configuration info, see https://kind.sigs.k8s.io/docs/user/configuration/. Port 80 is mapped from the control plane to your local system, and the Kubernetes API is exposed on `127.0.0.1:6443`.

## Getting Started

1. Install [Docker](https://docs.docker.com/install/), [Kubernetes in Docker (KinD)](https://kind.sigs.k8s.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), and [Helm](https://helm.sh/docs/intro/install/)
2. Fill in the `.env` file.
	1. `GREMLIN_CERT_PATH`: the path containing your [Gremlin certificates](https://www.gremlin.com/docs/infrastructure-layer/authentication/#signature-based-authentication).
	2. `GREMLIN_CLUSTER_ID`: the name of your cluster as it will appear in the Gremlin web app.
	3. `GREMLIN_TEAM_ID`: your [Gremlin team ID](https://app.gremlin.com/settings/teams).
	4. `KIND_CLUSTER_NAME`: a unique identifier for your cluster for the `kind` CLI.
3. Optionally customize your KinD cluster by editing `config.yaml`.
4. Run `run.sh` to create the cluster.
5. Access the demo application using http://localhost.