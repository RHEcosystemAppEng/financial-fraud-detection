{{- define "fraud-preprocess.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "fraud-preprocess.imageNamespace" -}}
{{- default .Release.Namespace .Values.image.namespace -}}
{{- end -}}
