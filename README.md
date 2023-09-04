# AWS Kube Proxy

This chart installs kube-proxy as it is configured by default on AWS

## Prerequisites

- Kubernetes 1.26+ running on AWS
- Helm v3

## Installing the Chart

First add the EKS repository to Helm:

```shell
helm repo add aws-kube-proxy https://jamiees2.github.io/aws-kube-proxy/
```

To install the chart with the release name `aws-vpc-cni` and default configuration:

```shell
$ helm install kube-proxy --namespace kube-system aws-kube-proxy/aws-kube-proxy
```

To install into an EKS cluster where the CNI is already installed, see [this section below](#adopting-the-existing-kube-proxy-resources-in-an-eks-cluster)

## Configuration

The following table lists the configurable parameters for this chart and their default values.

| Parameter                               | Description                                             | Default                          |
| --------------------------------------- | ------------------------------------------------------- | -------------------------------- |
| `nameOverride`                          | Override the name of the chart                          | `kube-proxy`                     |
| `fullnameOverride`                      | Override the fullname of the chart                      | `kube-proxy`                     |
| `image.tag`                             | Image tag                                               | `v1.27.1-minimal-eksbuild.1`     |
| `image.domain`                          | ECR repository domain                                   | `amazonaws.com`                  |
| `image.region`                          | ECR repository region to use. Should match your cluster | `us-east-1`                      |
| `image.endpoint`                        | ECR repository endpoint to use.                         | `ecr`                            |
| `image.account`                         | ECR repository account number                           | `602401143452`                   |
| `image.pullPolicy`                      | Container pull policy                                   | `IfNotPresent`                   |
| `image.override`                        | A custom docker image to use                            | `nil`                            |
| `imagePullSecrets`                      | Docker registry pull secret                             | `[]`                             |
| `originalMatchLabels`                   | Use the original daemonset matchLabels                  | `false`                          |
| `env`                                   | List of environment variables.                          | `{}`                             |
| `priorityClassName`                     | Name of the priorityClass                               | `system-node-critical`           |
| `podSecurityContext`                    | Pod Security Context                                    | `{}`                             |
| `podAnnotations`                        | annotations to add to each pod                          | `{}`                             |
| `podLabels`                             | Labels to add to each pod                               | `{}`                             |
| `extraVolumes`                          | Array to add extra volumes                              | `[]`                             |
| `extraVolumeMounts`                     | Array to add extra mount                                | `[]`                             |
| `securityContext`                       | Container Security context                              | `capabilities: privileged: true` |
| `serviceAccount.create`                 | Specifies whether a ServiceAccount should be created    | `true`                           |
| `serviceAccount.name`                   | The name of the ServiceAccount to use                   | `nil`                            |
| `serviceAccount.clusterRoleBindingName` | The name of the clusterRoleBinding to use               | `nil`                            |
| `serviceAccount.annotations`            | Specifies the annotations for ServiceAccount            | `{}`                             |
| `resources`                             | Resources for containers in pod                         | `requests.cpu: 100m`             |
| `updateStrategy`                        | Optional update strategy                                | `type: RollingUpdate`            |
| `nodeSelector`                          | Node labels for pod assignment                          | `{}`                             |
| `tolerations`                           | Optional deployment tolerations                         | `[{"operator": "Exists"}]`       |
| `affinity`                              | Map of node/pod affinities                              | `{}`                             |
| `clusterEndpoint`                       | The cluster endpoint to talk to                         | `nil`                            |
| `kubeProxyConfiguration`                | The kube-proxy configuration                            | (see values.yaml)                |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install` or provide a YAML file containing the values for the above parameters:

```shell
$ helm install kube-proxy --namespace kube-system aws-kube-proxy/aws-kube-proxy --values values.yaml
```

## Adopting the existing kube-proxy resources in an EKS cluster

If you do not want to delete the existing kube-proxy resources in your cluster that run the kube-proxy and then install this helm chart, you can adopt the resources into a release instead. Refer to the script below to import existing resources into helm. Once you have annotated and labeled all the resources this chart specifies, enable the `originalMatchLabels` flag. If you have been careful this should not diff and leave all the resources unmodified and now under management of helm.

WARNING: Substitute YOUR_HELM_RELEASE_NAME_HERE with the name of your helm release.
```
#!/usr/bin/env bash

set -euo pipefail

helmRelease="YOUR_HELM_RELEASE_NAME_HERE"

annotate_and_label() {
  local kind="$1"
  local resource="$2"
  local helmRelease="$3"
  
  echo "setting annotations and labels on $kind/$resource"

  kubectl -n kube-system annotate --overwrite "$kind" "$resource" meta.helm.sh/release-name="$helmRelease"
  kubectl -n kube-system annotate --overwrite "$kind" "$resource" meta.helm.sh/release-namespace=kube-system
  kubectl -n kube-system label --overwrite "$kind" "$resource" app.kubernetes.io/managed-by=Helm
}

for kind in daemonSet serviceAccount configMap; do
  annotate_and_label $kind kube-proxy $helmRelease
done

annotate_and_label configMap "kube-proxy-config" $helmRelease
annotate_and_label clusterRoleBinding "eks:kube-proxy" $helmRelease
```
