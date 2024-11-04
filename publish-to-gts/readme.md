## Overview

The **Publish To GoToSocial** script for QOwnNotes allows users to publish markdown notes directly to their GoToSocial activitypub instance.
Future versions will be also able to download posts, to keep them as notes or to use other script for publishing them as standalone websites.

## Manual Installation

1. **Download the Plugin**: Save the `publish-to-gts.qml`  file to your local machine.
2. **Add to QOwnNotes**:
   - Open QOwnNotes.
   - Navigate to `Settings` > `Scripting`.
   - Click on `Add script... > Add local script`.
   - Select the  `publish-to-gts.qml` file in the script folder.
3. **Activate the Plugin**:
   - Go back to QOwnNotes.
   - In the `Scripting` settings, ensure that  `publish-to-gts.qml` is listed and checked.

## Settings

- **Server instance**: Server instance you want to connect to (i.e.: example.org - no spaces, no protocol, no slashes);
- **Authentication Code**: Code returned by GtS after performing a successful authentication, if you paste it here you won't need to authenticate again until expiry;
- **Visibility**: Default visibility for published posts:
  - Public
  - Unlisted
  - Private
  - Mutuals
  - Direct Message
- **Local Only**: If the post is local only, it will not be seen from federated instances;
- **Content Warning**: The post text will not be immediately visible, as it may be sensible to some audience;
- **Content Warning text**: Text to show as a content warning for senstitive posts;
- **Language code**: 2-chars laguage code as per https://www.loc.gov/standards/iso639-2/php/English_list.php.

## Usage

After installation type the server instance name on the script settings and press Ok. Connection with your server will be established the first time you will publish a post.

There are two implemented use cases:
1. **Creation of a new note**
2. **Note publishing**

### Creation of a new note

1. Select `Custom actions > New Post for GtS` on the context menu **or** click on `Scripting > Custom actions > New post for GtS`;
2. A new note with default Post Header will be created
3. Write your post below the front matter, adjust the post settings as per your preferences. You can try to add other accepted parameters and they should work, but it's not a supported feature. Not sure for nested object parameters. 

### Note publishing for first access

1. On the note to be published right click and select `Custom actions > Publish current note to GtS`
2. A *"Publish to Gts: confirm action"* dialog pops out, summarizing the post settings and asking for confirmation. Press Ok.
3. If this is the first note published a *"GoToSocial Authentication"* input dialog pops out: ppen the link referenced in the popup on your browser (you may need to copy and paste it depending on your OS).
4. Perform the authentication on your instance with the user you want to impersonate and click on *"Allow"* in the confirmation page
5. Copy the *"Authorization Code"* from the web page and paste it back to the *"GoToSocial Authentication"* popup. You may also want to paste the same code on your script settings page, on the **Authorization Code** parameter, so that you won't need re-authenticate when you opena new session on QON.
6. The post gets published with current settings.

#### Other Note publishing details

A published note gains extra information on the front matter:
- a **created_at** datatime field, that is returned by your server
- an **id** as the published post id
- an **url** as the published post permalink

A published note also gains 2 note tags:
- a `Pub2GtS` tag to identify the post as managed and modified by the publish-to-gts script
- a `Published` tag to identify a note that has been already published

In case you try to publish a note that contains `created_at` in the front matter a confirmation will be requested. If confirmed the post will be published again, updating the `created_at` datetime and the `id` and `url`, as GtS do not provide yet a post editing feature.

In case you try to publish a note that does not contain the front matter, a front matter will be generated at the moment and updated when the note is published.

## Contributing

If you have suggestions or improvements, feel free to fork the repository and submit a pull request.

## Needed testers on MacOS!

## ToDo

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

Enjoy using the Publish To GtS script to enhance your social publishing experience with QOwnNotes!
