
SimpleBlocklists
======

Apply and update hosts blocklists in a few clicks on a Windows machine.

Description
-----------

This is a PowerShell script that allows to download and merge hosts blocklists from URLs. It also makes a backup of your hosts file, disables the startup of the dnscache service, and offers to create a scheduled task to update your hosts file regularly.

Operations performed
---------------

 1. The script tries to elevate to admin, as it is needed to edit the hosts file.
 2. It downloads and merges the various blocklists that are specified in the `$blockLists` array.
 3. It makes a backup of the original hosts file to hosts.bak.
 4. It adds the original hosts file to the downloaded blocklists, and replaces the hosts file.
 5. It disables the startup of the dnscache service.
 6. It offers to create a scheduled task that will execute the script weekly to update the hosts file.

Simple, right?

Installation
------------------

I suggest placing this script in a folder where it will not be moved, and keep its filename as it is, otherwise the scheduled task won't be able to find it again. I personally put it in `C:\SimpleBlocklists.ps1`. Of course, if you want to change the filename, you can go change it in the scheduled task creation at the end of the script. And if you change the location of the script after you added the scheduled task, you can manually edit the scheduled task.

Anyway, at first launch:

 1. Right click on the script, select "Run with PowerShell".
 2. The script will attempt to auto-elevate: allow it in the UAC window.
 3. If the dnscache service is active, it disables its startup, and warns that a reboot is needed.
 4. If the scheduled task does not exist, it prompts to add one.

Once the dnscache service has been disabled and the scheduled task has been added, the script runs silently.

Customize the blocklists
------------------

At the beginning of the script, in the "Parameters" section, you can customize two things:

 - The blocklists to apply: some are present by default, but you can add or remove them as you like.
 - The IP address you want the blocked domains to be redirected to, by default it is 0.0.0.0.

Contribution
-------

Contributions are welcome, especially code optimizations. Please keep simplicity in mind!

License
-------

Feel free to share or remix SimpleBlocklists! Keep my name and a link to this page though.

[Creative Commons - Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/).
