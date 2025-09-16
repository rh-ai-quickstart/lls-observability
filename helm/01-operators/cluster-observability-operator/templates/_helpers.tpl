{{/*
Expand the name of the chart.
*/}}
{{- define "cluster-observability-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cluster-observability-operator.fullname" -}}
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
{{- define "cluster-observability-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cluster-observability-operator.labels" -}}
helm.sh/chart: {{ include "cluster-observability-operator.chart" . }}
{{ include "cluster-observability-operator.selectorLabels" . }}
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
{{- define "cluster-observability-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cluster-observability-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Namespace name
*/}}
{{- define "cluster-observability-operator.namespace" -}}
{{- .Values.namespace.name | default "openshift-cluster-observability-operator" }}
{{- end }}

{{/*
OperatorGroup name
*/}}
{{- define "cluster-observability-operator.operatorGroupName" -}}
{{- .Values.operatorGroup.name | default (include "cluster-observability-operator.namespace" .) }}
{{- end }}

{{/*
Subscription name
*/}}
{{- define "cluster-observability-operator.subscriptionName" -}}
{{- .Values.subscription.name | default "cluster-observability-operator" }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "cluster-observability-operator.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Subscription metadata labels
*/}}
{{- define "cluster-observability-operator.subscriptionMetadataLabels" -}}
{{- if .Values.metadataLabels.subscription }}
{{ toYaml .Values.metadataLabels.subscription }}
{{- end }}
{{- end }}