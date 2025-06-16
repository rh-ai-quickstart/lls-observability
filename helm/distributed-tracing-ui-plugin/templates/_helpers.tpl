{{/*
Expand the name of the chart.
*/}}
{{- define "distributed-tracing-ui-plugin.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "distributed-tracing-ui-plugin.fullname" -}}
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
{{- define "distributed-tracing-ui-plugin.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "distributed-tracing-ui-plugin.labels" -}}
helm.sh/chart: {{ include "distributed-tracing-ui-plugin.chart" . }}
{{ include "distributed-tracing-ui-plugin.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: ui-plugin
app.kubernetes.io/part-of: observability
{{- if .Values.monitoring.enabled }}
{{- range $key, $value := .Values.monitoring.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- if .Values.metadata.commonLabels }}
{{- range $key, $value := .Values.metadata.commonLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "distributed-tracing-ui-plugin.selectorLabels" -}}
app.kubernetes.io/name: {{ include "distributed-tracing-ui-plugin.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
UIPlugin name - use configured name or default
*/}}
{{- define "distributed-tracing-ui-plugin.uiPluginName" -}}
{{- .Values.uiPlugin.name | default "distributed-tracing" }}
{{- end }}

{{/*
UIPlugin labels - combines common labels with UIPlugin specific labels
*/}}
{{- define "distributed-tracing-ui-plugin.uiPluginLabels" -}}
{{- include "distributed-tracing-ui-plugin.labels" . }}
{{- if .Values.uiPlugin.labels }}
{{- range $key, $value := .Values.uiPlugin.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
UIPlugin annotations - combines common annotations with UIPlugin specific annotations
*/}}
{{- define "distributed-tracing-ui-plugin.uiPluginAnnotations" -}}
{{- if .Values.metadata.commonAnnotations }}
{{- range $key, $value := .Values.metadata.commonAnnotations }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- if .Values.uiPlugin.annotations }}
{{- range $key, $value := .Values.uiPlugin.annotations }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}