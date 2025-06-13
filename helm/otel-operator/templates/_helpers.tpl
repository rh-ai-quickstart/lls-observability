{{/*
Expand the name of the chart.
*/}}
{{- define "otel-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "otel-operator.fullname" -}}
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
{{- define "otel-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "otel-operator.labels" -}}
helm.sh/chart: {{ include "otel-operator.chart" . }}
{{ include "otel-operator.selectorLabels" . }}
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
{{- define "otel-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "otel-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Namespace name
*/}}
{{- define "otel-operator.namespace" -}}
{{- .Values.namespace.name | default "openshift-opentelemetry-operator" }}
{{- end }}

{{/*
OperatorGroup name
*/}}
{{- define "otel-operator.operatorGroupName" -}}
{{- .Values.operatorGroup.name | default (include "otel-operator.namespace" .) }}
{{- end }}

{{/*
Subscription name
*/}}
{{- define "otel-operator.subscriptionName" -}}
{{- .Values.subscription.name | default "opentelemetry-product" }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "otel-operator.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}