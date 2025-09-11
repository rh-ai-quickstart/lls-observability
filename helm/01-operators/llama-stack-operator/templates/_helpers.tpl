{{/*
Expand the name of the chart.
*/}}
{{- define "llama-stack-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "llama-stack-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "llama-stack-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "llama-stack-operator.labels" -}}
helm.sh/chart: {{ include "llama-stack-operator.chart" . }}
{{ include "llama-stack-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "llama-stack-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "llama-stack-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
control-plane: controller-manager
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "llama-stack-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (printf "%s-controller-manager" (include "llama-stack-operator.fullname" .)) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the namespace to use
*/}}
{{- define "llama-stack-operator.namespace" -}}
{{- if eq .Release.Namespace "default" }}
{{- .Values.namespace.name }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "llama-stack-operator.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Controller manager labels (specific for deployment)
*/}}
{{- define "llama-stack-operator.controllerLabels" -}}
{{ include "llama-stack-operator.labels" . }}
control-plane: controller-manager
{{- end }}

{{/*
Leader election role name
*/}}
{{- define "llama-stack-operator.leaderElectionRoleName" -}}
{{- printf "%s-leader-election-role" (include "llama-stack-operator.fullname" .) }}
{{- end }}

{{/*
Leader election role binding name
*/}}
{{- define "llama-stack-operator.leaderElectionRoleBindingName" -}}
{{- printf "%s-leader-election-rolebinding" (include "llama-stack-operator.fullname" .) }}
{{- end }}

{{/*
Manager cluster role name
*/}}
{{- define "llama-stack-operator.managerClusterRoleName" -}}
{{- printf "%s-manager-role" (include "llama-stack-operator.fullname" .) }}
{{- end }}

{{/*
Manager cluster role binding name
*/}}
{{- define "llama-stack-operator.managerClusterRoleBindingName" -}}
{{- printf "%s-manager-rolebinding" (include "llama-stack-operator.fullname" .) }}
{{- end }}

{{/*
Metrics service name
*/}}
{{- define "llama-stack-operator.metricsServiceName" -}}
{{- printf "%s-metrics" (include "llama-stack-operator.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Deployment name
*/}}
{{- define "llama-stack-operator.deploymentName" -}}
{{- printf "%s-controller-manager" (include "llama-stack-operator.fullname" .) }}
{{- end }}