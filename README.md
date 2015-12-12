# mm-vsts-agent-tasks
Custom Build and Release Tasks for Visual Studio Team Services and Team Foundation Server. Based on https://github.com/Microsoft/vso-agent-tasks

# VSTS Installation

You'll need the following nuget package:

`npm install -g tfx-cli`

Then from the a console window, login to your VSTS instance:

`tfx login --authType basic`

When asked for the URL, us the following format: `https://YOURVSTSINSTANCE.visualstudio.com/DefaultCollection`

Use your normal login credentials.

To push a specific task, run the following from within the `Tasks` folder:

`tfx build tasks upload --task-path .\TaskFolderName`

If you're installing a new version, you can add `--overwrite` to that command to force it to be updated.