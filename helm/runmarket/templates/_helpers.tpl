{{- define "runmarket.name" -}}
{{- .Chart.Name }}
{{- end }}

{{- define "runmarket.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "runmarket.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "runmarket.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "runmarket.selectorLabels" -}}
app.kubernetes.io/name: {{ include "runmarket.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "runmarket.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "runmarket.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* PostgreSQL host */}}
{{- define "runmarket.postgresql.host" -}}
{{- printf "%s-postgresql" .Release.Name }}
{{- end }}

{{/* PostgreSQL secret name */}}
{{- define "runmarket.postgresql.secretName" -}}
{{- printf "%s-postgresql" .Release.Name }}
{{- end }}
