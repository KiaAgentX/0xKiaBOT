{{- define "0xkia.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "0xkia.fullname" -}}
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

{{- define "0xkia.egressName" -}}
{{- printf "%s-egress" (include "0xkia.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "0xkia.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "0xkia.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels; pass (dict "root" $ "component" "agent") */}}
{{- define "0xkia.selectorLabels" -}}
app.kubernetes.io/name: {{ include "0xkia.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "0xkia.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "0xkia.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "0xkia.image" -}}
{{- if .Values.image.digest }}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}
{{- end }}

{{- define "0xkia.agentSecretName" -}}
{{- if .Values.secrets.create }}
{{- printf "%s-agent" (include "0xkia.fullname" .) }}
{{- else }}
{{- .Values.agent.existingSecret }}
{{- end }}
{{- end }}

{{- define "0xkia.egressSecretName" -}}
{{- if .Values.secrets.create }}
{{- printf "%s-egress" (include "0xkia.fullname" .) }}
{{- else }}
{{- .Values.egress.existingSecret }}
{{- end }}
{{- end }}

{{- define "0xkia.publicUrl" -}}
{{- if .Values.publicUrl }}
{{- .Values.publicUrl | trimSuffix "/" }}
{{- else if and .Values.ingress.enabled .Values.ingress.host }}
{{- printf "%s://%s" (ternary "https" "http" (ne .Values.ingress.tlsSecretName "")) .Values.ingress.host }}
{{- end }}
{{- end }}

{{- define "0xkia.egressUrl" -}}
{{- printf "http://%s.%s.svc.cluster.local:%d" (include "0xkia.egressName" .) .Release.Namespace (int .Values.egress.port) }}
{{- end }}

{{/* Render a map as ConfigMap data, dropping empty values. */}}
{{- define "0xkia.envData" -}}
{{- range $k, $v := . }}
{{- if and (ne (toString $v) "") (ne (toString $v) "<nil>") }}
{{ $k }}: {{ toString $v | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "0xkia.validate" -}}
{{- if and (not .Values.secrets.create) (not .Values.agent.existingSecret) }}
{{- fail "Set agent.existingSecret to a Secret with the provider and platform credentials (or secrets.create=true for local testing)." }}
{{- end }}
{{- if and .Values.egress.enabled (not .Values.secrets.create) (not .Values.egress.existingSecret) }}
{{- fail "egress.enabled requires egress.existingSecret (or secrets.create=true for local testing)." }}
{{- end }}
{{- if and .Values.egress.enabled (not .Values.egress.secrets) }}
{{- fail "egress.enabled requires egress.secrets: the names whose real values live only in the egress pod." }}
{{- end }}
{{- range $k, $_ := .Values.agent.config }}
{{- if has $k (list "PORT" "PUBLIC_URL" "EGRESS_PROXY_URL" "EGRESS_SECRETS" "KIA_SERVICE_ROLE") }}
{{- fail (printf "agent.config.%s is set by the chart; use the matching chart value instead." $k) }}
{{- end }}
{{- end }}
{{- end }}

{{/* NetworkPolicy egress rules; pass .Values.networkPolicy */}}
{{- define "0xkia.np.dns" -}}
- to:
    - namespaceSelector:
        {{- toYaml .dns.namespaceSelector | nindent 8 }}
      podSelector:
        {{- toYaml .dns.podSelector | nindent 8 }}
  ports:
    - { protocol: UDP, port: 53 }
    - { protocol: TCP, port: 53 }
{{- end }}

{{- define "0xkia.np.internet" -}}
- to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
          {{- toYaml .privateCidrs | nindent 10 }}
    - ipBlock:
        cidr: ::/0
        except: [fc00::/7, fe80::/10]
{{- end }}
