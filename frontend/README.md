# Frontend

Next.js storefront for HomeOffice Hub, with product browsing and a shopping
cart interface.

## Current runtime

The Dockerfile uses a multi-stage build:

- Build the application with `npm run build`.
- Install runtime dependencies in the runtime image.
- Run `next start` as a non-root user.

The deployed image does not run `next dev`.

See `Dockerfile` and `package.json` for the authoritative configuration.

## API routing

Browser requests use `/api/*`. The Next.js rewrite forwards those requests
to the internal backend service at `http://backend:5000/api/*`.

The name `backend` must resolve from the frontend runtime environment.
Running the frontend directly on a workstation requires corresponding
backend connectivity; the container-network configuration is not a
standalone-host setup.

## Source layout

- `src/app/`: pages, layout, and global styles
- `src/components/`: shared interface components
- `src/context/`: cart state
- `public/`: static assets
- `next.config.mjs`: application and rewrite configuration

## Deployment

Use the [Helm chart](../charts/homeoffice-commerce/).
Azure image addresses are supplied through `values-azure.yaml`.

The current public demo uses HTTP. HTTPS, frontend health probes, and
continued dependency/base-image maintenance remain on the roadmap.