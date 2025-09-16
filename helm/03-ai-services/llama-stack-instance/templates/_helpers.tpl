{{/*
Expand the name of the chart.
*/}}
{{- define "llama-stack-instance.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "llama-stack-instance.fullname" -}}
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
{{- define "llama-stack-instance.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "llama-stack-instance.labels" -}}
helm.sh/chart: {{ include "llama-stack-instance.chart" . }}
{{ include "llama-stack-instance.selectorLabels" . }}
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
{{- define "llama-stack-instance.selectorLabels" -}}
app.kubernetes.io/name: {{ include "llama-stack-instance.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the namespace to use
*/}}
{{- define "llama-stack-instance.namespace" -}}
{{- if .Values.namespace.name }}
{{- .Values.namespace.name }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "llama-stack-instance.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
LlamaStackDistribution name
*/}}
{{- define "llama-stack-instance.distributionName" -}}
{{- if .Values.llamaStackDistribution.name }}
{{- .Values.llamaStackDistribution.name }}
{{- else }}
{{- include "llama-stack-instance.fullname" . }}
{{- end }}
{{- end }}

{{/*
ConfigMap name for user configuration
*/}}
{{- define "llama-stack-instance.configMapName" -}}
{{- if .Values.llamaStackDistribution.server.userConfig.configMapName }}
{{- .Values.llamaStackDistribution.server.userConfig.configMapName }}
{{- else }}
llama-stack-config
{{- end }}
{{- end }}

{{/*
Environment variables for container spec
*/}}
{{- define "llama-stack-instance.containerEnv" -}}
- name: OTEL_SERVICE_NAME
  value: {{ .Values.llamaStackDistribution.server.containerSpec.env.otelServiceName | quote }}
{{- range $key, $value := .Values.llamaStackDistribution.server.containerSpec.env.customVariables }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
Instance labels (combination of common labels and instance-specific labels)
*/}}
{{- define "llama-stack-instance.instanceLabels" -}}
{{ include "llama-stack-instance.labels" . }}
{{- with .Values.instanceLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Instance annotations (combination of common annotations and instance-specific annotations)
*/}}
{{- define "llama-stack-instance.instanceAnnotations" -}}
{{ include "llama-stack-instance.annotations" . }}
{{- with .Values.instanceAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}