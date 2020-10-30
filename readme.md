# Kind as a Kubernetes Cluster

Installs a Kubernetes in Docker (KinD) cluster along with the Gremlin K8s client, Ingress, and the [microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) application.

1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), [Helm](https://helm.sh/docs/intro/install/), and [Kubernetes in Docker (KinD)](https://kind.sigs.k8s.io/)
2. Fill in the `.env` file.
	1. Optionally customize your KinD cluster by editing `config.yaml`.
3. Run `run.sh` to create the cluster.
4. Access Hipster-Shop using http://localhost.