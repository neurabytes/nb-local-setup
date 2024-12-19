import json
import requests
import os

def update_tools():
    tools_path = os.path.join(os.path.dirname(__file__), '../../tools.json')
    with open(tools_path, 'r') as file:
        tools = json.load(file)

    tool_names = tools['tools'].keys()

    for tool in tool_names:
        response = requests.get(f'https://community.chocolatey.org/api/v2/package/{tool}')
        if response.status_code == 200:
            latest_version = response.json()['Properties']['version']
            tools['tools'][tool] = latest_version
        else:
            print(f'Error fetching data for {tool}: {response.status_code}')

    with open(tools_path, 'w') as file:
        json.dump(tools, file, indent=2)

if __name__ == '__main__':
    update_tools()