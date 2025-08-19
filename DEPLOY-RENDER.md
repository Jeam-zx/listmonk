# Deploy to Render

This repo includes a `render.yaml` blueprint that provisions:
- A managed PostgreSQL database.
- A Docker-based web service that builds listmonk (frontend + backend) and runs it.

Steps:
1. Push this repo to GitHub.
2. In Render, click New > Blueprint and select this repo.
3. Review and create resources.
4. On first deploy, the app runs `--install --idempotent` and `--upgrade` automatically. A super admin can be auto-created with env vars:
   - LISTMONK_ADMIN_USER
   - LISTMONK_ADMIN_PASSWORD

Notes:
- Render provides `PORT`; the entrypoint maps it to `LISTMONK_app__address`.
- `DATABASE_URL` from the Render DB is parsed into `LISTMONK_db__*` variables.
- To persist uploads, add a Render disk and mount at `/listmonk/uploads` and set Admin > Settings > Media to that path.
