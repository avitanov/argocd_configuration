{{- define "emt-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "emt-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "emt-app.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "emt-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "emt-app.namespace" -}}
{{- default .Release.Namespace .Values.namespace.name -}}
{{- end -}}

{{- define "emt-app.labels" -}}
helm.sh/chart: {{ include "emt-app.chart" . }}
app.kubernetes.io/name: {{ include "emt-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "emt-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "emt-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "emt-app.componentLabels" -}}
{{ include "emt-app.selectorLabels" .root }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "emt-app.backendServiceName" -}}
{{- printf "%s-backend" (include "emt-app.fullname" .) -}}
{{- end -}}

{{- define "emt-app.frontendServiceName" -}}
{{- printf "%s-frontend" (include "emt-app.fullname" .) -}}
{{- end -}}

{{- define "emt-app.backendConfigMapName" -}}
{{- printf "%s-backend-config" (include "emt-app.fullname" .) -}}
{{- end -}}

{{- define "emt-app.frontendConfigMapName" -}}
{{- printf "%s-frontend-config" (include "emt-app.fullname" .) -}}
{{- end -}}

{{- define "emt-app.backendSecretName" -}}
{{- if .Values.backend.secret.existingSecret -}}
{{- .Values.backend.secret.existingSecret -}}
{{- else -}}
{{- printf "%s-backend-secret" (include "emt-app.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "emt-app.frontendBackendInternalUrl" -}}
{{- if .Values.frontend.config.BACKEND_INTERNAL_URL -}}
{{- .Values.frontend.config.BACKEND_INTERNAL_URL -}}
{{- else -}}
{{- printf "http://%s:%v" (include "emt-app.backendServiceName" .) .Values.backend.service.port -}}
{{- end -}}
{{- end -}}
