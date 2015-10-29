PresideCMS CommandBox Commands
==============================

[![Build Status](https://travis-ci.org/pixl8/Preside-CMS-CommandBox-Commands.svg?branch=master)](https://travis-ci.org/pixl8/Preside-CMS-CommandBox-Commands)

CommandBox commands for PresideCMS. This repository manages the code used to build the "preside" set of commands for CommandBox.

## Installation

Before starting, you will need CommandBox installed. Head to http://www.ortussolutions.com/products/commandbox for instructions on how to do so.

Once you have CommandBox up and running, you'll need to issue the following commands:

    CommandBox> install preside-commands
    CommandBox> reload

Make sure you have the latest commandbox build and that the reload command causes the preside namespace to appear when you type help.
    
## Usage

### Create a new site

From within the CommandBox shell, CD into an empty directory in which you would like to create the new site and type:

    CommandBox> preside new site
    
Follow any prompts that you receive.

### Start a server

From the webroot of your Preside site, enter the following command:

    CommandBox> preside start
    
If it is the first time starting, you will be prompted to download Preside and also to enter your database information, you will need an empty database already setup.

Once started, a browser should open and you should be presented with your homepage. To navigate to the administrator, browse to `/{site_id}_admin/`, where site id is the ID of the site you entered when creating the new site from the instructions above.

**n.b.** The admin path setting is editable in your site's `/application/config/Config.cfc` file.

