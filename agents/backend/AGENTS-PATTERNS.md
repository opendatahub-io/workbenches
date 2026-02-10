---
name: BFF Agent - Patterns
description: Detailed code patterns and examples for the Go Backend-For-Frontend API server.
---

# Backend Module - Detailed Patterns

This file contains detailed patterns and examples for the backend module.

**For essential guidelines, see [AGENTS.md](./AGENTS.md).**

---

## Table of Contents

- [Testing Guidelines](#testing-guidelines)
- [Swagger / OpenAPI Patterns](#swagger--openapi-patterns)
- [Go Best Practices](#go-best-practices)
- [Handler Patterns](#handler-patterns)
- [Validation Patterns](#validation-patterns)
- [Domain Logic](#domain-logic)
- [Repository Patterns](#repository-patterns)
- [Error Handling](#error-handling)
- [Persistence & Data](#persistence--data)
- [Observability and Logging](#observability-and-logging)
- [Performance & Reliability](#performance--reliability)
- [Common Tasks](#common-tasks)
- [Request/Response Patterns](#requestresponse-patterns)
- [Naming Conventions](#naming-conventions)
- [API Design](#api-design)
- [Kubernetes Integration](#kubernetes-integration)
- [Authentication & Authorization](#authentication--authorization)
- [Type Definitions and Models](#type-definitions-and-models)
- [Go-Specific Patterns](#go-specific-patterns)

---

## Testing Guidelines

### Test Framework

**Use Ginkgo and Gomega for BDD-style tests:**

```go
import (
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Workspaces Handler", func() {

	// NOTE: the tests in this context work on the same resources, they must be run in order.
	//       also, they assume a specific state of the cluster, so cannot be run in parallel with other tests.
	//       therefore, we run them using the `Ordered` and `Serial` Ginkgo decorators.
	Context("with existing Workspaces", Serial, Ordered, func() {

		const namespaceName = "ws-test-ns"

		var (
			workspaceName     string
			workspaceKey      types.NamespacedName
			workspaceKindName string
		)

		BeforeAll(func() {
			uniqueName := "ws-handler-test"
			workspaceName = fmt.Sprintf("workspace-%s", uniqueName)
			workspaceKey = types.NamespacedName{Name: workspaceName, Namespace: namespaceName}
			workspaceKindName = fmt.Sprintf("workspacekind-%s", uniqueName)

			By("creating the Namespace")
			namespace := &corev1.Namespace{
				ObjectMeta: metav1.ObjectMeta{
					Name: namespaceName,
				},
			}
			Expect(k8sClient.Create(ctx, namespace)).To(Succeed())

			By("creating a WorkspaceKind")
			workspaceKind := NewExampleWorkspaceKind(workspaceKindName)
			Expect(k8sClient.Create(ctx, workspaceKind)).To(Succeed())

			By("creating a Workspace")
			workspace := NewExampleWorkspace(workspaceName, namespaceName, workspaceKindName)
			Expect(k8sClient.Create(ctx, workspace)).To(Succeed())
		})

		AfterAll(func() {
			By("deleting the Workspace")
			workspace := &kubefloworgv1beta1.Workspace{
				ObjectMeta: metav1.ObjectMeta{
					Name:      workspaceName,
					Namespace: namespaceName,
				},
			}
			Expect(k8sClient.Delete(ctx, workspace)).To(Succeed())

			By("deleting the WorkspaceKind")
			workspaceKind := &kubefloworgv1beta1.WorkspaceKind{
				ObjectMeta: metav1.ObjectMeta{
					Name: workspaceKindName,
				},
			}
			Expect(k8sClient.Delete(ctx, workspaceKind)).To(Succeed())

			By("deleting the Namespace")
			namespace := &corev1.Namespace{
				ObjectMeta: metav1.ObjectMeta{
					Name: namespaceName,
				},
			}
			Expect(k8sClient.Delete(ctx, namespace)).To(Succeed())
		})

		It("should get workspace successfully", func() {
			By("creating the HTTP request")
			path := strings.Replace(WorkspacesByNamePath, ":"+NamespacePathParam, namespaceName, 1)
			path = strings.Replace(path, ":"+ResourceNamePathParam, workspaceName, 1)
			req, err := http.NewRequest(http.MethodGet, path, http.NoBody)
			Expect(err).NotTo(HaveOccurred())

			By("setting the auth headers")
			req.Header.Set(userIdHeader, adminUser)

			By("executing GetWorkspaceHandler")
			ps := httprouter.Params{
				httprouter.Param{Key: NamespacePathParam, Value: namespaceName},
				httprouter.Param{Key: ResourceNamePathParam, Value: workspaceName},
			}
			rr := httptest.NewRecorder()
			a.GetWorkspaceHandler(rr, req, ps)

			By("checking the response")
			Expect(rr.Code).To(Equal(http.StatusOK), descUnexpectedHTTPStatus, rr.Body.String())
		})
	})
})
```

### Test Organization

**Use Ginkgo decorators for test control:**

- `Serial` - Tests run serially, not in parallel
- `Ordered` - Tests run in order (use for integration tests)
- `BeforeAll` / `AfterAll` - Run once per context (setup/cleanup)
- `BeforeEach` / `AfterEach` - Run before/after each test
- `By` - Add descriptive steps in tests

### Testing Best Practices

✅ **DO**: Use unique resource names

```go
uniqueName := "ws-handler-test"
workspaceName := fmt.Sprintf("workspace-%s", uniqueName)
workspaceKindName := fmt.Sprintf("workspacekind-%s", uniqueName)
```

✅ **DO**: Use Gomega matchers

```go
Expect(err).ToNot(HaveOccurred())
Expect(err).To(Succeed())
Expect(rr.Code).To(Equal(http.StatusOK))
Expect(workspaces).To(HaveLen(3))
```

✅ **DO**: Test HTTP handlers with httptest

```go
By("creating the HTTP request")
body := strings.NewReader(`{"data":{"name":"test-workspace","kind":"jupyterlab"}}`)
path := strings.Replace(AllWorkspacesPath+"/"+namespaceName, ":"+NamespacePathParam, namespaceName, 1)
req, err := http.NewRequest(http.MethodPost, path, body)
Expect(err).NotTo(HaveOccurred())
req.Header.Set("Content-Type", "application/json")

By("setting the auth headers")
req.Header.Set(userIdHeader, adminUser)

By("executing CreateWorkspaceHandler")
ps := httprouter.Params{
	httprouter.Param{Key: NamespacePathParam, Value: namespaceName},
}
rr := httptest.NewRecorder()
a.CreateWorkspaceHandler(rr, req, ps)

By("checking the response")
Expect(rr.Code).To(Equal(http.StatusCreated), descUnexpectedHTTPStatus, rr.Body.String())
```

✅ **DO**: Test all error paths

```go
It("should return 422 for invalid request", func() {
	body := strings.NewReader(`{"data":{"name":""}}`)
	req := httptest.NewRequest(http.MethodPost, path, body)
	Expect(rr.Code).To(Equal(http.StatusUnprocessableEntity))
})

It("should return 404 when resource doesn't exist", func() {
	Expect(rr.Code).To(Equal(http.StatusNotFound))
})
```

### Table-Driven Tests

```go
type testCase struct {
	name           string
	inputName      string
	inputNamespace string
	expectedError  bool
	expectedCode   int
}

testCases := []testCase{
	{
		name:           "valid workspace",
		inputName:      "test-workspace",
		inputNamespace: "default",
		expectedError:  false,
		expectedCode:   http.StatusOK,
	},
	{
		name:           "empty name",
		inputName:      "",
		inputNamespace: "default",
		expectedError:  true,
		expectedCode:   http.StatusUnprocessableEntity,
	},
}

for _, tc := range testCases {
	It(tc.name, func() {
		// Test using tc fields
	})
}
```

---

## Swagger / OpenAPI Patterns

### Swagger Annotations

**All API handlers MUST have Swagger annotations:**

```go
// GetWorkspaceHandler retrieves a specific workspace by namespace and name.
//
//	@Summary		Get workspace
//	@Description	Returns the current state of a specific workspace.
//	@Tags			workspaces
//	@ID				getWorkspace
//	@Accept			json
//	@Produce		json
//	@Param			namespace		path		string				true	"Namespace"	extensions(x-example=kubeflow-user-example-com)
//	@Param			workspace_name	path		string				true	"Name"		extensions(x-example=my-workspace)
//	@Success		200				{object}	WorkspaceEnvelope	"Successful operation."
//	@Failure		401				{object}	ErrorEnvelope		"Unauthorized."
//	@Failure		403				{object}	ErrorEnvelope		"Forbidden."
//	@Failure		404				{object}	ErrorEnvelope		"Not Found."
//	@Failure		422				{object}	ErrorEnvelope		"Validation error."
//	@Failure		500				{object}	ErrorEnvelope		"Internal server error."
//	@Router			/workspaces/{namespace}/{workspace_name} [get]
func (a *App) GetWorkspaceHandler(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	// ...
}
```

### Required Annotations

- `@Summary` - Short description (one line)
- `@Description` - Detailed description
- `@Tags` - Group endpoints (e.g., "workspaces", "secrets")
- `@ID` - Unique operation ID (camelCase)
- `@Accept` - Request content type (usually `json`)
- `@Produce` - Response content type (usually `json`)
- `@Param` - Path/query/body parameters
- `@Success` - Success response
- `@Failure` - Error responses (all possible status codes)
- `@Router` - Route pattern and HTTP method

### Status Codes to Document

- `200` - OK (GET successful)
- `201` - Created (POST successful)
- `204` - No Content (DELETE successful)
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict
- `422` - Unprocessable Entity
- `500` - Internal Server Error

---

## Go Best Practices

### Context Handling

✅ **DO**: Propagate context through all function calls

```go
func (r *Repository) GetWorkspace(ctx context.Context, namespace, name string) (*Model, error) {
	obj := &CRD{}
	if err := r.client.Get(ctx, key, obj); err != nil {
		return nil, err
	}
	return convertToModel(ctx, obj), nil
}
```

✅ **DO**: Use context timeouts for external operations

```go
func (h *Handler) handleLongOperation(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 30*time.Second)
	defer cancel()

	result, err := h.service.LongOperation(ctx)
	if err != nil {
		if ctx.Err() == context.DeadlineExceeded {
			http.Error(w, "operation timed out", http.StatusGatewayTimeout)
			return
		}
		if ctx.Err() == context.Canceled {
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	// ... write response
}
```

✅ **DO**: Check for context cancellation in long loops

```go
for _, item := range items {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}
	if err := processItem(ctx, item); err != nil {
		return err
	}
}
```

### Pointer Handling

✅ **DO**: Use k8s.io/utils/ptr helpers

```go
import "k8s.io/utils/ptr"

obj.Spec.Paused = ptr.To(true)
obj.Spec.Replicas = ptr.To[int32](3)

paused := ptr.Deref(obj.Spec.Paused, false)
replicas := ptr.Deref(obj.Spec.Replicas, 1)
```

### Error Wrapping

✅ **DO**: Wrap errors with context using %w

```go
if err != nil {
	return fmt.Errorf("error creating workspace %s in namespace %s: %w", name, namespace, err)
}
```

✅ **DO**: Use errors.Is() and errors.As()

```go
if errors.Is(err, repository.ErrWorkspaceNotFound) { }

var statusErr apierrors.APIStatus
if errors.As(err, &statusErr) {
	causes := statusErr.Status().Details.Causes
}
```

### Constants and Magic Values

✅ **DO**: Define constants at package level

```go
const (
	Version    = "1.0.0"
	PathPrefix = "/api/v1"

	MediaTypeJson = "application/json"

	NamespacePathParam    = "namespace"
	ResourceNamePathParam = "name"

	errMsgPathParamsInvalid  = "path parameters were invalid"
	errMsgRequestBodyInvalid = "request body was invalid"
)
```

### Slice and Map Handling

✅ **DO**: Initialize slices with capacity when size is known

```go
models := make([]Model, len(items))
for i, item := range items {
	models[i] = convertToModel(item)
}
```

✅ **DO**: Copy maps to avoid shared references

```go
labels := make(map[string]string)
for k, v := range original {
	labels[k] = v
}
```

---

## Handler Patterns

### Handler Pattern Template

```go
// @Summary Brief description
// @Tags category
// @Success 200 {object} ResponseType
// @Failure 400 {object} ErrorResponse
// @Router /path [method]
func (h *Handler) HandleX(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    // 1. Parse and validate input
    // 2. Call business logic
    // 3. Handle errors with context
    // 4. Return response
}
```

### Handler Structure

**All handlers follow a consistent structure:**

1. Extract path parameters
2. Validate path parameters
3. Validate Content-Type (for POST/PUT)
4. Decode request body (for POST/PUT)
5. Validate request body
6. Perform authorization checks
7. Call repository method
8. Handle repository errors
9. Return success response

### Example Handler

```go
func (a *App) GetWorkspaceHandler(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
	namespace := ps.ByName(NamespacePathParam)
	workspaceName := ps.ByName(ResourceNamePathParam)

	var valErrs field.ErrorList
	valErrs = append(valErrs, helper.ValidateKubernetesNamespaceName(field.NewPath(NamespacePathParam), namespace)...)
	valErrs = append(valErrs, helper.ValidateWorkspaceName(field.NewPath(ResourceNamePathParam), workspaceName)...)
	if len(valErrs) > 0 {
		a.failedValidationResponse(w, r, errMsgPathParamsInvalid, valErrs, nil)
		return
	}

	authPolicies := []*auth.ResourcePolicy{
		auth.NewResourcePolicy(auth.VerbGet, auth.Workspaces, auth.ResourcePolicyResourceMeta{Namespace: namespace, Name: workspaceName}),
	}
	if success := a.requireAuth(w, r, authPolicies); !success {
		return
	}

	workspace, err := a.repositories.Workspace.GetWorkspace(r.Context(), namespace, workspaceName)
	if err != nil {
		if errors.Is(err, repository.ErrWorkspaceNotFound) {
			a.notFoundResponse(w, r)
			return
		}
		a.serverErrorResponse(w, r, err)
		return
	}

	responseEnvelope := &WorkspaceEnvelope{Data: workspace}
	a.dataResponse(w, r, responseEnvelope)
}
```

### Handler Best Practices

✅ **DO**: Return immediately after error responses

```go
if len(valErrs) > 0 {
	a.failedValidationResponse(w, r, errMsgPathParamsInvalid, valErrs, nil)
	return // Must return here
}
```

✅ **DO**: Check auth success and return early

```go
if success := a.requireAuth(w, r, authPolicies); !success {
	return
}
```

✅ **DO**: Use specific error checks with errors.Is()

```go
if errors.Is(err, repository.ErrWorkspaceNotFound) {
	a.notFoundResponse(w, r)
	return
}
```

---

## Validation Patterns

### Path Parameter Validation

```go
var valErrs field.ErrorList
valErrs = append(valErrs, helper.ValidateKubernetesNamespaceName(field.NewPath(NamespacePathParam), namespace)...)
valErrs = append(valErrs, helper.ValidateWorkspaceName(field.NewPath(ResourceNamePathParam), workspaceName)...)
if len(valErrs) > 0 {
	a.failedValidationResponse(w, r, errMsgPathParamsInvalid, valErrs, nil)
	return
}
```

### Request Body Validation

**Models MUST implement a `Validate()` method:**

```go
// Validate validates the WorkspaceCreate struct.
// NOTE: we only do basic validation, more complex validation is done by the controller.
func (w *WorkspaceCreate) Validate(prefix *field.Path) []*field.Error {
	var errs []*field.Error

	// validate the workspace name
	namePath := prefix.Child("name")
	errs = append(errs, helper.ValidateWorkspaceName(namePath, w.Name)...)

	// validate the workspace kind name
	kindPath := prefix.Child("kind")
	errs = append(errs, helper.ValidateWorkspaceKindName(kindPath, w.Kind)...)

	// validate pod template
	podTemplatePath := prefix.Child("podTemplate")
	errs = append(errs, w.PodTemplate.Validate(podTemplatePath)...)

	return errs
}
```

### Validation Helper Functions

```go
helper.ValidateKubernetesNamespaceName(path, value)
helper.ValidateWorkspaceName(path, value)
helper.ValidateWorkspaceKindName(path, value)
helper.ValidateKubernetesSecretName(path, value)
helper.ValidateKubernetesLabels(path, labels)
helper.ValidateKubernetesAnnotations(path, annotations)
helper.ValidateFieldIsNotEmpty(path, value)
helper.ValidateFieldIsDNS1123Subdomain(path, value)
```

✅ **DO**: Accumulate all validation errors

```go
var errs []*field.Error
errs = append(errs, helper.ValidateFieldIsNotEmpty(prefix.Child("name"), w.Name)...)
errs = append(errs, helper.ValidateFieldIsNotEmpty(prefix.Child("kind"), w.Kind)...)
return errs // Return all errors at once
```

---

## Domain Logic

- Keep business rules explicit and readable
- Business logic belongs in `internal/models/` packages, not in handlers
- Avoid leaking infrastructure concerns into domain logic
- Domain models **SHOULD** be independent of transport layer

### Model Conversion Functions

```go
func NewWorkspaceListItemFromWorkspace(
	ws *kubefloworgv1beta1.Workspace,
	wsk *kubefloworgv1beta1.WorkspaceKind,
) WorkspaceListItem {
	if wsk == nil || wsk.UID == "" {
		// Handle missing WorkspaceKind
	}

	var wsState WorkspaceState
	switch ws.Status.State {
	case kubefloworgv1beta1.WorkspaceStateRunning:
		wsState = WorkspaceStateRunning
	// ... other cases
	}

	// Copy maps to avoid references
	podLabels := make(map[string]string)
	for k, v := range ws.Spec.PodTemplate.PodMetadata.Labels {
		podLabels[k] = v
	}

	return WorkspaceListItem{
		Name:      ws.Name,
		Namespace: ws.Namespace,
		State:     wsState,
	}
}
```

---

## Repository Patterns

### Repository Structure

```go
type WorkspaceRepository struct {
	client client.Client
}

func NewWorkspaceRepository(cl client.Client) *WorkspaceRepository {
	return &WorkspaceRepository{client: cl}
}
```

### Get Single Resource

```go
func (r *WorkspaceRepository) GetWorkspace(ctx context.Context, namespace, name string) (*models.WorkspaceUpdate, error) {
	workspace := &kubefloworgv1beta1.Workspace{}
	key := client.ObjectKey{Namespace: namespace, Name: name}

	if err := r.client.Get(ctx, key, workspace); err != nil {
		if apierrors.IsNotFound(err) {
			return nil, ErrWorkspaceNotFound
		}
		return nil, err
	}

	model := models.NewWorkspaceUpdateModelFromWorkspace(workspace)
	return model, nil
}
```

### Custom Repository Errors

```go
var (
	ErrWorkspaceNotFound         = fmt.Errorf("workspace not found")
	ErrWorkspaceAlreadyExists    = fmt.Errorf("workspace already exists")
	ErrWorkspaceInvalidState     = fmt.Errorf("workspace is in an invalid state")
	ErrWorkspaceRevisionConflict = fmt.Errorf("revision conflict")
)
```

---

## Error Handling

### Error Response Types

- `serverErrorResponse(w, r, err)` - HTTP 500
- `badRequestResponse(w, r, err)` - HTTP 400
- `unauthorizedResponse(w, r)` - HTTP 401
- `forbiddenResponse(w, r, msg)` - HTTP 403
- `notFoundResponse(w, r)` - HTTP 404
- `conflictResponse(w, r, err, k8sCauses)` - HTTP 409
- `failedValidationResponse(w, r, msg, valErrs, k8sCauses)` - HTTP 422

### Error Handling in Handlers

```go
workspace, err := a.repositories.Workspace.CreateWorkspace(r.Context(), workspaceCreate, namespace)
if err != nil {
	if errors.Is(err, repository.ErrWorkspaceAlreadyExists) {
		causes := helper.StatusCausesFromAPIStatus(err)
		a.conflictResponse(w, r, err, causes)
		return
	}

	if apierrors.IsInvalid(err) {
		causes := helper.StatusCausesFromAPIStatus(err)
		a.failedValidationResponse(w, r, errMsgKubernetesValidation, nil, causes)
		return
	}

	a.serverErrorResponse(w, r, fmt.Errorf("error creating workspace: %w", err))
	return
}
```

---

## Persistence & Data

- Respect existing transaction boundaries
- Use controller-runtime caches for read operations
- Avoid N+1 query patterns
- Handle Kubernetes eventual consistency appropriately

### Kubernetes Client Patterns

```go
// Get single object
obj := &kubefloworgv1beta1.Workspace{}
err := r.client.Get(ctx, client.ObjectKey{Namespace: ns, Name: name}, obj)

// List objects
list := &kubefloworgv1beta1.WorkspaceList{}
err := r.client.List(ctx, list, client.InNamespace(ns))

// Create/Update/Delete
err := r.client.Create(ctx, obj)
err := r.client.Update(ctx, obj)
err := r.client.Delete(ctx, obj)
```

---

## Observability and Logging

### Logging Methods

```go
a.LogError(r, err)
a.LogWarn(r, message)
a.LogInfo(r, message)
```

### Logging Patterns

✅ **DO**: Include context in log messages

```go
log.Error("failed to create workspace",
	"namespace", namespace,
	"name", workspaceName,
	"error", err,
)
```

❌ **DON'T**: Log sensitive data

```go
// Bad
log.Info("authenticated user", "token", authToken)

// Good
log.Info("authenticated user", "username", username)
```

---

## Request/Response Patterns

### Envelope Pattern

```go
type Envelope[D any] struct {
	Data D `json:"data"`
}

type WorkspaceEnvelope Envelope[*models.WorkspaceUpdate]
type WorkspaceCreateEnvelope Envelope[*models.WorkspaceCreate]
type WorkspaceListEnvelope Envelope[[]models.WorkspaceListItem]

type ErrorEnvelope struct {
	Error *HTTPError `json:"error"`
}
```

### Request Body Decoding

```go
bodyEnvelope := &WorkspaceCreateEnvelope{}
err := a.DecodeJSON(r, bodyEnvelope)
if err != nil {
	if a.IsMaxBytesError(err) {
		a.requestEntityTooLargeResponse(w, r, err)
		return
	}
	a.badRequestResponse(w, r, fmt.Errorf("error decoding request body: %w", err))
	return
}

if bodyEnvelope.Data == nil {
	valErrs := field.ErrorList{field.Required(field.NewPath("data"), "data is required")}
	a.failedValidationResponse(w, r, errMsgRequestBodyInvalid, valErrs, nil)
	return
}

workspaceCreate := bodyEnvelope.Data
```

---

## Naming Conventions

### File Naming

- **Handlers**: `<resource>_handler.go`
- **Tests**: `<resource>_handler_test.go`
- **Models**: `types.go`, `funcs.go`, `types_write.go`, `funcs_write.go`
- **Repositories**: `repo.go` (in resource-specific directory)

### Function Naming

```go
// Handler methods (exported, on App receiver)
func (a *App) GetWorkspaceHandler(w http.ResponseWriter, r *http.Request, ps httprouter.Params)

// Repository methods (exported, on Repository receiver)
func (r *WorkspaceRepository) GetWorkspace(ctx context.Context, namespace, name string) (*Model, error)

// Model conversion functions (exported)
func NewWorkspaceListItemFromWorkspace(ws *CRD, wsk *RelatedCRD) Model

// Helper functions (exported)
func ValidateWorkspaceName(path *field.Path, value string) field.ErrorList
```

---

## API Design

### Adding a New Endpoint

1. Define models in `internal/models/<resource>/`
2. Add repository method in `internal/repositories/<resource>/repo.go`
3. Add handler in `api/<resource>_handler.go`
4. Register route in `api/app.go`
5. Add tests in `api/<resource>_handler_test.go`
6. Regenerate Swagger: `make swag`

### RESTful Patterns

- `GET /resources` - List all
- `GET /resources/:namespace` - List by namespace
- `GET /resources/:namespace/:name` - Get single
- `POST /resources/:namespace` - Create
- `PUT /resources/:namespace/:name` - Update
- `DELETE /resources/:namespace/:name` - Delete

---

## Kubernetes Integration

### Using controller-runtime Client

```go
import "sigs.k8s.io/controller-runtime/pkg/client"

repos := repositories.NewRepositories(k8sClient)

func (r *Repository) GetResource(ctx context.Context) error {
	obj := &CustomResource{}
	err := r.client.Get(ctx, client.ObjectKey{Namespace: ns, Name: name}, obj)
	return err
}
```

### Kubernetes Error Handling

```go
import apierrors "k8s.io/apimachinery/pkg/api/errors"

if apierrors.IsNotFound(err) {
	return nil, ErrResourceNotFound
}

if apierrors.IsAlreadyExists(err) {
	return nil, ErrResourceAlreadyExists
}

if apierrors.IsConflict(err) {
	causes := helper.StatusCausesFromAPIStatus(err)
	return nil, fmt.Errorf("%w: %v", ErrRevisionConflict, causes)
}
```

---

## Authentication & Authorization

### Authentication Headers

- `kubeflow-userid` - Authenticated user's ID
- `kubeflow-groups` - Comma-separated list of groups

### Authorization Pattern

```go
authPolicies := []*auth.ResourcePolicy{
	auth.NewResourcePolicy(
		auth.VerbGet,
		auth.Workspaces,
		auth.ResourcePolicyResourceMeta{
			Namespace: namespace,
			Name: workspaceName,
		},
	),
}
if success := a.requireAuth(w, r, authPolicies); !success {
	return
}
```

### Resource Policy Structure

```go
// For specific resource
auth.NewResourcePolicy(auth.VerbGet, auth.Workspaces, auth.ResourcePolicyResourceMeta{
	Namespace: "default",
	Name: "my-workspace",
})

// For all resources in namespace
auth.NewResourcePolicy(auth.VerbList, auth.Workspaces, auth.ResourcePolicyResourceMeta{
	Namespace: "default",
	Name: "",
})

// For cluster-scoped resources
auth.NewResourcePolicy(auth.VerbList, auth.WorkspaceKinds, auth.ResourcePolicyResourceMeta{
	Namespace: "",
	Name: "",
})
```

---

## Type Definitions and Models

### Model Structure

```
internal/models/
├── common/              # Shared types
├── workspaces/          # Workspace models
│   ├── types.go         # Read models
│   ├── funcs.go         # Conversion logic
│   ├── types_write.go   # Write models
│   └── funcs_write.go   # Write conversion logic
```

### JSON Naming Convention (CRITICAL)

**All model struct fields MUST use camelCase in JSON tags.**

```go
// Good - camelCase JSON properties
type WorkspaceListItem struct {
	Name          string `json:"name"`
	DisplayName   string `json:"displayName"`
	LastUpdatedAt string `json:"lastUpdatedAt"`
}
```

### Struct Definition Patterns

```go
type WorkspaceListItem struct {
	Name      string        `json:"name"`
	Namespace string        `json:"namespace"`
	State     WorkspaceState `json:"state"`
	Labels    map[string]string `json:"labels"`
	CreatedAt int64         `json:"createdAt"`
	UpdatedAt *int64        `json:"updatedAt,omitempty"`
}

type WorkspaceState string

const (
	WorkspaceStateRunning     WorkspaceState = "Running"
	WorkspaceStateTerminating WorkspaceState = "Terminating"
	WorkspaceStatePaused      WorkspaceState = "Paused"
	WorkspaceStatePending     WorkspaceState = "Pending"
	WorkspaceStateError       WorkspaceState = "Error"
	WorkspaceStateUnknown     WorkspaceState = "Unknown"
)
```

---

## Performance & Reliability

- Be mindful of latency and resource usage
- Avoid unbounded retries or loops
- Set appropriate timeouts for operations
- Use context cancellation properly
- Implement rate limiting and backpressure
- Kubernetes operations can be slow - handle timeouts gracefully

---

## Common Tasks

### Adding a New Model

1. **Create types** in `internal/models/<resource>/types.go`:

   ```go
   type ResourceListItem struct {
       Name      string `json:"name"`
       Namespace string `json:"namespace"`
       State     ResourceState `json:"state"`
   }

   type ResourceState string
   const (
       ResourceStateRunning ResourceState = "Running"
       ResourceStatePending ResourceState = "Pending"
   )
   ```

2. **Add write types** in `types_write.go` (for create/update):

   ```go
   type ResourceCreate struct {
       Name string `json:"name"`
       Kind string `json:"kind"`
   }

   // Validate validates the ResourceCreate struct.
   // NOTE: we only do basic validation, more complex validation is done by the controller.
   func (r *ResourceCreate) Validate(prefix *field.Path) []*field.Error {
       var errs []*field.Error

       // validate the name
       namePath := prefix.Child("name")
       errs = append(errs, helper.ValidateFieldIsNotEmpty(namePath, r.Name)...)

       // validate the kind
       kindPath := prefix.Child("kind")
       errs = append(errs, helper.ValidateFieldIsNotEmpty(kindPath, r.Kind)...)

       return errs
   }
   ```

3. **Add conversion functions** in `funcs.go`:

   ```go
   func NewResourceFromCRD(crd *CRD) ResourceListItem {
       return ResourceListItem{
           Name:      crd.Name,
           Namespace: crd.Namespace,
           State:     convertState(crd.Status.State),
       }
   }
   ```

### Adding Repository Methods

1. **Add method** to `internal/repositories/<resource>/repo.go`:

   ```go
   func (r *ResourceRepository) GetResource(ctx context.Context, namespace string, resourceName string) (*models.ResourceUpdate, error) {
       // get resource
       resource := &kubefloworgv1beta1.Resource{}
       if err := r.client.Get(ctx, client.ObjectKey{Namespace: namespace, Name: resourceName}, resource); err != nil {
           if apierrors.IsNotFound(err) {
               return nil, ErrResourceNotFound
           }
           return nil, err
       }

       // convert resource to model
       resourceUpdateModel := models.NewResourceUpdateModelFromResource(resource)

       return resourceUpdateModel, nil
   }
   ```

2. **Define custom errors** at package level:

   ```go
   var (
       ErrResourceNotFound         = fmt.Errorf("resource not found")
       ErrResourceAlreadyExists    = fmt.Errorf("resource already exists")
       ErrResourceInvalidState     = fmt.Errorf("resource is in an invalid state for this operation")
       ErrResourceRevisionConflict = fmt.Errorf("current resource revision does not match request")
   )
   ```

3. **Add tests** using Ginkgo/Gomega

### Adding Validation Helper

1. **Add function** to `internal/helper/validation.go`:

   ```go
   func ValidateResourceName(path *field.Path, value string) field.ErrorList {
       return ValidateFieldIsDNS1123Subdomain(path, value)
   }
   ```

2. **Reuse existing validators** when possible:

   - `ValidateFieldIsNotEmpty()`
   - `ValidateFieldIsDNS1123Subdomain()`
   - `ValidateFieldIsDNS1123Label()`
   - `ValidateKubernetesLabels()`
   - `ValidateKubernetesAnnotations()`

3. **Add tests** in `internal/helper/validation_test.go`

### Modifying OpenAPI Spec

1. Update Swagger annotations in handler functions
2. Run `make swag`
3. Include regenerated `openapi/swagger.json` and `openapi/docs.go` in changes
4. Frontend changes that depend on API changes **MUST** be implemented separately

---

## Go-Specific Patterns

### Receiver Patterns

✅ **DO**: Use pointer receivers for methods

```go
func (r *WorkspaceRepository) GetWorkspace(ctx context.Context, ...) error {
	return r.client.Get(ctx, key, obj)
}
```

### Package Imports

✅ **DO**: Alias conflicting package names

```go
import (
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	models "github.com/kubeflow/notebooks/workspaces/backend/internal/models/workspaces"
	repository "github.com/kubeflow/notebooks/workspaces/backend/internal/repositories/workspaces"
)
```

### Struct Initialization

✅ **DO**: Use field names in struct literals

```go
workspace := &kubefloworgv1beta1.Workspace{
	ObjectMeta: metav1.ObjectMeta{
		Name:      name,
		Namespace: namespace,
	},
	Spec: kubefloworgv1beta1.WorkspaceSpec{
		Kind: kindName,
	},
}
```
