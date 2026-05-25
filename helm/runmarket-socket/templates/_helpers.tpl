{{- define "runmarket-socket.name" -}}
{{- .Chart.Name }}
{{- end }}

{{- define "runmarket-socket.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "runmarket-socket.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "runmarket-socket.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "runmarket-socket.selectorLabels" -}}
app.kubernetes.io/name: {{ include "runmarket-socket.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "runmarket-socket.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "runmarket-socket.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Redis host */}}
{{- define "runmarket-socket.redis.host" -}}
{{- printf "%s-redis" .Release.Name }}
{{- end }}
