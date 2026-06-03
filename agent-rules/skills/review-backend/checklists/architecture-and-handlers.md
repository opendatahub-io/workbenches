# Architecture & Handler Patterns Review Checklist

## Project Context

The backend is a Go BFF (Backend-For-Frontend) API server under `workspaces/backend/`. It uses a three-layer architecture:

- **Handlers** (`api/*_handler.go`): HTTP request handling, path param extraction, auth checks, response writing. One file per resource or sub-resource endpoint.
- **Models** (`internal/models/<resource>/`): Type definitions (`types.go`, `types_write.go`) and CRD-to-model conversion functions (`funcs.go`, `funcs_write.go`). Each model sub-package mirrors the API URL structure.
- **Repositories** (`internal/repositories/<resource>/`): The only layer that interacts with the Kubernetes API client. Returns model types to handlers.

Handlers MUST NOT import or use raw Kubernetes types directly — only model types. Handlers call a single repository method and receive a model back; they MUST NOT chain a repository fetch with a separate model conversion call. Response helpers live in `api/response_errors.go`.

## Checklist

### Architecture & Layering

- [ ] **Handler-Model-Repository separation**: Handlers in `api/` MUST only interact with model types from `internal/models/`. Handlers MUST NOT import or use raw Kubernetes types directly. Repositories in `internal/repositories/` are the only layer that interacts with the Kubernetes API client. Critically, handlers MUST call a single repository method and receive a model back — they MUST NOT chain a repository fetch with a separate model conversion call. If the handler is calling `repo.GetX()` then passing the result to `models.BuildY()`, that conversion belongs inside the repository method.
- [ ] **Handler file per sub-resource**: When an API has sub-resource endpoints (e.g., `/workspacekinds/{name}/podtemplate/options/listvalues`), the handler MUST be in its own file (e.g., `workspacekind_podtemplate_options_handler.go`), not appended to the parent resource's handler file (`workspacekinds_handler.go`). Test files MUST match their handler file name (e.g., `workspacekind_podtemplate_options_handler_test.go`).
- [ ] **Single model package per handler**: Each handler file should import from only ONE models sub-package (e.g., `models "...internal/models/workspaces"` or `models "...internal/models/workspaces/actions"`). If a handler needs types from multiple model packages, consider whether the handler is doing too much.
- [ ] **Model package structure**: Each model sub-package should contain `types.go` (type definitions) and `funcs.go` (conversion/builder functions). Write operations use `types_write.go` and `funcs_write.go`. Actions should have their own sub-package (e.g., `models/workspaces/actions/`). `Validate()` methods are co-located with their type definitions (in `types.go` or `types_write.go`), not in `funcs.go` — this is an accepted pattern even though it adds imports to type files.
- [ ] **Model sub-package hierarchy mirrors API path**: When a new endpoint introduces a distinct set of request/response types, those types MUST live in their own model sub-package whose path mirrors the API URL structure (e.g., `internal/models/workspacekinds/podtemplate/options/` for `/workspacekinds/{name}/podtemplate/options/...`). Do not grow a parent model package's `types.go` with unrelated types — if the file is accumulating request/response types for multiple endpoints, they need to be split into sub-packages.
- [ ] **Shared constants in common package**: Shared annotations (`AnnotationDisplayName`, `AnnotationDescription`) and labels (`LabelCanMount`, `LabelCanUpdate`, `LabelCanUse`) belong in `internal/models/common/funcs.go`. Domain-specific model packages import from `common` rather than duplicating constants. Use `commonModels` or `modelsCommon` as import alias.
- [ ] **Validation location**: Validation helper functions belong in `internal/helper/`, not in `api/`. Handler-level validation (path params, body) stays in `api/`, but reusable validation logic must live in `internal/helper/validation.go`.

### Handler Structure

- [ ] **Consistent handler flow**: Handler step ordering depends on the HTTP method. **POST (Create)** handlers follow: (1) extract path params, (2) validate path params, (3) validate Content-Type, (4) decode request body, (5) validate request body, (6) auth check, (7) call repository, (8) handle errors, (9) send response — auth comes after body parsing because the resource identity (e.g., name) is extracted from the body and needed for the auth policy. **PUT (Update)** handlers follow: (1) extract path params, (2) validate path params, (3) auth check, (4) validate Content-Type, (5) decode request body, (6) validate request body, (7) call repository, (8) handle errors, (9) send response — auth comes before body parsing because the resource is identified by path params, allowing early rejection of unauthorized requests. **DELETE** handlers follow the same early-auth pattern as PUT. **GET/List (Read)** handlers: (1) extract params, (2) validate params, (3) auth check, (4) call repository, (5) handle errors, (6) send response.
- [ ] **Auth block format**: Auth checks must use the `// =========================== AUTH ===========================` comment block pattern for visibility.
- [ ] **Auth policies match operation intent**: Auth policies MUST reflect the actual operation the user is performing, not just the resource being read. When an endpoint's behavior changes based on request context (e.g., namespace-scoped user action vs cluster-scoped admin view), the auth policy MUST branch accordingly. For example, a listvalues call in the context of "creating a workspace in namespace X" should check `VerbCreate` on Workspaces, not `VerbGet` on WorkspaceKinds.
- [ ] **Body size enforcement**: Write handlers must check `a.IsMaxBytesError(err)` after `DecodeJSON` and return 413 if true.
- [ ] **Nil data check**: After decoding the request envelope, always check if `bodyEnvelope.Data == nil` and return a 422 with `field.Required(dataPath, "data is required")`.

### Response Patterns

- [ ] **Use established response helpers**: All responses must use the existing helper methods: `dataResponse()` for 200, `createdResponse()` for 201, `deletedResponse()` for 204, `badRequestResponse()` for 400, `notFoundResponse()` for 404, `conflictResponse()` for 409, `failedValidationResponse()` for 422, `serverErrorResponse()` for 500, `requestEntityTooLargeResponse()` for 413, `unsupportedMediaTypeResponse()` for 415.
- [ ] **Validation errors return 422**: Input validation failures must return HTTP 422 with field paths, not generic 400 errors. Field paths should look like `data.podTemplate.volumes.data[0].pvcName`.
- [ ] **Error wrapping**: Errors passed to `serverErrorResponse` in **write handlers** (Create, Update, Delete) should be wrapped with context using `fmt.Errorf("error creating/updating/deleting X: %w", err)`. Read-only handlers (Get, List) pass `err` directly without wrapping, matching the existing codebase convention.
