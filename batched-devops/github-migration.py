def format_size(bytes_or_kb, is_bytes=True):
    """Format size in bytes or KB to MB/GB with readable units."""
    size = float(bytes_or_kb) if bytes_or_kb is not None else 0
    if is_bytes:
        size = size / 1024  # convert to KB
    # Now size is in KB
    if size >= 1024 * 1024:
        return f"{size / (1024 * 1024):.2f} GB"
    elif size >= 1024:
        return f"{size / 1024:.2f} MB"
    else:
        return f"{size:.2f} KB"
def get_bitbucket_repo_size(repo_slug):
    """Return the size (in bytes) of a Bitbucket repo."""
    url = f"https://api.bitbucket.org/2.0/repositories/{BB_WORKSPACE}/{repo_slug}"
    res = requests.get(url, auth=bb_auth)
    if res.status_code != 200:
        return None
    data = res.json()
    return data.get('size')

def get_github_repo_size(repo_name):
    """Return the size (in kilobytes) of a GitHub repo."""
    url = f"https://api.github.com/repos/{GH_ORG_NAME}/{repo_name}"
    res = requests.get(url, headers=gh_headers)
    if res.status_code != 200:
        return None
    data = res.json()
    return data.get('size')
def get_bitbucket_branch_commits(repo_slug):
    """Return dict of branch_name -> last commit hash for Bitbucket repo."""
    branches_url = f"https://api.bitbucket.org/2.0/repositories/{BB_WORKSPACE}/{repo_slug}/refs/branches"
    branches_res = requests.get(branches_url, auth=bb_auth)
    if branches_res.status_code != 200:
        return {}
    branches_data = branches_res.json()
    branch_commits = {}
    for branch in branches_data.get('values', []):
        branch_name = branch['name']
        commit_hash = branch['target']['hash']
        branch_commits[branch_name] = commit_hash
    return branch_commits

def get_github_branch_commits(repo_name):
    """Return dict of branch_name -> last commit sha for GitHub repo."""
    branches_url = f"https://api.github.com/repos/{GH_ORG_NAME}/{repo_name}/branches?per_page=100"
    branches_res = requests.get(branches_url, headers=gh_headers)
    if branches_res.status_code != 200:
        return {}
    branches_data = branches_res.json()
    branch_commits = {}
    for branch in branches_data:
        branch_name = branch['name']
        commit_sha = branch['commit']['sha']
        branch_commits[branch_name] = commit_sha
    return branch_commits
def list_all_github_files(repo_name, branch_name=None):
    """List all files in a GitHub repo (optionally for a specific branch)."""
    if branch_name is None:
        # Get default branch
        repo_url = f"https://api.github.com/repos/{GH_ORG_NAME}/{repo_name}"
        repo_res = requests.get(repo_url, headers=gh_headers)
        if repo_res.status_code != 200:
            print(f"❌ Error fetching GitHub repo info: {repo_res.text}")
            return []
        repo_data = repo_res.json()
        branch_name = repo_data.get('default_branch', 'master')
    print(f"Listing all files in GitHub repo '{repo_name}' (branch: {branch_name})...")
    # Get the tree for the branch
    branch_url = f"https://api.github.com/repos/{GH_ORG_NAME}/{repo_name}/branches/{branch_name}"
    branch_res = requests.get(branch_url, headers=gh_headers)
    if branch_res.status_code != 200:
        print(f"❌ Error fetching GitHub branch info: {branch_res.text}")
        return []
    branch_data = branch_res.json()
    commit_sha = branch_data['commit']['sha']
    tree_url = f"https://api.github.com/repos/{GH_ORG_NAME}/{repo_name}/git/trees/{commit_sha}?recursive=1"
    tree_res = requests.get(tree_url, headers=gh_headers)
    if tree_res.status_code != 200:
        print(f"❌ Error fetching GitHub tree: {tree_res.text}")
        return []
    tree_data = tree_res.json()
    files = set(f['path'] for f in tree_data.get('tree', []) if f['type'] == 'blob')
    return sorted(files)
def list_all_bitbucket_files(repo_slug, branch_name=None):
    """List all files in a Bitbucket repo (optionally for a specific branch)."""
    if branch_name is None:
        # Get default branch
        repo_url = f"https://api.bitbucket.org/2.0/repositories/{BB_WORKSPACE}/{repo_slug}"
        repo_res = requests.get(repo_url, auth=bb_auth)
        if repo_res.status_code != 200:
            print(f"❌ Error fetching repo info: {repo_res.text}")
            return []
        repo_data = repo_res.json()
        branch_name = repo_data.get('mainbranch', {}).get('name', 'master')
    print(f"Listing all files in Bitbucket repo '{repo_slug}' (branch: {branch_name})...")
    files = set()
    files_url = f"https://api.bitbucket.org/2.0/repositories/{BB_WORKSPACE}/{repo_slug}/src/{branch_name}/?pagelen=100"
    while files_url:
        files_res = requests.get(files_url, auth=bb_auth)
        if files_res.status_code != 200:
            print(f"❌ Error fetching files: {files_res.text}")
            break
        files_data = files_res.json()
        for f in files_data.get('values', []):
            if 'path' in f:
                files.add(f['path'])
        files_url = files_data.get('next')
    return sorted(files)
