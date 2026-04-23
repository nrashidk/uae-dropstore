# UAE Dropshipping Store

Self-hosted WooCommerce dropshipping store for UAE/GCC market.
Built entirely in GitHub Codespaces — no local installs required.

---

## Quick start (first time)

### Step 1 — Create the GitHub repository

1. Go to github.com → click **New repository**
2. Name it: `uae-dropstore` (or your preferred name)
3. Set to **Private**
4. Do NOT initialize with README (you'll push these files)
5. Click **Create repository**

### Step 2 — Upload these files to the repo

Copy the 4 files from this package into your repo root:
```
CLAUDE.md
.env.example
.gitignore
README.md
```

Create the folder `.devcontainer/` and put inside it:
```
.devcontainer/devcontainer.json
.devcontainer/setup.sh
```

Commit and push to `main`.

### Step 3 — Open in GitHub Codespaces

1. On your repo page, click the green **Code** button
2. Select the **Codespaces** tab
3. Click **Create codespace on main**
4. Wait ~3–5 minutes — setup.sh installs everything automatically
5. When done, you'll see:
   ```
   Store URL  : http://localhost:8080
   Admin URL  : http://localhost:8080/wp-admin
   Username   : admin
   Password   : admin123
   ```
6. The browser tab with WordPress will open automatically (port forwarding)

### Step 4 — Add your API key

In the Codespaces terminal:
```bash
nano .env
# Add your ANTHROPIC_API_KEY= value
# Ctrl+X to save
```

### Step 5 — Start Claude Code

```bash
claude
```

Paste the contents of `CLAUDE.md` as the system prompt when Claude Code asks.

---

## Saving hours — important habits

| Habit | Why |
|---|---|
| Stop codespace when done | Free tier = 60 hrs/month. Every minute counts. |
| Commit code often | Codespace data is not permanent — only git is. |
| Keep only 1 active codespace | Multiple codespaces eat hours simultaneously. |
| Set idle timeout to 15 min | Settings → Codespaces → Default idle timeout |
| Delete old codespaces | Storage counts even when stopped. |

**Stop codespace:** Top menu → Codespaces → Stop codespace
**Resume:** github.com/codespaces → click your stopped codespace

---

## Deployment to production (when domain is ready)

1. Update `SITE_URL` in production `.env` on the DigitalOcean droplet
2. `git push origin main` from Codespaces
3. On DigitalOcean browser console: `bash ~/deploy.sh`

---

## Tech stack

| Layer | Tool | Cost |
|---|---|---|
| Dev environment | GitHub Codespaces | Free (60 hrs/mo) |
| Platform | WordPress + WooCommerce | Free |
| Theme | Astra (free tier) | Free |
| Hosting (production) | Existing DigitalOcean droplet | $0 extra |
| Suppliers | DSers + Arabia Dropship + CJ | Free |
| Payment | PayTabs | 2.75% per sale only |
| AI (product copy) | Claude API | Pay per use |
| Notifications | Telegram Bot | Free |
| **Total fixed monthly** | | **~$0** |
