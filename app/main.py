from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import os

app = FastAPI(title="External Secrets Demo")

SECRET_KEYS = {"DATABASE_PASSWORD", "API_KEY", "TLS_CERT", "TLS_KEY"}
CONFIG_KEYS = {"APP_NAME", "DEBUG_MODE", "MAX_CONNECTIONS", "DB_HOST"}

# Directories where secrets might be mounted
SECRETS_DIR = "/etc/secrets"
CONFIGS_DIR = "/etc/config"

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>External Secrets Demo</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; background: #f5f5f5; }}
        h1 {{ color: #333; border-bottom: 3px solid #6366f1; padding-bottom: 10px; }}
        .nav {{ margin: 20px 0; padding: 15px; background: white; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }}
        .nav a {{ margin-right: 20px; color: #6366f1; text-decoration: none; font-weight: 600; }}
        .nav a:hover {{ text-decoration: underline; }}
        .grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 20px; margin-top: 20px; }}
        .card {{ background: white; border-radius: 12px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }}
        .card.secret {{ border-left: 4px solid #ef4444; background: linear-gradient(135deg, #fef2f2 0%, #ffffff 100%); }}
        .card.config {{ border-left: 4px solid #3b82f6; background: linear-gradient(135deg, #eff6ff 0%, #ffffff 100%); }}
        .card.system {{ border-left: 4px solid #9ca3af; }}
        .card.file {{ border-left: 4px solid #10b981; background: linear-gradient(135deg, #ecfdf5 0%, #ffffff 100%); }}
        .label {{ font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600; margin-bottom: 8px; }}
        .label.secret {{ color: #ef4444; }}
        .label.config {{ color: #3b82f6; }}
        .label.system {{ color: #9ca3af; }}
        .label.file {{ color: #10b981; }}
        .key {{ font-family: monospace; font-size: 14px; color: #374151; word-break: break-all; font-weight: 600; }}
        .value {{ font-family: monospace; font-size: 13px; color: #6b7280; margin-top: 8px; padding: 8px; background: #f9fafb; border-radius: 6px; word-break: break-all; max-height: 150px; overflow-y: auto; }}
        .badge {{ display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 600; margin-bottom: 12px; }}
        .badge.secret {{ background: #fecaca; color: #991b1b; }}
        .badge.config {{ background: #bfdbfe; color: #1e40af; }}
        .badge.system {{ background: #e5e7eb; color: #374151; }}
        .badge.file {{ background: #a7f3d0; color: #065f46; }}
        .stats {{ display: flex; gap: 20px; margin: 20px 0; flex-wrap: wrap; }}
        .stat {{ background: white; padding: 15px 25px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }}
        .stat-value {{ font-size: 24px; font-weight: 700; color: #6366f1; }}
        .stat-label {{ font-size: 12px; color: #6b7280; text-transform: uppercase; }}
        .source {{ font-size: 11px; color: #9ca3af; margin-top: 10px; font-style: italic; }}
        .file-path {{ font-family: monospace; font-size: 11px; color: #6b7280; background: #f3f4f6; padding: 2px 6px; border-radius: 4px; }}
    </style>
</head>
<body>
    <h1>🔐 External Secrets Demo</h1>
    <p>Secrets from HashiCorp Vault via External Secrets Operator</p>
    
    <div class="nav">
        <a href="/">🏠 Home</a>
        <a href="/env">🌍 Environment Variables</a>
        <a href="/files">📁 Mounted Files</a>
        <a href="/combined">🔀 Combined View</a>
    </div>
    
    <div class="stats">
        <div class="stat">
            <div class="stat-value">{secret_count}</div>
            <div class="stat-label">Secrets</div>
        </div>
        <div class="stat">
            <div class="stat-value">{config_count}</div>
            <div class="stat-label">Configs</div>
        </div>
        <div class="stat">
            <div class="stat-value">{file_count}</div>
            <div class="stat-label">Files</div>
        </div>
        <div class="stat">
            <div class="stat-value">{system_count}</div>
            <div class="stat-label">System</div>
        </div>
    </div>
    
    <div class="grid">
        {cards}
    </div>
</body>
</html>
"""


def classify_key(key: str) -> str:
    """Classify a key as secret, config, or system."""
    if key in SECRET_KEYS:
        return "secret"
    elif key in CONFIG_KEYS:
        return "config"
    return "system"


def create_card(
    key: str, value: str, source: str = "env", file_path: str | None = None
) -> str:
    """Create an HTML card for a key-value pair."""
    # Map file sources to their visual category
    if source == "file":
        category = "file"
        badge_text = "FILE"
    else:
        category = classify_key(key)
        badge_text = category.upper()

    display_value = value if len(value) < 300 else value[:300] + "..."

    source_html = ""
    if source == "file" and file_path:
        source_html = f'<div class="source">📁 Mounted at: <span class="file-path">{file_path}</span></div>'
    elif source == "env":
        source_html = '<div class="source">🌍 Environment Variable</div>'

    return f"""
    <div class="card {category}">
        <span class="badge {category}">{badge_text}</span>
        <div class="label {category}">{key}</div>
        <div class="value">{display_value}</div>
        {source_html}
    </div>
    """


def read_mounted_files(directory: str) -> dict:
    """Read all files from a mounted directory."""
    files_data = {}
    if os.path.exists(directory) and os.path.isdir(directory):
        for filename in os.listdir(directory):
            filepath = os.path.join(directory, filename)
            if os.path.isfile(filepath):
                try:
                    with open(filepath, "r") as f:
                        files_data[filename] = f.read().strip()
                except Exception as e:
                    files_data[filename] = f"<Error reading file: {e}>"
    return files_data


@app.get("/", response_class=HTMLResponse)
def home():
    """Home page with navigation."""
    return HTMLResponse(
        content="""
    <!DOCTYPE html>
    <html>
    <head>
        <title>External Secrets Demo</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; background: #f5f5f5; }
            .container { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
            h1 { color: #333; border-bottom: 3px solid #6366f1; padding-bottom: 15px; }
            .links { margin-top: 30px; }
            .link { display: block; padding: 15px 20px; margin: 10px 0; background: #f9fafb; border-radius: 8px; text-decoration: none; color: #374151; transition: all 0.2s; }
            .link:hover { background: #eef2ff; transform: translateX(5px); }
            .link-title { font-weight: 600; color: #6366f1; font-size: 16px; }
            .link-desc { font-size: 14px; color: #6b7280; margin-top: 5px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🔐 External Secrets Operator Demo</h1>
            <p>Demonstrating two methods of consuming Vault secrets in Kubernetes:</p>
            
            <div class="links">
                <a href="/env" class="link">
                    <div class="link-title">🌍 Environment Variables</div>
                    <div class="link-desc">Secrets injected as environment variables using envFrom</div>
                </a>
                
                <a href="/files" class="link">
                    <div class="link-title">📁 Mounted Files</div>
                    <div class="link-desc">Secrets mounted as files in /etc/secrets and /etc/config</div>
                </a>
                
                <a href="/combined" class="link">
                    <div class="link-title">🔀 Combined View</div>
                    <div class="link-desc">See both environment variables and mounted files together</div>
                </a>
            </div>
        </div>
    </body>
    </html>
    """
    )


@app.get("/env", response_class=HTMLResponse)
def show_env():
    """Display only environment variables."""
    env_vars = dict(os.environ)

    # Sort by category, then by key
    sorted_items = sorted(env_vars.items(), key=lambda x: (classify_key(x[0]), x[0]))
    cards = "".join(create_card(k, v, source="env") for k, v in sorted_items)

    secret_count = sum(1 for k in env_vars if classify_key(k) == "secret")
    config_count = sum(1 for k in env_vars if classify_key(k) == "config")
    system_count = sum(1 for k in env_vars if classify_key(k) == "system")

    html = HTML_TEMPLATE.format(
        cards=cards,
        secret_count=secret_count,
        config_count=config_count,
        file_count=0,
        system_count=system_count,
    )

    return HTMLResponse(content=html)


@app.get("/files", response_class=HTMLResponse)
def show_files():
    """Display only mounted files."""
    # Read mounted secrets and configs
    secret_files = read_mounted_files(SECRETS_DIR)
    config_files = read_mounted_files(CONFIGS_DIR)

    all_files = []

    # Add secret files
    for filename, content in sorted(secret_files.items()):
        all_files.append((filename, content, SECRETS_DIR))

    # Add config files
    for filename, content in sorted(config_files.items()):
        all_files.append((filename, content, CONFIGS_DIR))

    # Create cards
    cards = "".join(
        create_card(
            filename, content, source="file", file_path=os.path.join(dirpath, filename)
        )
        for filename, content, dirpath in all_files
    )

    if not cards:
        cards = """
        <div class="card system" style="grid-column: 1 / -1;">
            <span class="badge system">INFO</span>
            <div class="label system">No Mounted Files Found</div>
            <div class="value">
                No files found in /etc/secrets or /etc/config.<br><br>
                Expected files from Vault:<br>
                • /etc/secrets/tls.crt (TLS certificate)<br>
                • /etc/secrets/tls.key (TLS key)<br>
                • /etc/config/database.conf (Database configuration)
            </div>
        </div>
        """

    html = HTML_TEMPLATE.format(
        cards=cards,
        secret_count=sum(
            1 for f in all_files if f[1] and classify_key(f[0]) == "secret"
        ),
        config_count=sum(
            1 for f in all_files if f[1] and classify_key(f[0]) == "config"
        ),
        file_count=len(all_files),
        system_count=0,
    )

    return HTMLResponse(content=html)


@app.get("/combined", response_class=HTMLResponse)
def show_combined():
    """Display both environment variables and mounted files."""
    items = []

    # Add environment variables
    for key, value in os.environ.items():
        items.append((key, value, "env", None))

    # Add mounted files
    for filename, content in read_mounted_files(SECRETS_DIR).items():
        items.append((filename, content, "file", os.path.join(SECRETS_DIR, filename)))

    for filename, content in read_mounted_files(CONFIGS_DIR).items():
        items.append((filename, content, "file", os.path.join(CONFIGS_DIR, filename)))

    # Sort by source, then category, then key
    def sort_key(item):
        key, value, source, path = item
        return (source, classify_key(key), key)

    items.sort(key=sort_key)

    # Create cards
    cards = "".join(
        create_card(k, v, source=src, file_path=path) for k, v, src, path in items
    )

    # Count by type
    secret_count = sum(1 for k, v, src, _ in items if classify_key(k) == "secret")
    config_count = sum(1 for k, v, src, _ in items if classify_key(k) == "config")
    file_count = sum(1 for _, _, src, _ in items if src == "file")
    system_count = sum(1 for k, v, src, _ in items if classify_key(k) == "system")

    html = HTML_TEMPLATE.format(
        cards=cards,
        secret_count=secret_count,
        config_count=config_count,
        file_count=file_count,
        system_count=system_count,
    )

    return HTMLResponse(content=html)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
