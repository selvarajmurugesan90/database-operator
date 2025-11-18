{{/*
Expand the name of the chart.
Returns the chart name from Chart.yaml unless overridden by values.nameOverride.
Truncates to 63 characters and removes trailing dashes to comply with Kubernetes DNS naming requirements.

Usage: {{ include "database-operator.name" . }}
Returns: "database-operator" or custom name from nameOverride
*/}}
{{- define "database-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.

Logic:
1. If fullnameOverride is set, use it (truncated to 63 chars)
2. Otherwise, check if release name already contains the chart name
   - If yes, use just the release name (avoids "myrelease-database-operator-database-operator")
   - If no, combine them as "release-name-chart-name"
3. Always truncate to 63 chars and remove trailing dashes

Usage: {{ include "database-operator.fullname" . }}
Returns: "my-release-database-operator" or custom name from fullnameOverride
*/}}
{{- define "database-operator.fullname" -}}
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
Combines chart name and version, replacing "+" with "_" for DNS compatibility.

Usage: {{ include "database-operator.chart" . }}
Returns: "database-operator-2.0.0"
*/}}
{{- define "database-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
Generates the standard set of labels for all Kubernetes resources.
Follows Kubernetes recommended labels: https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/

Includes:
- helm.sh/chart: Chart name and version
- app.kubernetes.io/name: Application name
- app.kubernetes.io/instance: Release instance name
- app.kubernetes.io/version: Application version (if AppVersion is set)
- app.kubernetes.io/managed-by: Tool managing the release (Helm)

Usage: {{ include "database-operator.labels" . | nindent 4 }}
*/}}
{{- define "database-operator.labels" -}}
helm.sh/chart: {{ include "database-operator.chart" . }}
{{ include "database-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
Generates the minimal set of labels used for pod/service selectors.
These labels must remain stable and should not include version or other changing values.

Used by:
- Service selectors
- Deployment/StatefulSet selectors
- NetworkPolicy selectors

Usage: {{ include "database-operator.selectorLabels" . | nindent 4 }}
Returns: app.kubernetes.io/name and app.kubernetes.io/instance labels
*/}}
{{- define "database-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "database-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use

Logic:
1. If serviceAccount.create is true, return serviceAccount.name or generated name
2. If serviceAccount exists but create is false, return serviceAccount.name or "default"
3. If serviceAccount is not configured at all, return "default"

This allows:
- Creating a new service account (create: true, name optional)
- Using an existing service account (create: false, name: "existing-sa")
- Using the default service account (serviceAccount not configured)

Usage: {{ include "database-operator.serviceAccountName" . }}
Returns: Service account name or "default"
*/}}
{{- define "database-operator.serviceAccountName" -}}
{{- if and (hasKey .Values "serviceAccount") .Values.serviceAccount.create -}}
    {{ default (include "database-operator.fullname" .) .Values.serviceAccount.name }}
{{- else if hasKey .Values "serviceAccount" -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- else -}}
    {{ "default" }}
{{- end -}}
{{- end -}}

{{/*
Generate job name with version
Creates a unique job name by appending the image tag version.
This is useful when generateName is true to create version-specific jobs.

Replaces dots with dashes in the version tag for DNS compatibility.

Usage: {{ include "database-operator.jobNameWithVersion" (dict "fullname" $fullname "name" $name "tag" $tag) }}
Example: "database-operator-postgresql-schema-4-25-0" for tag "4.25.0"
*/}}
{{- define "database-operator.jobNameWithVersion" -}}
{{- $name := .name -}}
{{- $tag := .tag | default "1.0.0" | replace "." "-" -}}
{{- $fullname := .fullname -}}
{{- printf "%s-%s-%s" $fullname $name $tag | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate image name with fallback to job name
Returns the container image repository, or falls back to the job name if repository is not specified.
This provides flexibility for simple configurations where image name matches job name.

Usage: {{ include "database-operator.imageName" (dict "repository" $repository "name" $name) }}
Example: If repository="postgres", returns "postgres"
         If repository is empty and name="postgresql-backup", returns "postgresql-backup"
*/}}
{{- define "database-operator.imageName" -}}
{{- $repository := .repository -}}
{{- $name := .name -}}
{{- if $repository -}}
{{- $repository -}}
{{- else -}}
{{- $name -}}
{{- end -}}
{{- end -}}
