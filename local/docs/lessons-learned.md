# Lessons Learned — Local Lab (k3d + Keycloak + Istio)

Problems encountered and solutions applied during the development and execution of the local lab.
Reference document for reproducing the environment or diagnosing failures in new runs.

---

## Keycloak 26

### Bitnami removed images from Docker Hub

The `bitnami/keycloak` image was removed from Docker Hub. Any reference to it results in
`pull access denied`.

**Solution:** use the official image `quay.io/keycloak/keycloak:26.1` with `start-dev` and import
via `k3d image import` before deploying. Set `imagePullPolicy: Never`.

---

### `frontendUrl` in the realm creation body causes a 400 error

Passing `frontendUrl` as a top-level field in the creation JSON (`POST /admin/realms`) returns
`"unable to read contents from stream"` in KC 26.

**Solution:** create the realm without `frontendUrl`, then configure it via:

```bash
curl --request PUT "${kc_url}/admin/realms/${realm}" \
  --header "Content-Type: application/json" \
  --data '{"attributes":{"frontendUrl":"http://idp.wasp.local:32080"}}'
```

---

### Multiline JSON in `--data` causes a 400 error with Istio

When the pod has an Istio sidecar, `curl` requests with JSON formatted across multiple lines via
`--data` cause parse errors in Keycloak. Istio modifies the body encoding.

**Solution:** always use single-line JSON in `--data` in bash scripts.

---

### KC 26 User Profile silently drops undeclared attributes

In KC 26, the User Profile system only persists attributes that have been previously declared in
the realm schema. If `tenant_id` is not declared, it is silently ignored when creating
users — curl returns 201 but the attribute is never saved.

**Solution:** before creating users, declare the attribute via `GET /users/profile` → add
`tenant_id` → `PUT /users/profile`:

```bash
profile=$(curl --silent "${kc_url}/admin/realms/${realm}/users/profile" --header "${auth_header}")
python3 << PYEOF
import json
profile = json.loads('${profile}')
if not any(a['name'] == 'tenant_id' for a in profile.get('attributes', [])):
    profile['attributes'].append({
        "name": "tenant_id",
        "displayName": "Tenant ID",
        "permissions": {"view": ["admin"], "edit": ["admin"]},
        "validations": {}, "annotations": {},
        "required": {"roles": []}, "multivalued": False
    })
with open('/tmp/wasp_user_profile.json', 'w') as f:
    json.dump(profile, f)
PYEOF
curl --request PUT "${kc_url}/admin/realms/${realm}/users/profile" \
  --header "${auth_header}" --header "Content-Type: application/json" \
  --data @/tmp/wasp_user_profile.json
```

---

### VERIFY_PROFILE blocks login even with `defaultAction: false`

KC 26 evaluates `VERIFY_PROFILE` dynamically. Disabling it only as `defaultAction: false`
is not enough — the action still intercepts login if it detects missing fields.

**Solution:** disable it completely with `enabled: false`:

```bash
curl --request PUT \
  "${kc_url}/admin/realms/${realm}/authentication/required-actions/VERIFY_PROFILE" \
  --header "${auth_header}" --header "Content-Type: application/json" \
  --data '{"alias":"VERIFY_PROFILE","name":"Verify Profile","providerId":"VERIFY_PROFILE","enabled":false,"defaultAction":false,"priority":90,"config":{}}'
```

---

### `grant_type=password` does not return `id_token` without `scope=openid`

When testing tokens directly via curl, the `password` grant only includes `id_token` when
`scope=openid` is present:

```bash
curl ... --data "grant_type=password" --data "scope=openid"
```

---

## HAProxy Ingress

### Helm parameter for fixed NodePort

The parameter `controller.service.nodePorts.http` has no effect. The correct parameter is:

```bash
--set "controller.service.httpPorts[0].nodePort=32080"
```

If HAProxy is installed with the wrong port, fix it via patch without reinstalling:

```bash
kubectl patch svc haproxy-ingress -n ingress-controller \
  --type='json' \
  --patch='[{"op":"replace","path":"/spec/ports/0/nodePort","value":32080}]'
```

---

### HAProxy requires an `Ingress` resource to route to Istio

The HAProxy Ingress Controller does not know how to forward to the Istio IngressGateway without an
`Ingress` resource pointing to it. Without it, HAProxy returns 503 for every request.

**Solution:** create a catch-all `Ingress` in the `istio-ingress` namespace with `defaultBackend`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: istio-passthrough
  namespace: istio-ingress
  annotations:
    kubernetes.io/ingress.class: haproxy
spec:
  defaultBackend:
    service:
      name: istio-ingressgateway
      port:
        number: 80
```

This resource was added at the end of script `04-install-istio`.

---

## Discovery service

### SQLite fails without a volume mounted at `/data`

The `discovery` service tries to create the `.db` file at `/data/tenants.db`. Without a volume
mounted at that path, the pod starts but fails with `unable to open database file`.

**Solution:** add `emptyDir: {}` to the deployment spec:

```yaml
volumeMounts:
  - name: data
    mountPath: /data
volumes:
  - name: data
    emptyDir: {}
```

---

### `DISCOVERY_URL` must be in-cluster, not the external host

Inside pods, `http://discovery.wasp.local:32080` does not resolve — the host's `/etc/hosts` DNS
is not propagated to containers.

**Solution:** use the Kubernetes service name directly:

```
DISCOVERY_URL=http://discovery.discovery.svc.cluster.local:8000
```

---

### Seed domain must be the email domain, not the application subdomain

The platform looks up the tenant by the user's email domain (`customer1.com`). The seed
must contain the email domain, not the application subdomain (`customer1.wasp.local`).

**Wrong:**
```json
{ "domain": "customer1.wasp.local", ... }
```

**Correct:**
```json
{ "domain": "customer1.com", ... }
```

---

## callback-handler — session cookie

### `secure=True` prevents the cookie from being sent over HTTP

The original hardcoded `secure=True` causes the browser (and curl) to never send the
cookie over HTTP connections. The local lab has no TLS on the external path.

### `domain=".wasp.silvios.me"` does not cover `.wasp.local`

The hardcoded AWS lab domain does not match the local domain.

**Solution (TDD):** add `COOKIE_SECURE` and `COOKIE_DOMAIN` environment variables:

```python
cookie_secure = os.getenv("COOKIE_SECURE", "true").lower() != "false"
cookie_domain = os.getenv("COOKIE_DOMAIN", ".wasp.silvios.me")
```

In the local lab ConfigMap:

```yaml
COOKIE_SECURE: "false"
COOKIE_DOMAIN: ".wasp.local"
```

---

## Recommended Diagnostic Order

When reprovisioning the lab from scratch, check in this order if something fails:

1. **Health checks** — all services return 200 at `/health`
2. **Direct token** — `grant_type=password&scope=openid` returns `id_token` with `custom:tenant_id`
3. **Login flow** — `POST /login` → redirect to KC with valid `state`
4. **Callback** — `GET /callback?code=...&state=...` returns 302 with `set-cookie: session=...`
5. **Cookie** — verify `Domain=.wasp.local` and absence of `Secure` in `set-cookie` header
6. **Tenant access** — `curl --cookie "session=<jwt>" http://customer1.wasp.local:32080/` returns 200
7. **Isolation** — customer1 JWT rejected at customer2 with 403
