{{/*
Expand the name of the chart.
*/}}
{{- define "grafana-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "grafana-operator.fullname" -}}
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
{{- define "grafana-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "grafana-operator.labels" -}}
helm.sh/chart: {{ include "grafana-operator.chart" . }}
{{ include "grafana-operator.selectorLabels" . }}
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
{{- define "grafana-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grafana-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Namespace name
*/}}
{{- define "grafana-operator.namespace" -}}
{{- .Values.namespace.name | default "openshift-grafana-operator" }}
{{- end }}

{{/*
OperatorGroup name
*/}}
{{- define "grafana-operator.operatorGroupName" -}}
{{- .Values.operatorGroup.name | default (include "grafana-operator.namespace" .) }}
{{- end }}

{{/*
Subscription name
*/}}
{{- define "grafana-operator.subscriptionName" -}}
{{- .Values.subscription.name | default "grafana" }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "grafana-operator.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}