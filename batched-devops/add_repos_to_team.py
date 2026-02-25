import requests
import os

GH_TOKEN = os.getenv('GH_TOKEN', '')
GH_ORG_NAME = os.getenv('GH_ORG_NAME', 'LabelTraxx')
TEAM_SLUG = os.getenv('GH_TEAM_SLUG', 'batchedpowerbirepoaccess')  # Set your team slug here


def get_github_repos_with_prefix(org_name, prefix):
    """Fetch all repo names in the org that start with the given prefix."""
    url = f"https://api.github.com/orgs/{org_name}/repos?per_page=100"
    repos = []
    while url:
        res = requests.get(url, headers=gh_headers)
        if res.status_code != 200:
            print(f"❌ Error fetching GitHub repos: {res.text}")
            break
        data = res.json()
        for repo in data:
            if repo['name'].startswith(prefix):
                repos.append(repo['name'])
        # Pagination: look for 'next' in Link header
        if 'link' in res.headers and 'rel=\"next\"' in res.headers['link']:
            links = res.headers['link'].split(',')
            next_link = [l for l in links if 'rel=\"next\"' in l]
            if next_link:
                url = next_link[0].split(';')[0].strip()[1:-1]
            else:
                url = None
        else:
            url = None
    return repos

gh_headers = {
    "Authorization": f"token {GH_TOKEN}",
    "Accept": "application/vnd.github.v3+json"
}

def add_repo_to_team(repo_name, team_slug, org_name, permission="push"):
    url = f"https://api.github.com/orgs/{org_name}/teams/{team_slug}/repos/{org_name}/{repo_name}"
    payload = {"permission": permission}
    res = requests.put(url, headers=gh_headers, json=payload)
    if res.status_code in (204, 201):
        print(f"✅ Added {repo_name} to team '{team_slug}' with '{permission}' access.")
    else:
        print(f"❌ Failed to add {repo_name}: {res.status_code} {res.text}")

if __name__ == "__main__":
    prefix = "batched-algo"
    repo_names = get_github_repos_with_prefix(GH_ORG_NAME, prefix)
    print(f"Found {len(repo_names)} repos starting with '{prefix}' in org '{GH_ORG_NAME}'.")
    for repo in repo_names:
        add_repo_to_team(repo, TEAM_SLUG, GH_ORG_NAME, permission="push")
