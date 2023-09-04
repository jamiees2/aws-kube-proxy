{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "kube-proxy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kube-proxy.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kube-proxy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "kube-proxy.labels" -}}
app.kubernetes.io/name: {{ include "kube-proxy.name" . }}
helm.sh/chart: {{ include "kube-proxy.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
eks.amazonaws.com/component: kube-proxy
k8s-app: kube-proxy
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "kube-proxy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "kube-proxy.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "kube-proxy.clusterRoleBindingName" -}}
    {{ default (printf "eks:%s" (include "kube-proxy.fullname" .)) .Values.serviceAccount.clusterRoleBindingName }}
{{- end -}}

{{/*
The kube-proxy image to use
*/}}
{{- define "kube-proxy.image" -}}
{{- if .Values.image.override }}
{{- .Values.image.override }}
{{- else }}
{{- printf "%s.dkr.%s.%s.%s/eks/kube-proxy:%s" .Values.image.account .Values.image.endpoint .Values.image.region .Values.image.domain .Values.image.tag }}
{{- end }}
{{- end }}
