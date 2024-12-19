import json
import requests
import os
import xml.etree.ElementTree as ET

def update_tools():
    # Construct the absolute path to tools.json
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../'))
    tools_path = os.path.join(repo_root, 'windows', 'bin', 'tools.json')

    # Load the tools configuration
    with open(tools_path, 'r') as file:
        tools = json.load(file)

    tool_names = tools['tools'].keys()

    for tool in tool_names:
        try:
            # Fetch the Chocolatey package data
            response = requests.get(f'https://community.chocolatey.org/api/v2/Packages()?$filter=Id eq \'{tool}\'')
            if response.status_code == 200:
                # Parse the XML response to get the latest version
                root = ET.fromstring(response.content)
                namespace = {'d': 'http://schemas.microsoft.com/ado/2007/08/dataservices'}
                version_element = root.find('.//d:Version', namespace)
                if version_element is not None:
                    latest_version = version_element.text
                    tools['tools'][tool] = latest_version
                    print(f"Updated {tool} to version {latest_version}")
                else:
                    print(f"Version information not found for {tool}")
            else:
                print(f"Error fetching data for {tool}: HTTP {response.status_code}")
        except Exception as e:
            print(f"An error occurred while processing {tool}: {e}")

    # Save the updated tools configuration
    with open(tools_path, 'w') as file:
        json.dump(tools, file, indent=2)
    print(f"Tools updated successfully in {tools_path}")

if __name__ == '__main__':
    update_tools()
