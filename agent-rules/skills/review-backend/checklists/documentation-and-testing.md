# Documentation & Testing Review Checklist

## Project Context

The backend uses swaggo for Swagger/OpenAPI documentation. All handler functions require complete Swagger annotations that generate the OpenAPI spec consumed by the frontend's generated API client.

Tests use Ginkgo (BDD framework) + Gomega matchers. Test files mirror handler files (`*_handler_test.go`). Tests run against a real Kubernetes API (envtest), not mocks. Preferred complex-object assertion: `BeComparableTo(expectedObject)` over field-by-field checks.

The frontend generates its API client from the backend's OpenAPI spec (`openapi/swagger.json`). Model type changes (field renames, type changes, added/removed fields) affect the generated client and may break the frontend. The `swagger.version` file in the frontend tracks which backend commit the client was generated from.

## Checklist

### Swagger Documentation

- [ ] **Swagger annotations present**: All handler functions must have complete Swagger annotations (`@Summary`, `@Description`, `@Tags`, `@ID`, `@Accept`, `@Produce`, `@Param`, `@Success`, `@Failure`, `@Router`).
- [ ] **Concise summaries**: Summaries use imperative verb forms: "List workspaces", "Get secret", "Create PVC" — not "Returns a list of workspaces" or "Provides details of a secret".
- [ ] **Correct media types**: Swagger annotations must specify correct `@Accept` and `@Produce` types.
- [ ] **Response types match**: Swagger `@Success` and `@Failure` types must match the actual envelope types used in the handler.

### Testing

- [ ] **Nil/default value tests**: At least one test case should pass nil for optional fields to verify defaults work correctly.
- [ ] **Test edge cases**: Tests should cover empty values, nil pointers, and missing references.
- [ ] **Comprehensive object comparison**: Prefer `BeComparableTo(expectedObject)` over field-by-field assertions when verifying complex response bodies. Build an expected object and compare in one assertion to catch regressions on new fields.
- [ ] **Test label-based access control**: Include test cases that verify resources without required labels (e.g., `can-mount=true`) are rejected. Test both the "resource not found" and "resource exists but lacks label" scenarios.
- [ ] **Run make lint and make test**: Verify the PR passes `make lint` and `make test` in `workspaces/backend/`.

### Frontend Considerations

- [ ] **Frontend-friendly responses**: Model types should abstract away Kubernetes internals. The frontend should not need to understand Kubernetes resource structure. For example, workspace services should present HTTP paths, not raw port numbers.
- [ ] **Stable API surface**: Changes to model types affect the generated API client. Verify that field renames or type changes are intentional and consider backwards compatibility.