import requests
import json
import os
import sys

# --- CONFIGURATION ---
# It is best practice to set these as Environment Variables, but you can fill them here for a one-off script.
BB_USERNAME = os.getenv('BB_USERNAME', 'thakkarmanthan')
BB_APP_PASSWORD = os.getenv('BB_APP_PASSWORD', '')
BB_WORKSPACE = os.getenv('BB_WORKSPACE', 'batched')

GH_USERNAME = os.getenv('GH_USERNAME', 'manthan-amtech')
GH_TOKEN = os.getenv('GH_TOKEN', '')
GH_ORG_NAME = os.getenv('GH_ORG_NAME', 'LabelTraxx')  # <--- NEW

# The prefix to search for
TARGET_PREFIX = "batched-algo"

# --- HEADERS ---
bb_auth = (BB_USERNAME, BB_APP_PASSWORD)
gh_headers = {
    "Authorization": f"token {GH_TOKEN}",
    "Accept": "application/vnd.github.v3+json"
}

def get_bitbucket_repos():
    """Fetches all repos from Bitbucket and filters by prefix."""
    print(f"🔍 Searching for repositories starting with '{TARGET_PREFIX}' in workspace '{BB_WORKSPACE}'...")
    url = f"https://api.bitbucket.org/2.0/repositories/{BB_WORKSPACE}"
    repos = []
    while url:
        response = requests.get(url, auth=bb_auth)
        if response.status_code != 200:
            print(f"❌ Error fetching Bitbucket repos: {response.text}")
            sys.exit(1)
        data = response.json()
        for repo in data['values']:
            if repo['name'].startswith(TARGET_PREFIX):
                repos.append({
                    "name": repo['name'],
                    "slug": repo['slug']
                })
        url = data.get('next')
    return repos

def get_github_repos():
    """Fetches all repos from GitHub org and filters by prefix."""
    print(f"🔍 Searching for repositories starting with '{TARGET_PREFIX}' in GitHub org '{GH_ORG_NAME}'...")
    url = f"https://api.github.com/orgs/{GH_ORG_NAME}/repos?per_page=100"
    repos = []
    while url:
        response = requests.get(url, headers=gh_headers)
        if response.status_code != 200:
            print(f"❌ Error fetching GitHub repos: {response.text}")
            sys.exit(1)
        data = response.json()
        for repo in data:
            if repo['name'].startswith(TARGET_PREFIX):
                repos.append({
                    "name": repo['name'],
                })
        # Pagination: look for 'next' in Link header
        if 'link' in response.headers and 'rel="next"' in response.headers['link']:
            links = response.headers['link'].split(',')
            next_link = [l for l in links if 'rel="next"' in l]
            if next_link:
                url = next_link[0].split(';')[0].strip()[1:-1]
            else:
                url = None
        else:
            url = None
    return repos



def get_bitbucket_branches_and_files(repo_slug):
    """Return dict of branch_name -> set of file paths for Bitbucket repo, recursively."""
    def fetch_files_recursive(branch_name, path_prefix=""):
        files = set()
        url = f"https://api.bitbucket.org/2.0/repositories/{BB_WORKSPACE}/{repo_slug}/src/{branch_name}/{path_prefix}?pagelen=100"
        while url:
            res = requests.get(url, auth=bb_auth)
            if res.status_code != 200:
                break
            data = res.json()
            for entry in data.get('values', []):
                if entry.get('type') == 'commit_file' and 'path' in entry:
                    files.add(entry['path'])
                elif entry.get('type') == 'commit_directory' and 'path' in entry:
                    # Recurse into subdirectory
                    files.update(fetch_files_recursive(branch_name, entry['path']))
            url = data.get('next')
        return files

    branches_url = f"https://api.bitbucket.org/2.0/repositories/{BB_WORKSPACE}/{repo_slug}/refs/branches"
    branches_res = requests.get(branches_url, auth=bb_auth)
    if branches_res.status_code != 200:
        return {}
    branches_data = branches_res.json()
    branch_list = branches_data.get('values', [])
    branch_files = {}
    for branch in branch_list:
        branch_name = branch['name']
        branch_files[branch_name] = fetch_files_recursive(branch_name)
    return branch_files

def get_github_branches_and_files(repo_name):
    """Return dict of branch_name -> set of file paths for GitHub repo (recursive)."""
    branches_url = f"https://api.github.com/repos/{GH_ORG_NAME}/{repo_name}/branches?per_page=100"
    branches_res = requests.get(branches_url, headers=gh_headers)
    if branches_res.status_code != 200:
        return {}
    branches_data = branches_res.json()
    branch_files = {}
    for branch in branches_data:
        branch_name = branch['name']
        commit_sha = branch['commit']['sha']
        tree_url = f"https://api.github.com/repos/{GH_ORG_NAME}/{repo_name}/git/trees/{commit_sha}?recursive=1"
        tree_res = requests.get(tree_url, headers=gh_headers)
        if tree_res.status_code != 200:
            branch_files[branch_name] = set()
            continue
        tree_data = tree_res.json()
        file_paths = set(f['path'] for f in tree_data.get('tree', []) if f['type'] == 'blob')
        branch_files[branch_name] = file_paths
    return branch_files

