---
name: Kubernetes Controller Agent - Patterns
description: Detailed code patterns and examples for the Kubernetes controller and webhooks.
---

# Controller Module - Detailed Patterns

This file contains detailed patterns and examples for the controller module.

**For essential guidelines, see [AGENTS.md](./AGENTS.md).**

---

## Table of Contents

- [Testing Guidelines](#testing-guidelines)
- [Custom Resource Definitions (CRDs)](#custom-resource-definitions-crds)
- [Rate Limiting Patterns](#rate-limiting-patterns)
- [Logging Patterns](#logging-patterns)
- [Controller Reconciliation Patterns](#controller-reconciliation-patterns)
- [Status Management Patterns](#status-management-patterns)
- [Webhook Patterns](#webhook-patterns)
- [Owner Reference and Finalizer Patterns](#owner-reference-and-finalizer-patterns)
- [Helper Functions](#helper-functions)
- [Field Indexers and Efficient Lookups](#field-indexers-and-efficient-lookups)
- [SetupWithManager Patterns](#setupwithmanager-patterns)
- [RBAC Markers and Permissions](#rbac-markers-and-permissions)
- [Go-Specific Patterns for Controllers](#go-specific-patterns-for-controllers)
- [Kustomize Manifests](#kustomize-manifests)
- [Common Tasks](#common-tasks)

---

## Testing Guidelines

### Test Framework

**Use Ginkgo and Gomega for BDD-style tests:**

```go
import (
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Workspace Controller", func() {
	Context("When reconciling a Workspace", Serial, Ordered, func() {
		const (
			timeout  = time.Second * 10
			interval = time.Millisecond * 250
		)

		var (
			workspaceName     string
			workspaceKindName string
			workspaceKey      types.NamespacedName
		)

		BeforeAll(func() {
			// NOTE: to avoid conflicts between parallel tests, resource names are unique to each test
			uniqueName := "ws-test"
			workspaceName = fmt.Sprintf("workspace-%s", uniqueName)
			workspaceKindName = fmt.Sprintf("workspacekind-%s", uniqueName)
			workspaceKey = types.NamespacedName{Name: workspaceName, Namespace: "default"}

			By("creating the WorkspaceKind")
			workspaceKind := NewExampleWorkspaceKind1(workspaceKindName)
			Expect(k8sClient.Create(ctx, workspaceKind)).To(Succeed())

			By("creating the Workspace")
			workspace := NewExampleWorkspace1(workspaceName, "default", workspaceKindName)
			Expect(k8sClient.Create(ctx, workspace)).To(Succeed())
		})

		AfterAll(func() {
			By("deleting the Workspace")
			workspace := &kubefloworgv1beta1.Workspace{
				ObjectMeta: metav1.ObjectMeta{
					Name:      workspaceName,
					Namespace: "default",
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
		})

		It("should reconcile successfully", func() {
			Eventually(func() error {
				workspace := &kubefloworgv1beta1.Workspace{}
				return k8sClient.Get(ctx, workspaceKey, workspace)
			}, timeout, interval).Should(Succeed())
		})
	})
})
```

### Testing Patterns

✅ **DO**: Use Eventually for async operations

```go
Eventually(func() (WorkspaceState, error) {
	workspace := &kubefloworgv1beta1.Workspace{}
	err := k8sClient.Get(ctx, workspaceKey, workspace)
	if err != nil {
		return "", err
	}
	return workspace.Status.State, nil
}, timeout, interval).Should(Equal(kubefloworgv1beta1.WorkspaceStateRunning))
```

✅ **DO**: Use Consistently for stable conditions

```go
Consistently(func() bool {
	workspace := &kubefloworgv1beta1.Workspace{}
	k8sClient.Get(ctx, workspaceKey, workspace)
	return workspace.Status.State == kubefloworgv1beta1.WorkspaceStateRunning
}, duration, interval).Should(BeTrue())
```

✅ **DO**: Test immutable fields

```go
It("should not allow updating immutable fields", func() {
	workspace := &kubefloworgv1beta1.Workspace{}
	Expect(k8sClient.Get(ctx, workspaceKey, workspace)).To(Succeed())
	patch := client.MergeFrom(workspace.DeepCopy())

	newWorkspace := workspace.DeepCopy()
	newWorkspace.Spec.Kind = "new-kind"
	Expect(k8sClient.Patch(ctx, newWorkspace, patch)).NotTo(Succeed())
})
```

---

## Custom Resource Definitions (CRDs)

### CRD Type Structure

```go
// WorkspaceSpec defines the desired state
type WorkspaceSpec struct {
	// +kubebuilder:validation:Optional
	// +kubebuilder:default=false
	Paused *bool `json:"paused,omitempty"`

	// +kubebuilder:validation:MinLength:=2
	// +kubebuilder:validation:MaxLength:=63
	// +kubebuilder:validation:Pattern:=^[a-z0-9][-a-z0-9]*[a-z0-9]$
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="Workspace 'kind' is immutable"
	// +kubebuilder:example="jupyterlab"
	Kind string `json:"kind"`

	PodTemplate WorkspacePodTemplate `json:"podTemplate"`
}

// WorkspaceStatus defines the observed state
type WorkspaceStatus struct {
	Activity       WorkspaceActivity `json:"activity"`
	PauseTime      int64            `json:"pauseTime"`
	PendingRestart bool             `json:"pendingRestart"`
	State          WorkspaceState   `json:"state"`
	StateMessage   string           `json:"stateMessage"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:resource:scope=Namespaced,categories={kubeflow,workspaces}
// +kubebuilder:printcolumn:name="Kind",type=string,JSONPath=`.spec.kind`
// +kubebuilder:printcolumn:name="State",type=string,JSONPath=`.status.state`
// +kubebuilder:printcolumn:name="Age",type=date,JSONPath=`.metadata.creationTimestamp`
type Workspace struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   WorkspaceSpec   `json:"spec,omitempty"`
	Status WorkspaceStatus `json:"status,omitempty"`
}
```

### Kubebuilder Validation Markers

```go
// String validation
// +kubebuilder:validation:MinLength:=1
// +kubebuilder:validation:MaxLength:=253
// +kubebuilder:validation:Pattern:=^[a-z0-9]([-a-z0-9]*[a-z0-9])?$
Name string `json:"name"`

// Number validation
// +kubebuilder:validation:Minimum:=0
// +kubebuilder:validation:Maximum:=511
// +kubebuilder:validation:MultipleOf:=1
DefaultMode int32 `json:"defaultMode,omitempty"`

// Enum validation
// +kubebuilder:validation:Enum:={"Running","Pending","Error","Unknown"}
State WorkspaceState `json:"state"`

// Required/Optional
// +kubebuilder:validation:Required
RequiredField string `json:"requiredField"`

// +kubebuilder:validation:Optional
// +kubebuilder:default=false
OptionalField *bool `json:"optionalField,omitempty"`

// Immutability (CEL validation)
// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="Field is immutable"
ImmutableField string `json:"immutableField"`

// Array validation
// +kubebuilder:validation:MinItems=1
// +kubebuilder:validation:MaxItems=10
// +listType=map
// +listMapKey=mountPath
Volumes []VolumeMount `json:"volumes"`
```

### Modifying CRD Types

**CRITICAL**: CRD changes affect all users. Human approval required.

1. Modify types in `api/v1beta1/*_types.go`
2. Run `make generate` - Regenerates DeepCopy methods
3. Run `make manifests` - Regenerates CRD YAML
4. Test with samples in `manifests/kustomize/samples/`
5. Check generated files: `api/v1beta1/zz_generated.deepcopy.go`, `manifests/kustomize/base/crd/*.yaml`

---

## Rate Limiting Patterns

### Custom Rate Limiter

```go
func BuildRateLimiter() workqueue.TypedRateLimiter[reconcile.Request] {
	failureBaseDelay := 1 * time.Second
	failureMaxDelay := 7 * time.Minute
	failureRateLimiter := workqueue.NewTypedItemExponentialFailureRateLimiter[reconcile.Request](
		failureBaseDelay,
		failureMaxDelay,
	)

	totalEventsPerSecond := 10
	totalMaxBurst := 100
	totalRateLimiter := &workqueue.TypedBucketRateLimiter[reconcile.Request]{
		Limiter: rate.NewLimiter(rate.Limit(totalEventsPerSecond), totalMaxBurst),
	}

	return workqueue.NewTypedMaxOfRateLimiter[reconcile.Request](
		failureRateLimiter,
		totalRateLimiter,
	)
}
```

---

## Logging Patterns

### Structured Logging

```go
func (r *WorkspaceReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := log.FromContext(ctx)

	// V(2) - debug/verbose
	log.V(2).Info("reconciling Workspace")
	log.V(2).Info("update conflict, will requeue")

	// V(1) - info
	log.V(1).Info("creating StatefulSet")

	// V(0) - important info/warnings
	log.V(0).Info("Workspace references unknown WorkspaceKind")

	// Error - actual errors
	log.Error(err, "unable to fetch Workspace")
}
```

✅ **DO**: Use structured fields

```go
log.V(2).Info("reconciling Workspace",
	"namespace", workspace.Namespace,
	"name", workspace.Name,
	"kind", workspace.Spec.Kind,
)
```

✅ **DO**: Add context with WithValues

```go
log = log.WithValues("workspaceKind", workspaceKindName)
log.V(2).Info("fetched WorkspaceKind")
```

---

## Controller Reconciliation Patterns

### Reconciler Pattern Template

```go
func (r *Reconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    log := log.FromContext(ctx)

    // 1. Fetch the resource
    var obj v1beta1.MyResource
    if err := r.Get(ctx, req.NamespacedName, &obj); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }

    // 2. Handle deletion (finalizers)
    // 3. Ensure child resources (idempotent)
    // 4. Update status

    return ctrl.Result{}, nil
}
```

### Reconciliation Structure

```go
func (r *WorkspaceReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := log.FromContext(ctx)
	log.V(2).Info("reconciling Workspace")

	// 1. Fetch the primary resource
	workspace := &kubefloworgv1beta1.Workspace{}
	if err := r.Get(ctx, req.NamespacedName, workspace); err != nil {
		if client.IgnoreNotFound(err) == nil {
			return ctrl.Result{}, nil
		}
		log.Error(err, "unable to fetch Workspace")
		return ctrl.Result{}, err
	}

	// 2. Handle deletion timestamp
	if !workspace.GetDeletionTimestamp().IsZero() {
		log.V(2).Info("Workspace is being deleted")
		return ctrl.Result{}, nil
	}

	// 3. Copy current status for comparison
	currentStatus := *workspace.Status.DeepCopy()

	// 4. Fetch related resources
	workspaceKind := &kubefloworgv1beta1.WorkspaceKind{}
	if err := r.Get(ctx, client.ObjectKey{Name: workspace.Spec.Kind}, workspaceKind); err != nil {
		if apierrors.IsNotFound(err) {
			return r.updateWorkspaceState(ctx, log, workspace,
				kubefloworgv1beta1.WorkspaceStateError,
				fmt.Sprintf("Workspace references unknown WorkspaceKind: %s", workspace.Spec.Kind),
			)
		}
		return ctrl.Result{}, err
	}

	// 5-6. Reconcile owned resources...

	// 7. Update status only if changed
	if !equality.Semantic.DeepEqual(currentStatus, workspace.Status) {
		if err := r.Status().Update(ctx, workspace); err != nil {
			if apierrors.IsConflict(err) {
				log.V(2).Info("update conflict on status, will requeue")
				return ctrl.Result{Requeue: true}, nil
			}
			log.Error(err, "unable to update Workspace status")
			return ctrl.Result{}, err
		}
	}

	return ctrl.Result{}, nil
}
```

### Reconciliation Best Practices

✅ **DO**: Make reconciliation idempotent

```go
func (r *Reconciler) reconcileStatefulSet(ctx context.Context, workspace *Workspace) error {
	existing := &appsv1.StatefulSet{}
	err := r.Get(ctx, types.NamespacedName{Name: name, Namespace: namespace}, existing)

	if apierrors.IsNotFound(err) {
		return r.Create(ctx, desired)
	} else if err != nil {
		return err
	}

	if !equality.Semantic.DeepEqual(existing.Spec, desired.Spec) {
		return r.Update(ctx, desired)
	}

	return nil
}
```

✅ **DO**: Handle conflicts with requeue

```go
if err := r.Update(ctx, resource); err != nil {
	if apierrors.IsConflict(err) {
		log.V(2).Info("update conflict, will requeue")
		return ctrl.Result{Requeue: true}, nil
	}
	return ctrl.Result{}, err
}
```

### Return Values

```go
// Success - no further action needed
return ctrl.Result{}, nil

// Requeue immediately
return ctrl.Result{Requeue: true}, nil

// Requeue after delay
return ctrl.Result{RequeueAfter: 30 * time.Second}, nil

// Error - will be retried with exponential backoff
return ctrl.Result{}, err
```

---

## Status Management Patterns

### Status Updates

```go
// Good - separate status update
workspace.Status.State = kubefloworgv1beta1.WorkspaceStateRunning
workspace.Status.StateMessage = "Workspace is running"

if err := r.Status().Update(ctx, workspace); err != nil {
	return ctrl.Result{}, err
}
```

### Status Helper Methods

```go
func (r *WorkspaceReconciler) updateWorkspaceState(
	ctx context.Context,
	log logr.Logger,
	workspace *kubefloworgv1beta1.Workspace,
	state kubefloworgv1beta1.WorkspaceState,
	message string,
) (ctrl.Result, error) {
	workspace.Status.State = state
	workspace.Status.StateMessage = message

	if err := r.Status().Update(ctx, workspace); err != nil {
		if apierrors.IsConflict(err) {
			log.V(2).Info("update conflict on status, will requeue")
			return ctrl.Result{Requeue: true}, nil
		}
		log.Error(err, "unable to update Workspace status")
		return ctrl.Result{}, err
	}

	return ctrl.Result{}, nil
}
```

### State Constants

```go
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

## Webhook Patterns

**CRITICAL**: Webhook failures can break cluster operations. Extra care required.

### Validation Webhook Structure

```go
type WorkspaceValidator struct {
	client.Client
	Scheme *runtime.Scheme
}

func (v *WorkspaceValidator) ValidateCreate(ctx context.Context, obj runtime.Object) (admission.Warnings, error) {
	log := log.FromContext(ctx)
	log.V(1).Info("validating Workspace create")

	workspace, ok := obj.(*kubefloworgv1beta1.Workspace)
	if !ok {
		return nil, apierrors.NewBadRequest(fmt.Sprintf("expected a Workspace object but got %T", obj))
	}

	var allErrs field.ErrorList

	workspaceKind, err := v.validateWorkspaceKind(ctx, workspace)
	if err != nil {
		allErrs = append(allErrs, err)
		return nil, apierrors.NewInvalid(
			schema.GroupKind{Group: kubefloworgv1beta1.GroupVersion.Group, Kind: "Workspace"},
			workspace.Name,
			allErrs,
		)
	}

	allErrs = append(allErrs, v.validatePodTemplatePodMetadata(workspace)...)
	allErrs = append(allErrs, v.validateImageConfig(workspace, workspaceKind)...)
	allErrs = append(allErrs, v.validatePodConfig(workspace, workspaceKind)...)

	if len(allErrs) == 0 {
		return nil, nil
	}

	return nil, apierrors.NewInvalid(
		schema.GroupKind{Group: kubefloworgv1beta1.GroupVersion.Group, Kind: "Workspace"},
		workspace.Name,
		allErrs,
	)
}

func (v *WorkspaceValidator) ValidateUpdate(ctx context.Context, oldObj, newObj runtime.Object) (admission.Warnings, error) {
	log := log.FromContext(ctx)
	log.V(1).Info("validating Workspace update")

	newWorkspace, ok := newObj.(*kubefloworgv1beta1.Workspace)
	if !ok {
		return nil, apierrors.NewBadRequest(fmt.Sprintf("expected a Workspace object but got %T", newObj))
	}
	oldWorkspace, ok := oldObj.(*kubefloworgv1beta1.Workspace)
	if !ok {
		return nil, apierrors.NewBadRequest(fmt.Sprintf("expected old object to be a Workspace but got %T", oldObj))
	}

	var allErrs field.ErrorList

	// Validate immutable fields
	kindPath := field.NewPath("spec").Child("kind")
	if newWorkspace.Spec.Kind != oldWorkspace.Spec.Kind {
		allErrs = append(allErrs, field.Forbidden(kindPath, "field is immutable after creation"))
	}

	// Revalidate changed fields
	if !equality.Semantic.DeepEqual(newWorkspace.Spec.PodTemplate.PodMetadata, oldWorkspace.Spec.PodTemplate.PodMetadata) {
		if errs := v.validatePodMetadata(newWorkspace.Spec.PodTemplate.PodMetadata, field.NewPath("spec", "podTemplate", "podMetadata")); errs != nil {
			allErrs = append(allErrs, errs...)
		}
	}

	if len(allErrs) == 0 {
		return nil, nil
	}

	return nil, apierrors.NewInvalid(
		schema.GroupKind{Group: kubefloworgv1beta1.GroupVersion.Group, Kind: "Workspace"},
		newWorkspace.Name,
		allErrs,
	)
}
```

### Webhook Best Practices

✅ **DO**: Use field.ErrorList for validation errors

```go
var allErrs field.ErrorList
allErrs = append(allErrs, v.validateField1(resource)...)
allErrs = append(allErrs, v.validateField2(resource)...)
return allErrs
```

✅ **DO**: Use field.Path for nested fields

```go
metadataPath := field.NewPath("spec").Child("podTemplate").Child("podMetadata")
labelsPath := metadataPath.Child("labels")
```

✅ **DO**: Return apierrors.NewInvalid

```go
return nil, apierrors.NewInvalid(
	schema.GroupKind{Group: "kubeflow.org", Kind: "Workspace"},
	workspace.Name,
	allErrs,
)
```

---

## Owner Reference and Finalizer Patterns

### Owner References

```go
desiredStatefulSet := &appsv1.StatefulSet{
	ObjectMeta: metav1.ObjectMeta{
		Name:      generateName(workspace),
		Namespace: workspace.Namespace,
	},
	Spec: statefulSetSpec,
}

if err := controllerutil.SetControllerReference(workspace, desiredStatefulSet, r.Scheme); err != nil {
	return fmt.Errorf("failed to set owner reference: %w", err)
}

if err := r.Create(ctx, desiredStatefulSet); err != nil {
	return err
}
```

### Finalizers

```go
const WorkspaceKindFinalizer = "kubeflow.org/workspacekind-finalizer"

// Add finalizer
if resource.GetDeletionTimestamp().IsZero() {
	if !controllerutil.ContainsFinalizer(resource, WorkspaceKindFinalizer) {
		controllerutil.AddFinalizer(resource, WorkspaceKindFinalizer)
		if err := r.Update(ctx, resource); err != nil {
			if apierrors.IsConflict(err) {
				return ctrl.Result{Requeue: true}, nil
			}
			return ctrl.Result{}, err
		}
	}
}

// Remove finalizer when cleanup is done
if !resource.GetDeletionTimestamp().IsZero() {
	if controllerutil.ContainsFinalizer(resource, WorkspaceKindFinalizer) {
		if err := r.cleanup(ctx, resource); err != nil {
			return ctrl.Result{}, err
		}

		controllerutil.RemoveFinalizer(resource, WorkspaceKindFinalizer)
		if err := r.Update(ctx, resource); err != nil {
			return ctrl.Result{}, err
		}
	}
	return ctrl.Result{}, nil
}
```

---

## Helper Functions

### Resource Copy Helpers

```go
// CopyStatefulSetFields updates a StatefulSet with desired fields
// Returns true if the resource was modified
func CopyStatefulSetFields(from, to *appsv1.StatefulSet) bool {
	requireUpdate := false

	if !equality.Semantic.DeepEqual(to.Spec.Replicas, from.Spec.Replicas) {
		to.Spec.Replicas = from.Spec.Replicas
		requireUpdate = true
	}

	return requireUpdate
}
```

**Usage:**

```go
existingStatefulSet := &appsv1.StatefulSet{}
if err := r.Get(ctx, key, existingStatefulSet); err == nil {
	if helper.CopyStatefulSetFields(desiredStatefulSet, existingStatefulSet) {
		if err := r.Update(ctx, existingStatefulSet); err != nil {
			return ctrl.Result{}, err
		}
	}
}
```

---

## Field Indexers and Efficient Lookups

### Field Indexer Pattern

```go
const (
	IndexWorkspaceKindField = ".spec.kind"  // Leading dot required for field indexers
)

func SetupManagerFieldIndexers(mgr ctrl.Manager, cfg *config.EnvConfig) error {
	if err := mgr.GetFieldIndexer().IndexField(
		context.Background(),
		&kubefloworgv1beta1.Workspace{},
		IndexWorkspaceKindField,
		func(obj client.Object) []string {
			workspace := obj.(*kubefloworgv1beta1.Workspace)
			return []string{workspace.Spec.Kind}
		},
	); err != nil {
		return err
	}

	return nil
}
```

**Use in controllers:**

```go
workspaceList := &kubefloworgv1beta1.WorkspaceList{}
if err := r.List(ctx, workspaceList,
	client.MatchingFields{IndexWorkspaceKindField: workspaceKindName},
); err != nil {
	return err
}
```

---

## SetupWithManager Patterns

### Controller Setup

```go
func (r *WorkspaceReconciler) SetupWithManager(mgr ctrl.Manager, opts controller.Options) error {
	// NOTE: SetupManagerFieldIndexers() in helper/index.go should be called
	//       on mgr before this function is called

	return ctrl.NewControllerManagedBy(mgr).
		WithOptions(opts).
		For(&kubefloworgv1beta1.Workspace{}).
		Owns(&appsv1.StatefulSet{}).
		Owns(&corev1.Service{}).
		Watches(
			&kubefloworgv1beta1.WorkspaceKind{},
			handler.EnqueueRequestsFromMapFunc(r.findWorkspacesForWorkspaceKind),
			builder.WithPredicates(predicate.ResourceVersionChangedPredicate{}),
		).
		Complete(r)
}
```

### Watch Functions

```go
// mapWorkspaceKindToRequest converts WorkspaceKind events to reconcile requests for Workspaces
func (r *WorkspaceReconciler) mapWorkspaceKindToRequest(ctx context.Context, workspaceKind client.Object) []reconcile.Request {
	attachedWorkspaces := &kubefloworgv1beta1.WorkspaceList{}
	listOps := &client.ListOptions{
		FieldSelector: fields.OneTermEqualSelector(helper.IndexWorkspaceKindField, workspaceKind.GetName()),
		Namespace:     "", // fetch Workspaces in all namespaces
	}
	err := r.List(ctx, attachedWorkspaces, listOps)
	if err != nil {
		return []reconcile.Request{}
	}

	requests := make([]reconcile.Request, len(attachedWorkspaces.Items))
	for i, item := range attachedWorkspaces.Items {
		requests[i] = reconcile.Request{
			NamespacedName: types.NamespacedName{
				Name:      item.GetName(),
				Namespace: item.GetNamespace(),
			},
		}
	}
	return requests
}
```

### Predicates

```go
import "sigs.k8s.io/controller-runtime/pkg/predicate"

// Only trigger on resource version changes
builder.WithPredicates(predicate.ResourceVersionChangedPredicate{})

// Only trigger on generation changes (spec changes)
builder.WithPredicates(predicate.GenerationChangedPredicate{})

// Custom predicate using NewPredicateFuncs
predPodHasWSLabel := predicate.NewPredicateFuncs(func(object client.Object) bool {
	_, labelExists := object.GetLabels()[workspaceNameLabel]
	return labelExists
})

// Multiple predicates can be combined
builder.WithPredicates(predicate.ResourceVersionChangedPredicate{}, predPodHasWSLabel)
```

---

## RBAC Markers and Permissions

### RBAC Marker Pattern

```go
// +kubebuilder:rbac:groups=kubeflow.org,resources=workspaces,verbs=create;delete;get;list;patch;update;watch
// +kubebuilder:rbac:groups=kubeflow.org,resources=workspaces/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=kubeflow.org,resources=workspaces/finalizers,verbs=update
// +kubebuilder:rbac:groups=kubeflow.org,resources=workspacekinds,verbs=get;list;watch
// +kubebuilder:rbac:groups=apps,resources=statefulsets,verbs=create;delete;get;list;patch;update;watch
// +kubebuilder:rbac:groups=core,resources=services,verbs=create;delete;get;list;patch;update;watch

func (r *WorkspaceReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	// ...
}
```

---

## Go-Specific Patterns for Controllers

### Context Handling

✅ **DO**: Propagate context through all operations

```go
func (r *Reconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	if err := r.Get(ctx, key, obj); err != nil {
		return ctrl.Result{}, err
	}
	return r.reconcileStatefulSet(ctx, workspace)
}
```

### Pointer Safety

✅ **DO**: Use k8s.io/utils/ptr helpers

```go
import "k8s.io/utils/ptr"

workspace.Spec.Paused = ptr.To(true)
paused := ptr.Deref(workspace.Spec.Paused, false)
```

### DeepCopy Usage

✅ **DO**: Use DeepCopy before modifying

```go
original := &Workspace{}
r.Get(ctx, key, original)
modified := original.DeepCopy()
modified.Spec.Paused = ptr.To(true)
```

✅ **DO**: Dereference DeepCopy for value types

```go
currentStatus := *workspace.Status.DeepCopy()

if !equality.Semantic.DeepEqual(currentStatus, workspace.Status) {
	// Status changed
}
```

### Equality Checks

✅ **DO**: Use equality.Semantic.DeepEqual

```go
import "k8s.io/apimachinery/pkg/api/equality"

if !equality.Semantic.DeepEqual(existing.Spec, desired.Spec) {
	// Update needed
}
```

---

## Kustomize Manifests

### Manifest Structure

```
manifests/kustomize/
├── base/
│   ├── crd/                    # CRD definitions
│   ├── manager/                # Controller deployment, RBAC
│   └── webhook/                # Webhook configuration
├── components/
│   ├── certmanager/            # Certificate management
│   ├── istio/                  # Istio integration
│   └── prometheus/             # Monitoring
├── overlays/
│   └── istio/                  # Environment-specific config
└── samples/                    # Example resources
```

- Base manifests in `manifests/kustomize/base/` **SHOULD** work for all environments
- Environment-specific changes go in `overlays/`
- Component-specific additions go in `components/`
- Never break base manifests with overlay-specific assumptions
- Test manifest generation: `kustomize build manifests/kustomize/overlays/istio`

---

## Common Tasks

### Adding a New CRD Field

1. **Modify types** in `api/v1beta1/*_types.go`:

   ```go
   type WorkspaceSpec struct {
       // +kubebuilder:validation:Optional
       // +kubebuilder:default="default-value"
       NewField string `json:"newField,omitempty"`
   }
   ```

2. **Run generators**:

   ```bash
   make generate   # Regenerate DeepCopy methods
   make manifests  # Regenerate CRD YAML
   ```

3. **Update controller** if field affects reconciliation logic

4. **Update webhook** if field needs validation

5. **Add tests** for the new field behavior

6. **Update samples** in `manifests/kustomize/samples/`

### Adding a New Controller

1. **Create controller file** in `internal/controller/`:

   ```go
   // MyResourceReconciler reconciles a MyResource object
   type MyResourceReconciler struct {
       client.Client
       Scheme *runtime.Scheme
       Config *config.EnvConfig
   }

   // +kubebuilder:rbac:groups=kubeflow.org,resources=myresources,verbs=create;delete;get;list;patch;update;watch
   // +kubebuilder:rbac:groups=kubeflow.org,resources=myresources/status,verbs=get;update;patch
   // +kubebuilder:rbac:groups=kubeflow.org,resources=myresources/finalizers,verbs=update

   func (r *MyResourceReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
       log := log.FromContext(ctx)
       log.V(2).Info("reconciling MyResource")

       // 1. Fetch the resource
       myResource := &kubefloworgv1beta1.MyResource{}
       if err := r.Get(ctx, req.NamespacedName, myResource); err != nil {
           if client.IgnoreNotFound(err) == nil {
               // Request object not found, could have been deleted after reconcile request.
               // Owned objects are automatically garbage collected.
               return ctrl.Result{}, nil
           }
           log.Error(err, "unable to fetch MyResource")
           return ctrl.Result{}, err
       }

       // 2. Handle deletion
       if !myResource.GetDeletionTimestamp().IsZero() {
           log.V(2).Info("MyResource is being deleted")
           return ctrl.Result{}, nil
       }

       // 3. Reconcile owned resources
       // 4. Update status

       return ctrl.Result{}, nil
   }
   ```

2. **Add RBAC markers** above Reconcile function (as shown above)

3. **Register in main.go**:

   ```go
   if err = (&controllerInternal.MyResourceReconciler{
       Client: mgr.GetClient(),
       Scheme: mgr.GetScheme(),
       Config: cfg,
   }).SetupWithManager(mgr, controller.Options{
       RateLimiter: helper.BuildRateLimiter(),
   }); err != nil {
       setupLog.Error(err, "unable to create controller", "controller", "MyResource")
       os.Exit(1)
   }
   ```

4. **Run `make manifests`** to generate RBAC

5. **Add tests** in `*_controller_test.go`

### Adding a Validation Webhook

1. **Create webhook file** in `internal/webhook/`:

   ```go
   // MyResourceValidator validates a MyResource object
   type MyResourceValidator struct {
       client.Client
       Scheme *runtime.Scheme
   }

   // +kubebuilder:webhook:path=/validate-kubeflow-org-v1beta1-myresource,mutating=false,failurePolicy=fail,sideEffects=None,groups=kubeflow.org,resources=myresources,verbs=create;update,versions=v1beta1,name=vmyresource.kb.io,admissionReviewVersions=v1

   // SetupWebhookWithManager sets up the webhook with the manager
   func (v *MyResourceValidator) SetupWebhookWithManager(mgr ctrl.Manager) error {
       return ctrl.NewWebhookManagedBy(mgr).
           For(&kubefloworgv1beta1.MyResource{}).
           WithValidator(v).
           Complete()
   }

   // ValidateCreate validates the MyResource on creation.
   func (v *MyResourceValidator) ValidateCreate(ctx context.Context, obj runtime.Object) (admission.Warnings, error) {
       log := log.FromContext(ctx)
       log.V(1).Info("validating MyResource create")

       resource, ok := obj.(*kubefloworgv1beta1.MyResource)
       if !ok {
           return nil, apierrors.NewBadRequest(fmt.Sprintf("expected a MyResource object but got %T", obj))
       }

       var allErrs field.ErrorList
       // Add validation logic
       allErrs = append(allErrs, v.validateField(resource)...)

       if len(allErrs) == 0 {
           return nil, nil
       }

       return nil, apierrors.NewInvalid(
           schema.GroupKind{Group: kubefloworgv1beta1.GroupVersion.Group, Kind: "MyResource"},
           resource.Name,
           allErrs,
       )
   }
   ```

2. **Register webhook** in `cmd/main.go`:

   ```go
   if os.Getenv("ENABLE_WEBHOOKS") != "false" {
       if err = (&webhookInternal.MyResourceValidator{
           Client: mgr.GetClient(),
           Scheme: mgr.GetScheme(),
       }).SetupWebhookWithManager(mgr); err != nil {
           setupLog.Error(err, "unable to create webhook", "webhook", "MyResource")
           os.Exit(1)
       }
   }
   ```

3. **Add webhook configuration** in `manifests/kustomize/base/webhook/`

4. **Add tests** for validation scenarios

### Adding a Field Indexer

1. **Define index constant** in `internal/helper/index.go`:

   ```go
   const (
       IndexMyResourceOwnerField = ".metadata.controller"
       IndexMyResourceKindField  = ".spec.kind"
       OwnerKindMyResource       = "MyResource"
   )
   ```

2. **Register indexer** in `SetupManagerFieldIndexers` (in `internal/helper/index.go`):

   ```go
   // Index MyResource by its owner
   if err := mgr.GetFieldIndexer().IndexField(
       context.Background(),
       &kubefloworgv1beta1.MyResource{},
       IndexMyResourceOwnerField,
       func(rawObj client.Object) []string {
           resource := rawObj.(*kubefloworgv1beta1.MyResource)
           owner := metav1.GetControllerOf(resource)
           if owner == nil {
               return nil
           }
           // Verify the owner is the expected type
           if owner.APIVersion != kubefloworgv1beta1.GroupVersion.String() || owner.Kind != OwnerKindMyResource {
               return nil
           }
           return []string{owner.Name}
       },
   ); err != nil {
       return err
   }
   ```

3. **Use in controller** for efficient lookups:

   ```go
   list := &kubefloworgv1beta1.MyResourceList{}
   if err := r.List(ctx, list,
       client.InNamespace(namespace),
       client.MatchingFields{helper.IndexMyResourceOwnerField: ownerName},
   ); err != nil {
       return err
   }
   ```

### Adding Owner References

1. **Set controller reference** when creating owned resources:

   ```go
   desiredResource := &corev1.ConfigMap{
       ObjectMeta: metav1.ObjectMeta{
           Name:      generateName(owner),
           Namespace: owner.Namespace,
       },
       Data: configData,
   }

   if err := controllerutil.SetControllerReference(owner, desiredResource, r.Scheme); err != nil {
       return fmt.Errorf("failed to set owner reference: %w", err)
   }

   if err := r.Create(ctx, desiredResource); err != nil {
       return err
   }
   ```

2. **Add `Owns()` to SetupWithManager** for automatic reconciliation:

   ```go
   func (r *MyReconciler) SetupWithManager(mgr ctrl.Manager) error {
       return ctrl.NewControllerManagedBy(mgr).
           For(&kubefloworgv1beta1.MyResource{}).
           Owns(&corev1.ConfigMap{}).
           Complete(r)
   }
   ```
