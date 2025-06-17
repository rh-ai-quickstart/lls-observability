{{/*
Expand the name of the chart.
*/}}
{{- define "uwm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "uwm.fullname" -}}
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
{{- define "uwm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "uwm.labels" -}}
helm.sh/chart: {{ include "uwm.chart" . }}
{{ include "uwm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "uwm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "uwm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "uwm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "uwm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get target namespace for monitoring
*/}}
{{- define "uwm.targetNamespace" -}}
{{- if .Values.global.targetNamespace }}
{{- .Values.global.targetNamespace }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Merge common labels with specific labels
*/}}
{{- define "uwm.mergeLabels" -}}
{{- $common := .Values.common.commonLabels | default dict }}
{{- $specific := .specific | default dict }}
{{- $merged := merge $specific $common }}
{{- range $key, $value := $merged }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
Merge common annotations with specific annotations
*/}}
{{- define "uwm.mergeAnnotations" -}}
{{- $common := .Values.common.commonAnnotations | default dict }}
{{- $specific := .specific | default dict }}
{{- $merged := merge $specific $common }}
{{- range $key, $value := $merged }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}