def compare_repos_and_branches(bb_repos, gh_repos):
    bb_names = set(r['name'] for r in bb_repos)
    gh_names = set(r['name'] for r in gh_repos)
    only_in_bb = bb_names - gh_names
    only_in_gh = gh_names - bb_names
    if only_in_bb:
        print(f"\n❗Repos only in Bitbucket:")
        for n in only_in_bb:
            print(f"   {n}")
    if only_in_gh:
        print(f"\n❗Repos only in GitHub:")
        for n in only_in_gh:
            print(f"   {n}")
    # For repos in both, compare branches and files
    in_both = bb_names & gh_names
    for name in sorted(in_both):
        bb_repo = next(r for r in bb_repos if r['name'] == name)
        print(f"\n🔍 Comparing repo: {name}")
        bb_branches = get_bitbucket_branches_and_files(bb_repo['slug'])
        gh_branches = get_github_branches_and_files(name)
        bb_branch_set = set(bb_branches.keys())
        gh_branch_set = set(gh_branches.keys())
        if bb_branch_set != gh_branch_set:
            print(f"   ⚠️ Branch mismatch:")
            print(f"      Bitbucket: {sorted(bb_branch_set)}")
            print(f"      GitHub:    {sorted(gh_branch_set)}")
        else:
            print(f"   ✅ Branches match: {sorted(bb_branch_set)}")
        # For each branch in both, compare files
        for branch in sorted(bb_branch_set & gh_branch_set):
            bb_files = bb_branches[branch]
            gh_files = gh_branches[branch]
            if bb_files != gh_files:
                print(f"   ⚠️ Files mismatch in branch '{branch}':")
                print(f"      Bitbucket only: {sorted(bb_files - gh_files)}")
                print(f"      GitHub only:    {sorted(gh_files - bb_files)}")
            else:
                print(f"   ✅ Files match in branch '{branch}' ({len(bb_files)} files)")

# --- MAIN EXECUTION ---
if __name__ == "__main__":
    bb_repos = get_bitbucket_repos()
    gh_repos = get_github_repos()
    if not bb_repos:
        print(f"No repositories found starting with '{TARGET_PREFIX}' in Bitbucket.")
    elif not gh_repos:
        print(f"No repositories found starting with '{TARGET_PREFIX}' in GitHub.")
    else:
        gh_repo_names = set(r['name'] for r in gh_repos)
        for repo in bb_repos:
            bb_size = get_bitbucket_repo_size(repo['slug'])
            gh_size = get_github_repo_size(repo['name']) if repo['name'] in gh_repo_names else None
            bb_size_str = format_size(bb_size, is_bytes=True) if bb_size is not None else "N/A"
            gh_size_str = format_size(gh_size, is_bytes=False) if gh_size is not None else "N/A"
            # Only print size for reference, do not compare
            bb_branch_commits = get_bitbucket_branch_commits(repo['slug'])
            if repo['name'] not in gh_repo_names:
                print(f"\n--- Bitbucket repo: {repo['name']} (slug: {repo['slug']}) ---")
                print(f"Bitbucket repo size: {bb_size_str}")
                http_url = f"https://bitbucket.org/{BB_WORKSPACE}/{repo['slug']}"
                print(f"No matching GitHub repo found for '{repo['name']}'")
                print(f"   🌐 {http_url}")
                for branch, commit in bb_branch_commits.items():
                    print(f"  Branch: {branch}  Commit: {commit}")
                continue
            gh_branch_commits = get_github_branch_commits(repo['name'])
            all_branches = sorted(set(bb_branch_commits.keys()) | set(gh_branch_commits.keys()))
            all_match = True
            mismatch_branches = []
            for branch in all_branches:
                bb_commit = bb_branch_commits.get(branch)
                gh_commit = gh_branch_commits.get(branch)
                if bb_commit != gh_commit or bb_commit is None or gh_commit is None:
                    mismatch_branches.append((branch, bb_commit, gh_commit))
                    all_match = False
            if not all_match:
                print(f"\n--- Bitbucket repo: {repo['name']} (slug: {repo['slug']}) ---")
                print(f"Bitbucket repo size: {bb_size_str}")
                print(f"GitHub repo size:    {gh_size_str}")
                if mismatch_branches:
                    print(f"Branches/commits that do not match:")
                    for branch, bb_commit, gh_commit in mismatch_branches:
                        print(f"  Branch '{branch}': ⚠️")
                        print(f"    Bitbucket commit: {bb_commit}")
                        print(f"    GitHub commit:    {gh_commit}")