{{- define "demo-app-risky.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "demo-app-risky.fullname" -}}
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

{{- define "demo-app-risky.labels" -}}
helm.sh/chart: {{ include "demo-app-risky.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "demo-app-risky.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
security-risk: critical
{{- end }}

{{- define "demo-app-risky.selectorLabels" -}}
app.kubernetes.io/name: {{ include "demo-app-risky.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}