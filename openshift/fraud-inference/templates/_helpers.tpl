{{- define "fraud-inference.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "fraud-inference.imageNamespace" -}}
{{- default .Release.Namespace .Values.image.namespace -}}
{{- end -}}

{{- define "fraud-inference.tritonHost" -}}
{{- if .Values.route.host -}}
{{- .Values.route.host -}}
{{- else -}}
{{- printf "fraud-triton-%s.%s" .Release.Namespace .Values.route.clusterDomain -}}
{{- end -}}
{{- end -}}
