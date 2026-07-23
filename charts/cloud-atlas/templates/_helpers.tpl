{{- define "cloud-atlas.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "cloud-atlas.labels" -}}
app.kubernetes.io/name: {{ include "cloud-atlas.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: multi-cloud-gitops-platform
cloud: {{ .Values.cloud }}
{{- end }}
