{{/*
Expand the name of the chart.
*/}}
{{- define "teampass.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "teampass.fullname" -}}
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
{{- define "teampass.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "teampass.labels" -}}
helm.sh/chart: {{ include "teampass.chart" . }}
{{ include "teampass.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "teampass.selectorLabels" -}}
app.kubernetes.io/name: {{ include "teampass.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "teampass.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "teampass.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the database host.
*/}}
{{- define "teampass.databaseHost" -}}
{{- if .Values.externalDatabase.enabled }}
{{- .Values.externalDatabase.host }}
{{- else if .Values.mariadb.enabled }}
{{- printf "%s-mariadb" .Release.Name }}
{{- else }}
{{- fail "Database must be enabled (either externalDatabase.enabled or mariadb.enabled)" }}
{{- end }}
{{- end }}

{{/*
Get the database port.
*/}}
{{- define "teampass.databasePort" -}}
{{- if .Values.externalDatabase.enabled }}
{{- .Values.externalDatabase.port }}
{{- else if .Values.mariadb.enabled }}
{{- 3306 }}
{{- end }}
{{- end }}

{{/*
Get the database name.
*/}}
{{- define "teampass.databaseName" -}}
{{- if .Values.externalDatabase.enabled }}
{{- .Values.externalDatabase.database }}
{{- else if .Values.mariadb.enabled }}
{{- .Values.mariadb.auth.database }}
{{- end }}
{{- end }}

{{/*
Get the database user.
*/}}
{{- define "teampass.databaseUser" -}}
{{- if .Values.externalDatabase.enabled }}
{{- .Values.externalDatabase.user }}
{{- else if .Values.mariadb.enabled }}
{{- .Values.mariadb.auth.username }}
{{- end }}
{{- end }}

{{/*
Get the database password from secret.
*/}}
{{- define "teampass.databasePassword" -}}
{{- if .Values.externalDatabase.enabled }}
{{- .Values.externalDatabase.password }}
{{- else if .Values.mariadb.enabled }}
{{- if .Values.mariadb.auth.password }}
{{- .Values.mariadb.auth.password }}
{{- else }}
{{- include "mariadb.secret.password" . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the database secret name.
*/}}
{{- define "teampass.databaseSecretName" -}}
{{- if .Values.externalDatabase.enabled }}
{{- printf "%s-external-db" (include "teampass.fullname" .) }}
{{- else if .Values.mariadb.enabled }}
{{- printf "%s-mariadb" .Release.Name }}
{{- end }}
{{- end }}

{{/*
PHP configuration environment variables.
*/}}
{{- define "teampass.phpEnv" -}}
- name: PHP_MEMORY_LIMIT
  value: {{ .Values.teampass.php.memoryLimit | quote }}
- name: PHP_UPLOAD_MAX_FILESIZE
  value: {{ .Values.teampass.php.uploadMaxFilesize | quote }}
- name: PHP_MAX_EXECUTION_TIME
  value: {{ .Values.teampass.php.maxExecutionTime | quote }}
{{- end }}

{{/*
Installation mode environment variables.
*/}}
{{- define "teampass.installEnv" -}}
- name: INSTALL_MODE
  value: {{ .Values.teampass.installMode | quote }}
{{- if eq .Values.teampass.installMode "auto" }}
- name: ADMIN_EMAIL
  value: {{ .Values.teampass.adminEmail | quote }}
- name: ADMIN_PWD
  valueFrom:
    secretKeyRef:
      name: {{ include "teampass.fullname" . }}-admin
      key: admin-password
{{- end }}
- name: TEAMPASS_URL
  value: {{ .Values.teampass.url | quote }}
{{- end }}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "teampass.ingress.apiVersion" -}}
{{- if and (.Capabilities.APIVersions.Has "networking.k8s.io/v1") (semverCompare ">= 1.19-0" .Capabilities.KubeVersion.Version) }}
{{- print "networking.k8s.io/v1" }}
{{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" }}
{{- print "networking.k8s.io/v1beta1" }}
{{- else }}
{{- print "extensions/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "teampass.deployment.apiVersion" -}}
{{- print "apps/v1" }}
{{- end }}

{{/*
Return the appropriate apiVersion for PDB.
*/}}
{{- define "teampass.pdb.apiVersion" -}}
{{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) }}
{{- print "policy/v1" }}
{{- else }}
{{- print "policy/v1beta1" }}
{{- end }}
{{- end }}
