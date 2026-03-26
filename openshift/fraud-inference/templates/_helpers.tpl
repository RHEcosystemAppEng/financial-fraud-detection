{{- define "fraud-inference.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "fraud-inference.imageNamespace" -}}
{{- default .Release.Namespace .Values.image.namespace -}}
{{- end -}}
