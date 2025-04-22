import json
import re
import requests
import os
import sys
from datetime import datetime

def prepare_description(text):
    text = re.sub('<[^<]+?>', '', text) # Remove HTML tags
    text = re.sub(r'#{1,6}\s?', '', text) # Remove markdown header tags
    text = re.sub(r'\*{2}', '', text) # Remove all occurrences of two consecutive asterisks
    text = re.sub(r'(?<=\r|\n)-', '•', text) # Only replace - with • if it is preceded by \r or \n
    text = re.sub(r'`', '"', text) # Replace ` with "
    text = re.sub(r'\r\n\r\n', '\r \n', text) # Replace \r\n\r\n with \r \n (avoid incorrect display of the description regarding paragraphs)
    return text

def fetch_latest_release(repo_url):
    api_url = f"https://api.github.com/repos/{repo_url}/releases"
    headers = {
        "Accept": "application/vnd.github+json",
    }
    try:
        print(f"Fetching releases from: {api_url}")
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        releases = response.json()
        if not releases:
            print("No releases found in the repository")
            return None
        print(f"Found {len(releases)} releases")
        print(f"Latest release: {releases[0]['tag_name']}")
        return releases
    except requests.RequestException as e:
        print(f"Error fetching releases: {e}")
        return None

def get_file_size(url):
    try:
        response = requests.head(url)
        response.raise_for_status()
        return int(response.headers.get('Content-Length', 0))
    except requests.RequestException as e:
        print(f"Error getting file size: {e}")
        return 0

def update_json_file(json_file, latest_release):
    if isinstance(latest_release, list) and latest_release:
        latest_release = latest_release[0]
    else:
        print("Error getting latest release")
        return False

    try:
        print(f"Reading JSON file: {json_file}")
        with open(json_file, "r") as file:
            data = json.load(file)
    except json.JSONDecodeError as e:
        print(f"Error reading JSON file: {e}")
        return False
    except FileNotFoundError:
        print(f"File {json_file} not found")
        return False

    app = data["apps"][0]
    current_version = app.get("version", "unknown")
    print(f"Current version in repo.json: {current_version}")

    full_version = latest_release["tag_name"]
    tag = latest_release["tag_name"]
    version_match = re.search(r"(\d+\.\d+\.\d+)", full_version)
    if not version_match:
        print(f"Could not extract version from tag: {full_version}")
        return False
    
    version = version_match.group(1)
    print(f"Latest release version: {version}")
    
    # Check if the version is already in the versions list
    existing_versions = [v["version"] for v in app["versions"]]
    print(f"Existing versions: {existing_versions}")
    
    if version in existing_versions and version == current_version:
        print(f"Version {version} already exists and is current, no update needed")
        return False
    
    version_date = latest_release["published_at"]
    date_obj = datetime.strptime(version_date, "%Y-%m-%dT%H:%M:%SZ")
    version_date = date_obj.strftime("%Y-%m-%d")

    description = latest_release["body"] or "No description provided"
    description = prepare_description(description)

    assets = latest_release.get("assets", [])
    print(f"Found {len(assets)} assets in the release")
    for asset in assets:
        print(f"Asset: {asset['name']}")
    
    download_url = None
    size = None
    for asset in assets:
        if asset["name"].endswith(".ipa"):
            download_url = asset["browser_download_url"]
            size = asset["size"]
            print(f"Found IPA file: {asset['name']}, size: {size}")
            break

    if download_url is None or size is None:
        print("Error: IPA file not found in release assets.")
        return False

    version_entry = {
        "version": version,
        "date": version_date,
        "localizedDescription": description,
        "downloadURL": download_url,
        "size": size,
        "minOSVersion": "17.4"  # Adding minOSVersion for StikJIT
    }

    # Always update with the latest version
    print(f"Adding new version entry: {version}")
    app["versions"].insert(0, version_entry)

    print(f"Updating app with version {version}")
    app.update({
        "version": version,
        "versionDate": version_date,
        "versionDescription": description,
        "downloadURL": download_url,
        "size": size
    })

    if "news" not in data:
        data["news"] = []

    news_identifier = f"release-{full_version}"
    date_string = date_obj.strftime("%d/%m/%y")
    news_entry = {
        "appID": "com.stik.sj",
        "caption": f"Update of StikJIT just got released!",
        "date": latest_release["published_at"],
        "identifier": news_identifier,
        "imageURL": "https://github.com/StephenDev0/StikJIT/blob/main/assets/StikJIT.png?raw=true",
        "notify": True,
        "tintColor": "#293B45",
        "title": f"{full_version} - StikJIT {date_string}",
        "url": f"https://github.com/StephenDev0/StikJIT/releases/tag/{tag}"
    }

    news_entry_exists = any(item["identifier"] == news_identifier for item in data["news"])
    if not news_entry_exists:
        print(f"Adding news entry for version {full_version}")
        data["news"].append(news_entry)
    else:
        print(f"News entry for version {full_version} already exists")

    try:
        print(f"Writing updated JSON to {json_file}")
        with open(json_file, "w") as file:
            json.dump(data, file, indent=2)
        print("JSON file updated successfully.")
        return True
    except IOError as e:
        print(f"Error writing to JSON file: {e}")
        return False

def main():
    # Use the original repository instead of fork
    repo_url = "StephenDev0/StikJIT"
    json_file = "repo.json"

    print(f"Using repository: {repo_url}")
    print(f"Updating file: {json_file}")

    try:
        fetched_data_latest = fetch_latest_release(repo_url)
        if fetched_data_latest:
            success = update_json_file(json_file, fetched_data_latest)
            if not success:
                print("Failed to update JSON file or no changes were needed")
                sys.exit(0)  # Exit with success code since no changes needed is not an error
        else:
            print("No releases found to update")
            sys.exit(1)
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
