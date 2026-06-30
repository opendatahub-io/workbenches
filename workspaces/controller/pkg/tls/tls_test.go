/*
Copyright 2024.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package tls

import (
	"crypto/tls"
	"testing"

	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

func newAPIServer(profile map[string]interface{}) *unstructured.Unstructured {
	obj := &unstructured.Unstructured{}
	obj.SetGroupVersionKind(schema.GroupVersionKind{
		Group: "config.openshift.io", Version: "v1", Kind: "APIServer",
	})
	obj.SetName("cluster")
	if profile != nil {
		obj.Object["spec"] = map[string]interface{}{
			"tlsSecurityProfile": profile,
		}
	}
	return obj
}

func TestParseProfile(t *testing.T) {
	tests := []struct {
		name           string
		apiServer      *unstructured.Unstructured
		wantMinVersion uint16
		wantCiphers    []uint16
	}{
		{
			name:           "nil profile returns Intermediate defaults",
			apiServer:      newAPIServer(nil),
			wantMinVersion: tls.VersionTLS12,
			wantCiphers:    IntermediateCiphers,
		},
		{
			name:           "empty profile returns Intermediate defaults",
			apiServer:      newAPIServer(map[string]interface{}{}),
			wantMinVersion: tls.VersionTLS12,
			wantCiphers:    IntermediateCiphers,
		},
		{
			name: "Intermediate type returns Intermediate defaults",
			apiServer: newAPIServer(map[string]interface{}{
				"type": "Intermediate",
			}),
			wantMinVersion: tls.VersionTLS12,
			wantCiphers:    IntermediateCiphers,
		},
		{
			name: "Modern returns TLS 1.3 with nil ciphers",
			apiServer: newAPIServer(map[string]interface{}{
				"type": "Modern",
			}),
			wantMinVersion: tls.VersionTLS13,
			wantCiphers:    nil,
		},
		{
			name: "Old returns TLS 1.0 with nil ciphers",
			apiServer: newAPIServer(map[string]interface{}{
				"type": "Old",
			}),
			wantMinVersion: tls.VersionTLS10,
			wantCiphers:    nil,
		},
		{
			name: "Custom with valid ciphers",
			apiServer: newAPIServer(map[string]interface{}{
				"type": "Custom",
				"custom": map[string]interface{}{
					"minTLSVersion": "VersionTLS12",
					"ciphers": []interface{}{
						"ECDHE-ECDSA-AES128-GCM-SHA256",
						"ECDHE-RSA-AES256-GCM-SHA384",
					},
				},
			}),
			wantMinVersion: tls.VersionTLS12,
			wantCiphers: []uint16{
				tls.TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
				tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
			},
		},
		{
			name: "Custom with unsupported cipher skips it",
			apiServer: newAPIServer(map[string]interface{}{
				"type": "Custom",
				"custom": map[string]interface{}{
					"minTLSVersion": "VersionTLS12",
					"ciphers": []interface{}{
						"ECDHE-ECDSA-AES128-GCM-SHA256",
						"UNSUPPORTED-CIPHER",
					},
				},
			}),
			wantMinVersion: tls.VersionTLS12,
			wantCiphers: []uint16{
				tls.TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
			},
		},
		{
			name: "Custom with nil custom block falls back to Intermediate",
			apiServer: newAPIServer(map[string]interface{}{
				"type": "Custom",
			}),
			wantMinVersion: tls.VersionTLS12,
			wantCiphers:    IntermediateCiphers,
		},
		{
			name: "Unknown type falls back to Intermediate",
			apiServer: newAPIServer(map[string]interface{}{
				"type": "SuperSecure",
			}),
			wantMinVersion: tls.VersionTLS12,
			wantCiphers:    IntermediateCiphers,
		},
		{
			name: "Custom with all unsupported ciphers returns empty slice",
			apiServer: newAPIServer(map[string]interface{}{
				"type": "Custom",
				"custom": map[string]interface{}{
					"minTLSVersion": "VersionTLS12",
					"ciphers": []interface{}{
						"DHE-RSA-AES128-GCM-SHA256",
						"DHE-RSA-AES256-GCM-SHA384",
					},
				},
			}),
			wantMinVersion: tls.VersionTLS12,
			wantCiphers:    []uint16{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gotMinVersion, gotCiphers := parseProfile(tt.apiServer)

			if gotMinVersion != tt.wantMinVersion {
				t.Errorf("parseProfile() minVersion = %d, want %d", gotMinVersion, tt.wantMinVersion)
			}

			if tt.wantCiphers == nil {
				if gotCiphers != nil {
					t.Errorf("parseProfile() ciphers = %v, want nil", gotCiphers)
				}
				return
			}

			if gotCiphers == nil {
				t.Fatal("expected non-nil empty slice, got nil (fail-closed guard needs non-nil)")
			}
			if len(gotCiphers) != len(tt.wantCiphers) {
				t.Errorf("parseProfile() ciphers length = %d, want %d", len(gotCiphers), len(tt.wantCiphers))
				return
			}

			for i, c := range gotCiphers {
				if c != tt.wantCiphers[i] {
					t.Errorf("parseProfile() ciphers[%d] = %d, want %d", i, c, tt.wantCiphers[i])
				}
			}
		})
	}
}
